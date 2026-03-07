# Task 04 — Driver Location Service

**Port:** 3003 (HTTP + WebSocket on same port)  
**Responsibility:** Maintain persistent WebSocket connections from driver apps, ingest GPS pings at 2,000 events/sec, store live positions in Redis GEO, and publish location updates to RabbitMQ for the Notification Service.  
**Stack:** Node.js 20 + TypeScript, Redis 7 (GEO), PostgreSQL 16 (driver profiles), RabbitMQ 3, WebSocket (`ws` library)

---

## Subtasks

### 4.1 — Project Scaffolding

- [ ] Initialise `services/driver-location-service/` as a Node.js TypeScript project
  - Runtime deps: `express`, `ws`, `pg`, `ioredis`, `amqplib`, `uuid`, `dotenv`
  - Dev deps: `typescript`, `@types/express`, `@types/ws`, `@types/pg`, `@types/amqplib`, `@types/node`, `ts-node-dev`, `@types/uuid`
- [ ] Create `tsconfig.json` extending root `tsconfig.base.json`
- [ ] Add npm scripts: `build`, `start`, `dev`
- [ ] Folder structure:
  ```
  src/
  ├── index.ts
  ├── config/
  │   ├── db.ts
  │   ├── redis.ts
  │   └── rabbitmq.ts
  ├── websocket/
  │   └── driverSocket.ts   ← WebSocket server + connection lifecycle
  ├── services/
  │   ├── locationService.ts ← GEO write/read logic
  │   └── publisher.ts       ← RabbitMQ publish helpers
  ├── routes/
  │   └── drivers.ts         ← HTTP REST endpoints
  └── types/
      └── index.ts
  ```

---

### 4.2 — Database Client (`config/db.ts`)

- [ ] Same `pg.Pool` pattern as other services
- [ ] Used to query `drivers` table for profile validation on WebSocket connect

---

### 4.3 — Redis Client (`config/redis.ts`)

- [ ] Same `ioredis` singleton pattern
- [ ] Used for `GEOADD`, `GEOPOS`, `GEORADIUS` / `GEOSEARCH` commands

---

### 4.4 — RabbitMQ Connection (`config/rabbitmq.ts`)

- [ ] Connect to RabbitMQ, create durable channel
- [ ] Assert exchange `driver.events` — type `direct`, durable
- [ ] Same reconnect pattern as Order Service

---

### 4.5 — TypeScript Types (`types/index.ts`)

- [ ] `Driver` — id, name, phone, vehicle, is_active, created_at
- [ ] `GpsPing` — driverId: string, lat: number, lng: number, timestamp: number
- [ ] `DriverLocation` — driverId: string, lat: number, lng: number
- [ ] `NearbyDriversQuery` — lat: number, lng: number, radius: number (km)

---

### 4.6 — Location Service (`services/locationService.ts`)

**`updateDriverPosition(ping: GpsPing): Promise<void>`**
- [ ] Run `GEOADD drivers:active {lng} {lat} {driverId}`
  - Note: Redis GEO argument order is longitude first, then latitude
  - Overwrites previous position atomically
- [ ] Set a per-member TTL using a Sorted Set trick or pipeline:
  - After `GEOADD`, call `EXPIRE drivers:active 30` is not appropriate (expires the entire set)
  - Instead: maintain a secondary sorted set `drivers:ttl` with score = `Date.now() + 30000`; use a periodic cleanup job to `ZRANGEBYSCORE drivers:ttl 0 {now}` and `ZREM`/`GEOREM` expired members
- [ ] Log high-rate ingestion at DEBUG level only (avoid log flooding at 2,000/sec)

**`getDriverPosition(driverId: string): Promise<DriverLocation | null>`**
- [ ] Run `GEOPOS drivers:active {driverId}`
- [ ] Return `null` if position not found (driver offline)
- [ ] Return `DriverLocation` with lat, lng

**`getNearbyDrivers(query: NearbyDriversQuery): Promise<DriverLocation[]>`**
- [ ] Run `GEOSEARCH drivers:active FROMLONLAT {lng} {lat} BYRADIUS {radius} km ASC`
  - Use `GEOSEARCH` (Redis 6.2+) rather than deprecated `GEORADIUS`
- [ ] Return array of `DriverLocation` objects
- [ ] Cap results at 50 to prevent oversized responses

---

### 4.7 — Publisher (`services/publisher.ts`)

**`publishLocationUpdate(ping: GpsPing, orderId?: string): Promise<void>`**
- [ ] Publish to exchange `driver.events` with routing key `driver.location.updated`
- [ ] Payload: `{ driverId, lat, lng, timestamp, orderId }` (orderId may be undefined if driver not yet assigned to an order)
- [ ] Set `persistent: false` — stale GPS messages have no value, delivery speed is more important

---

### 4.8 — WebSocket Server (`websocket/driverSocket.ts`)

Handles persistent connections from driver mobile apps.

**Setup:**
- [ ] Create a `ws.Server` attached to the same Node.js HTTP server (not a separate port)
- [ ] Set `path: '/drivers/connect'` on the WebSocket server
- [ ] Maintain an in-memory `Map<driverId, WebSocket>` for active connections

**On Connection (`connection` event):**
- [ ] Extract `driverId` from the URL query string (`ws://host:3003/drivers/connect?driverId=xxx`)
- [ ] Validate `driverId` is a valid UUID
- [ ] Query PostgreSQL to verify the driver exists and `is_active = true`
  - Invalid or inactive driver → close socket with code `4001` and reason `"Unauthorized"`
- [ ] Register connection in `Map<driverId, WebSocket>`
- [ ] Log new driver connection

**On Message (`message` event):**
- [ ] Parse incoming message as JSON: `{ lat, lng, timestamp }`
- [ ] Validate `lat` (−90 to 90), `lng` (−180 to 180), `timestamp` (number)
  - Invalid → send error frame back; do NOT crash
- [ ] Construct `GpsPing` and call `updateDriverPosition(ping)` (Redis write)
- [ ] Call `publishLocationUpdate(ping)` (RabbitMQ publish, fire-and-forget)
- [ ] Do NOT `await` both sequentially — use `Promise.allSettled` to run Redis + RabbitMQ in parallel

**On Close / Error (`close` / `error` events):**
- [ ] Remove `driverId` from the connection map
- [ ] Log disconnect with `driverId` and close code
- [ ] Do NOT crash the process on individual socket errors

**Heartbeat:**
- [ ] Send `ping` frames every 15 seconds to detect dead connections
- [ ] On `pong` received, mark connection as alive
- [ ] Terminate connections that have not responded to a ping within 30 seconds

---

### 4.9 — HTTP Route Handlers (`routes/drivers.ts`)

- [ ] `GET /drivers/:id/location`
  - Validate `:id` UUID format
  - Call `getDriverPosition(id)`
  - `200 { data: DriverLocation }` or `404 { error: "Driver offline or not found" }`

- [ ] `GET /drivers/nearby?lat=&lng=&radius=`
  - Parse and validate query params: `lat` (number, required), `lng` (number, required), `radius` (number, optional, default 5 km, max 50 km)
  - Call `getNearbyDrivers({ lat, lng, radius })`
  - `200 { data: DriverLocation[], count: number }`

- [ ] `GET /drivers` (admin)
  - Query `SELECT * FROM drivers ORDER BY name`
  - `200 { data: Driver[] }`

---

### 4.10 — Express App Entry Point (`index.ts`)

- [ ] Load env vars, create Express app
- [ ] Create Node.js `http.Server` (wrapping Express) — needed to attach the WebSocket server
- [ ] Mount drivers HTTP router at `/`
- [ ] `GET /health` → `{ status: "ok", service: "driver-location-service", activeConnections: Map.size }`
- [ ] Global error middleware
- [ ] On startup: initialise Redis, RabbitMQ, WebSocket server
- [ ] Start `http.server.listen` on `process.env.DRIVER_LOCATION_PORT || 3003`
- [ ] Start the periodic TTL cleanup job for the `drivers:ttl` sorted set (run every 10 seconds)

---

### 4.11 — TTL Cleanup Job

Drivers who stop sending pings must be removed from `drivers:active` automatically.

- [ ] `setInterval` every 10 seconds:
  - `ZRANGEBYSCORE drivers:ttl 0 {Date.now()}` → list of expired driver IDs
  - For each expired driver: `ZREM drivers:active {driverId}` + `ZREM drivers:ttl {driverId}`
- [ ] Log count of evicted drivers at each cleanup run

---

## API Contract Summary

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| WS | `ws://.../drivers/connect?driverId=` | Driver GPS stream connection | Persistent WS |
| GET | `/health` | Health check + active connection count | 200 |
| GET | `/drivers` | List all driver profiles | 200 `{ data: Driver[] }` |
| GET | `/drivers/:id/location` | Current position from Redis GEO | 200 / 404 |
| GET | `/drivers/nearby?lat&lng&radius` | Drivers within radius | 200 `{ data, count }` |

---

## Acceptance Criteria

- [ ] 10 simultaneous WebSocket connections can be established and send GPS pings without errors
- [ ] After a GPS ping, `GEOPOS drivers:active {driverId}` in Redis CLI returns the updated position
- [ ] After 30 seconds of no pings from a driver, the driver is removed from `drivers:active`
- [ ] `GET /drivers/nearby?lat=12.97&lng=77.59&radius=5` returns nearby active drivers
- [ ] After a GPS ping, the RabbitMQ exchange `driver.events` receives a message (verify via Management UI)
- [ ] Sending invalid JSON over WebSocket does not crash the service
- [ ] `GET /health` reports the number of currently active WebSocket connections
