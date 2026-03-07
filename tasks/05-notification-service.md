# Task 05 — Notification Service

**Port:** 3004 (HTTP + WebSocket on same port)  
**Responsibility:** Consume RabbitMQ events (`order.*` and `driver.location.updated`) and push real-time updates to customers over WebSocket. Use Redis as a shared session registry to route messages to the correct service instance when horizontally scaled.  
**Stack:** Node.js 20 + TypeScript, Redis 7 (session registry), RabbitMQ 3 (consumer), WebSocket (`ws` library)

> **No persistent database** — this service is stateless except for the Redis session registry.

---

## Subtasks

### 5.1 — Project Scaffolding

- [ ] Initialise `services/notification-service/` as a Node.js TypeScript project
  - Runtime deps: `express`, `ws`, `ioredis`, `amqplib`, `uuid`, `dotenv`
  - Dev deps: `typescript`, `@types/express`, `@types/ws`, `@types/amqplib`, `@types/node`, `ts-node-dev`, `@types/uuid`
- [ ] Create `tsconfig.json` extending root `tsconfig.base.json`
- [ ] Add npm scripts: `build`, `start`, `dev`
- [ ] Folder structure:
  ```
  src/
  ├── index.ts
  ├── config/
  │   ├── redis.ts
  │   └── rabbitmq.ts
  ├── websocket/
  │   └── customerSocket.ts   ← customer-facing WebSocket server
  ├── consumers/
  │   ├── orderConsumer.ts    ← consumes orders.notification queue
  │   └── locationConsumer.ts ← consumes driver.location.notification queue
  ├── services/
  │   └── sessionService.ts   ← Redis session registry read/write
  └── types/
      └── index.ts
  ```

---

### 5.2 — Redis Client (`config/redis.ts`)

- [ ] Same `ioredis` singleton pattern as other services
- [ ] Used for reading/writing `ws:session:{orderId}` keys

---

### 5.3 — RabbitMQ Connection (`config/rabbitmq.ts`)

- [ ] Connect to RabbitMQ using `RABBITMQ_URL`
- [ ] Create a durable channel
- [ ] Assert the following queues (idempotent, they already exist from `definitions.json`):
  - `orders.notification` — bound to `order.events` fanout exchange
  - `driver.location.notification` — bound to `driver.events` direct exchange
- [ ] Set `prefetch(10)` on the channel — process at most 10 messages at once (prevents memory overload)
- [ ] Reconnect pattern: exponential back-off, max 5 retries, then exit with code 1

---

### 5.4 — TypeScript Types (`types/index.ts`)

- [ ] `OrderEvent` — orderId: string, status: string, restaurantId?: string, items?: any[]
- [ ] `LocationEvent` — driverId: string, orderId: string, lat: number, lng: number, timestamp: number
- [ ] `WebSocketMessage` — type: `'ORDER_UPDATE' | 'DRIVER_LOCATION'`, payload: OrderEvent | LocationEvent
- [ ] `SessionEntry` — instanceId: string, connectedAt: number

---

### 5.5 — Session Service (`services/sessionService.ts`)

Maps an `orderId` to the instance and the live WebSocket connection, enabling horizontal scaling.

**`registerSession(orderId: string, instanceId: string): Promise<void>`**
- [ ] `SET ws:session:{orderId} {instanceId} EX 3600` (1-hour TTL; refreshed on message activity)
- [ ] This marks that the WebSocket connection for this order is held by `instanceId`

**`getSessionInstance(orderId: string): Promise<string | null>`**
- [ ] `GET ws:session:{orderId}`
- [ ] Returns the `instanceId` or `null` if no active session

**`removeSession(orderId: string): Promise<void>`**
- [ ] `DEL ws:session:{orderId}`
- [ ] Called when customer disconnects

> **Note on horizontal scaling:** When multiple Notification Service instances run behind a load balancer, each instance maintains its own in-memory WebSocket map. The Redis registry tells a consumer which instance holds a given customer's connection. In the local Docker Compose setup there is only one instance, so this registry is a formality — but the code must be written as if multiple instances exist.

---

### 5.6 — Customer WebSocket Server (`websocket/customerSocket.ts`)

Handles persistent connections from customer browser / mobile apps tracking a live order.

**Setup:**
- [ ] Create `ws.Server` attached to the shared HTTP server, `path: '/track/:orderId'`
  - Note: `ws` does not parse path params natively. Listen on `path: '/track'` and parse `orderId` from the upgrade request URL manually.
- [ ] Maintain in-memory `Map<orderId, WebSocket>` for connections on this instance

**On Connection:**
- [ ] Extract `orderId` from URL path (e.g. `/track/abc-123` → `orderId = 'abc-123'`)
- [ ] Validate `orderId` is a valid UUID — close with code `4000` if not
- [ ] Register session: call `sessionService.registerSession(orderId, INSTANCE_ID)`
  - `INSTANCE_ID` = `process.env.INSTANCE_ID || uuid()` (set at startup, stable for process lifetime)
- [ ] Store `ws` in the local `Map<orderId, WebSocket>`
- [ ] Send an initial confirmation frame: `{ type: 'CONNECTED', orderId }`
- [ ] Log new customer tracking connection

**On Close:**
- [ ] Remove from local map
- [ ] Call `sessionService.removeSession(orderId)`
- [ ] Log disconnect

**`sendToCustomer(orderId: string, message: WebSocketMessage): boolean`**
- [ ] Check if `orderId` exists in local `Map`
  - Yes → `ws.send(JSON.stringify(message))`; return `true`
  - No → return `false` (message is for a different instance; log and drop in single-instance mode)
- [ ] Export this function so consumers can call it

**Heartbeat:**
- [ ] Same ping/pong heartbeat pattern as Driver Location Service (15s interval, 30s timeout to terminate dead connections)

---

### 5.7 — Order Event Consumer (`consumers/orderConsumer.ts`)

Consumes the `orders.notification` queue.

- [ ] `channel.consume('orders.notification', handler, { noAck: false })`
- [ ] Parse message content as `OrderEvent`
- [ ] Determine message type from the payload (check `status` field or add a `type` field to the published event)
- [ ] Construct `WebSocketMessage`: `{ type: 'ORDER_UPDATE', payload: OrderEvent }`
- [ ] Call `sendToCustomer(orderId, message)`
- [ ] `channel.ack(msg)` after successful processing
- [ ] On parse error or unexpected payload → `channel.nack(msg, false, false)` (dead-letter, do not requeue)
- [ ] Log each consumed event at INFO level

---

### 5.8 — Location Event Consumer (`consumers/locationConsumer.ts`)

Consumes the `driver.location.notification` queue.

- [ ] `channel.consume('driver.location.notification', handler, { noAck: false })`
- [ ] Parse message content as `LocationEvent`
- [ ] Construct `WebSocketMessage`: `{ type: 'DRIVER_LOCATION', payload: LocationEvent }`
- [ ] Call `sendToCustomer(event.orderId, message)`
  - If returns `false` (customer not on this instance or disconnected) → `ack` and log at DEBUG
- [ ] `channel.ack(msg)` after processing
- [ ] On error → `channel.nack(msg, false, false)`
- [ ] **Performance note:** This queue receives up to 2,000 messages/sec. The handler must be fast — no blocking I/O inside the handler beyond the WebSocket send

---

### 5.9 — Express App Entry Point (`index.ts`)

- [ ] Load env vars
- [ ] Generate or read `INSTANCE_ID` (used for session registry)
- [ ] Create Express app + `http.Server`
- [ ] `GET /health` → `{ status: "ok", service: "notification-service", instanceId, activeCustomers: Map.size }`
- [ ] Global error middleware
- [ ] On startup:
  1. Connect Redis
  2. Connect RabbitMQ and initialise channel
  3. Start WebSocket server (attach to HTTP server)
  4. Start Order consumer
  5. Start Location consumer
- [ ] Listen on `process.env.NOTIFICATION_PORT || 3004`

---

## API Contract Summary

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| WS | `ws://.../track/{orderId}` | Customer connects to track order | Persistent WS |
| GET | `/health` | Health check + active customer count | 200 |

**WebSocket message schema (outbound to customer):**
```json
// Order status update
{ "type": "ORDER_UPDATE", "payload": { "orderId": "...", "status": "CONFIRMED" } }

// Driver location push
{ "type": "DRIVER_LOCATION", "payload": { "driverId": "...", "orderId": "...", "lat": 12.97, "lng": 77.59, "timestamp": 1700000000 } }
```

---

## Acceptance Criteria

- [ ] A WebSocket client connecting to `ws://localhost:3004/track/{orderId}` receives a `CONNECTED` confirmation frame
- [ ] After `POST /orders` is placed, the customer WebSocket receives a `ORDER_UPDATE` with `status: "PENDING"` (or `"CONFIRMED"` depending on event emitted)
- [ ] After a driver sends a GPS ping, the customer WebSocket receives a `DRIVER_LOCATION` message within < 500ms end-to-end
- [ ] When the customer disconnects, the Redis session key `ws:session:{orderId}` is removed
- [ ] `GET /health` returns the number of currently tracked orders (active WebSocket connections)
- [ ] RabbitMQ `orders.notification` queue depth stays near 0 (messages consumed promptly; verify via Management UI)
