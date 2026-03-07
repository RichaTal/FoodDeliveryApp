# Task 03 — Order Service

**Port:** 3002  
**Responsibility:** Accept and validate incoming orders, mock payment processing, write orders to PostgreSQL inside an ACID transaction, and publish `order.placed` / `order.status.updated` events to RabbitMQ.  
**Stack:** Node.js 20 + TypeScript, PostgreSQL 16, Redis 7 (idempotency), RabbitMQ 3

---

## Subtasks

### 3.1 — Project Scaffolding

- [ ] Initialise `services/order-service/` as a Node.js TypeScript project
  - Runtime deps: `express`, `pg`, `ioredis`, `amqplib`, `uuid`, `dotenv`
  - Dev deps: `typescript`, `@types/express`, `@types/pg`, `@types/amqplib`, `@types/node`, `ts-node-dev`, `@types/uuid`
- [ ] Create `tsconfig.json` extending root `tsconfig.base.json`
- [ ] Add npm scripts: `build`, `start`, `dev`
- [ ] Folder structure:
  ```
  src/
  ├── index.ts
  ├── config/
  │   ├── db.ts
  │   ├── redis.ts
  │   └── rabbitmq.ts       ← RabbitMQ channel factory
  ├── routes/
  │   └── orders.ts
  ├── services/
  │   ├── orderService.ts   ← core business logic
  │   ├── paymentStub.ts    ← mock payment gateway
  │   └── publisher.ts      ← RabbitMQ publish helpers
  └── types/
      └── index.ts
  ```

---

### 3.2 — Database Client (`config/db.ts`)

- [ ] Same pattern as Restaurant & Menu Service: `pg.Pool` from env vars
- [ ] Export `query` helper and `getClient()` for manual transaction management (BEGIN / COMMIT / ROLLBACK)

---

### 3.3 — Redis Client (`config/redis.ts`)

- [ ] Same singleton `ioredis` pattern as Task 02
- [ ] Used exclusively for idempotency key storage

---

### 3.4 — RabbitMQ Connection (`config/rabbitmq.ts`)

- [ ] Connect to RabbitMQ using `RABBITMQ_URL` env var
- [ ] Create and export a durable channel
- [ ] Assert the following exchanges on startup (they will already exist from `definitions.json`, but assert is idempotent):
  - `order.events` — type `fanout`, durable
- [ ] Add reconnect logic: if connection drops, retry with exponential back-off (max 5 retries, then exit with code 1)
- [ ] Log connection lifecycle events (connected, disconnected, reconnecting)

---

### 3.5 — TypeScript Types (`types/index.ts`)

- [ ] `OrderStatus` — enum: `PENDING | CONFIRMED | PREPARING | PICKED_UP | DELIVERED | CANCELLED`
- [ ] `PaymentStatus` — enum: `PENDING | SUCCESS | FAILED`
- [ ] `CreateOrderBody` — restaurantId, items: Array<{ menuItemId, quantity }>
- [ ] `OrderItem` — id, order_id, menu_item_id, name, price_at_time, quantity
- [ ] `Order` — id, restaurant_id, driver_id (nullable), status, total_amount, payment_status, payment_txn_id, created_at, updated_at, items?: OrderItem[]
- [ ] `PaymentResult` — success: boolean, transactionId: string

---

### 3.6 — Payment Stub (`services/paymentStub.ts`)

Mock of an external payment gateway. **No real payment processing.**

- [ ] Export `async function processPayment(amount: number, orderId: string): Promise<PaymentResult>`
- [ ] Always return `{ success: true, transactionId: uuid() }` (simulates a successful charge)
- [ ] Add a 50–100ms artificial delay (`await sleep(75)`) to simulate network latency
- [ ] Log the mock payment attempt with amount and orderId for traceability

> **Note:** In a real system, this would call Stripe / Razorpay. The stub allows order flow testing without payment credentials.

---

### 3.7 — Publisher (`services/publisher.ts`)

- [ ] `publishOrderPlaced(order: Order): Promise<void>`
  - Publish to exchange `order.events` with routing key `''` (fanout ignores routing key)
  - Payload: `{ orderId, restaurantId, items, totalAmount, timestamp }`
  - Set `persistent: true` on the message (survives broker restart)

- [ ] `publishOrderStatusUpdated(orderId: string, status: OrderStatus): Promise<void>`
  - Publish to exchange `order.events`
  - Payload: `{ orderId, status, timestamp }`
  - Set `persistent: true`

---

### 3.8 — Order Service Logic (`services/orderService.ts`)

**`placeOrder(body: CreateOrderBody, idempotencyKey: string): Promise<Order>`**

Implement the full flow described in `ARCHITECTURE.md`:

- [ ] **Idempotency check** — check Redis for `idempotency:{idempotencyKey}`
  - If key exists → return the previously created order (do not re-process)
  - If not → continue
- [ ] **Validate restaurant** — query PostgreSQL: does `restaurantId` exist and `is_open = true`?
  - If closed or not found → throw `RestaurantNotAvailableError`
- [ ] **Validate menu items** — for each `menuItemId` in request, check `menu_items` table that item exists, belongs to the restaurant, and `is_available = true`; fetch `name` and `price`
  - Any invalid item → throw `MenuItemNotAvailableError`
- [ ] **Calculate total** — sum `price × quantity` for all items
- [ ] **Mock payment** — call `processPayment(total, generatedOrderId)`
  - Payment fail → throw `PaymentFailedError` (in stub this never happens but must be handled)
- [ ] **ACID transaction** — inside a single PostgreSQL client transaction:
  - `INSERT INTO orders (...)` with `status = 'PENDING'`, `payment_status = 'SUCCESS'`, `payment_txn_id`
  - `INSERT INTO order_items (...)` for each item with `name` and `price_at_time` snapshots
  - `COMMIT`
- [ ] **Store idempotency key** — `SET idempotency:{idempotencyKey} {orderId} EX 86400` (24h TTL)
- [ ] **Publish event** — call `publishOrderPlaced(order)`
- [ ] Return created `Order` with items

**`getOrder(orderId: string): Promise<Order | null>`**
- [ ] `SELECT * FROM orders WHERE id = $1`
- [ ] Join with `order_items` to populate `items` array
- [ ] Return `null` if not found

**`updateOrderStatus(orderId: string, newStatus: OrderStatus): Promise<Order | null>`**
- [ ] Validate the status transition is legal (see lifecycle below)
- [ ] `UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2`
- [ ] Call `publishOrderStatusUpdated(orderId, newStatus)`
- [ ] Return updated order or `null`

**Order Status Lifecycle (enforce these transitions):**
```
PENDING → CONFIRMED → PREPARING → PICKED_UP → DELIVERED
Any status → CANCELLED (except DELIVERED)
```

---

### 3.9 — Route Handlers (`routes/orders.ts`)

- [ ] `POST /orders`
  - Extract `Idempotency-Key` header (required — return `400` if missing)
  - Validate body: `restaurantId` (UUID), `items` (non-empty array with `menuItemId` UUID + `quantity` > 0)
  - Call `placeOrder(body, idempotencyKey)`
  - Respond `202 Accepted` with `{ data: { orderId, status: 'PENDING' } }`
  - On `RestaurantNotAvailableError` → `422`
  - On `MenuItemNotAvailableError` → `422`
  - On `PaymentFailedError` → `402`

- [ ] `GET /orders/:id`
  - Validate `:id` is a valid UUID
  - Call `getOrder(req.params.id)`
  - Respond `200 { data: Order }` or `404`

- [ ] `PATCH /orders/:id/status`
  - Validate body: `status` is one of the valid `OrderStatus` values
  - Call `updateOrderStatus(req.params.id, body.status)`
  - Respond `200 { data: Order }` or `404` or `400` for invalid transition

---

### 3.10 — Express App Entry Point (`index.ts`)

- [ ] Load env vars, create Express app with `express.json()`
- [ ] Mount orders router at `/`
- [ ] `GET /health` → `{ status: "ok", service: "order-service" }`
- [ ] Global error middleware
- [ ] Listen on `process.env.ORDER_SERVICE_PORT || 3002`
- [ ] On startup, initialise RabbitMQ connection (from `config/rabbitmq.ts`)

---

## API Contract Summary

| Method | Path | Headers | Description | Response |
|--------|------|---------|-------------|----------|
| GET | `/health` | — | Health check | 200 |
| POST | `/orders` | `Idempotency-Key: <uuid>` | Place an order | 202 / 400 / 402 / 422 |
| GET | `/orders/:id` | — | Get order + items | 200 / 404 |
| PATCH | `/orders/:id/status` | — | Update order status | 200 / 400 / 404 |

---

## Acceptance Criteria

- [ ] `POST /orders` with a valid body returns `202` and an `orderId`
- [ ] Sending the same `POST /orders` with identical `Idempotency-Key` twice returns the same `orderId` without creating a duplicate order in PostgreSQL
- [ ] `GET /orders/:id` returns the order with a nested `items` array including `price_at_time` snapshots
- [ ] After `POST /orders`, the RabbitMQ exchange `order.events` receives a message (verify via Management UI)
- [ ] `PATCH /orders/:id/status` with an invalid transition (e.g. `DELIVERED → CONFIRMED`) returns `400`
- [ ] `POST /orders` for a closed restaurant returns `422`
