# Task 01 — Infrastructure

Sets up all shared infrastructure: Docker images for every service, Docker Compose for local development, database initialisation scripts, and RabbitMQ topology.

---

## Subtasks

### 1.1 — Repository & Monorepo Layout

- [ ] Create the top-level monorepo folder structure:
  ```
  /
  ├── services/
  │   ├── restaurant-menu-service/
  │   ├── order-service/
  │   ├── driver-location-service/
  │   └── notification-service/
  ├── api-gateway/
  ├── infra/
  │   ├── postgres/
  │   │   └── init.sql          ← schema + seed SQL
  │   └── rabbitmq/
  │       └── definitions.json  ← exchanges & queues pre-provisioned
  ├── docker-compose.yml
  └── .env.example
  ```
- [ ] Add a root-level `.gitignore` (node_modules, dist, .env, *.log)
- [ ] Add a root-level `.env.example` with all required environment variable keys (no values)

---

### 1.2 — Dockerfile per Service

Create a **multi-stage Dockerfile** inside each service directory. All four services share the same pattern.

**Template (replicate for each service):**

```dockerfile
# Stage 1 — build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 — production image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE <PORT>
CMD ["node", "dist/index.js"]
```

- [ ] `services/restaurant-menu-service/Dockerfile` — EXPOSE 3001
- [ ] `services/order-service/Dockerfile` — EXPOSE 3002
- [ ] `services/driver-location-service/Dockerfile` — EXPOSE 3003
- [ ] `services/notification-service/Dockerfile` — EXPOSE 3004
- [ ] `api-gateway/Dockerfile` — EXPOSE 8080
- [ ] Add `.dockerignore` to each service (`node_modules`, `dist`, `.env`, `*.test.ts`)

---

### 1.3 — Docker Compose (`docker-compose.yml`)

Define all services + infrastructure in a single Compose file at the repo root.

**Services to declare:**

| Service | Image | Ports | Depends On |
|---------|-------|-------|-----------|
| `postgres` | `postgres:16-alpine` | 5432:5432 | — |
| `redis` | `redis:7-alpine` | 6379:6379 | — |
| `rabbitmq` | `rabbitmq:3-management-alpine` | 5672:5672, 15672:15672 | — |
| `restaurant-menu-service` | Build from `./services/restaurant-menu-service` | 3001:3001 | postgres, redis |
| `order-service` | Build from `./services/order-service` | 3002:3002 | postgres, redis, rabbitmq |
| `driver-location-service` | Build from `./services/driver-location-service` | 3003:3003 | postgres, redis, rabbitmq |
| `notification-service` | Build from `./services/notification-service` | 3004:3004 | redis, rabbitmq |
| `api-gateway` | Build from `./api-gateway` | 8080:8080 | All four services |

**Requirements:**
- [ ] Use a named Docker network (`food-delivery-net`, driver `bridge`) shared by all containers
- [ ] Mount `./infra/postgres/init.sql` as an init script into the postgres container (`/docker-entrypoint-initdb.d/`)
- [ ] Mount `./infra/rabbitmq/definitions.json` to pre-provision exchanges/queues (`RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS`)
- [ ] Add `healthcheck` to `postgres` (pg_isready), `redis` (redis-cli ping), and `rabbitmq` (rabbitmq-diagnostics ping)
- [ ] Service containers must use `depends_on: { condition: service_healthy }` so they only start after infra is healthy
- [ ] Pass all secrets via environment variables sourced from the root `.env` file (`env_file: .env`)
- [ ] Add `restart: unless-stopped` to all infrastructure containers
- [ ] Add named volumes for `postgres_data` and `redis_data` to survive container restarts

---

### 1.4 — PostgreSQL Initialisation Script (`infra/postgres/init.sql`)

A single SQL file that is auto-executed by the postgres container on first start.

- [ ] Create the `restaurants` table (UUID PK, name, address, lat, lng, is_open, created_at, updated_at)
- [ ] Create the `menu_categories` table (UUID PK, restaurant_id FK → restaurants, name, display_order)
- [ ] Create the `menu_items` table (UUID PK, category_id FK → menu_categories, restaurant_id FK → restaurants, name, description, price DECIMAL(10,2), is_available)
- [ ] Create the `drivers` table (UUID PK, name, phone UNIQUE, vehicle, is_active, created_at)
- [ ] Create the `orders` table (UUID PK, restaurant_id, driver_id nullable, status VARCHAR(50) DEFAULT 'PENDING', total_amount DECIMAL(10,2), payment_status, payment_txn_id, created_at, updated_at)
- [ ] Create the `order_items` table (UUID PK, order_id FK → orders CASCADE DELETE, menu_item_id UUID, name VARCHAR snapshot, price_at_time DECIMAL(10,2) snapshot, quantity INT CHECK > 0)
- [ ] Add indexes:
  - `orders(status)` — for status-based queries
  - `order_items(order_id)` — for order detail lookups
  - `menu_items(restaurant_id)` — for menu fetches
- [ ] Seed at least **2 restaurants**, **2 menu categories each**, **3 menu items per category**, and **3 drivers** for local testing

---

### 1.5 — RabbitMQ Topology (`infra/rabbitmq/definitions.json`)

Pre-provision exchanges and queues so services can connect without manual setup.

- [ ] Declare exchange `order.events` — type `fanout`, durable
- [ ] Declare exchange `driver.events` — type `direct`, durable
- [ ] Declare queue `orders.notification` — durable, bound to `order.events` fanout
- [ ] Declare queue `orders.driver-assign` — durable, bound to `order.events` fanout (reserved for future driver assignment logic)
- [ ] Declare queue `driver.location.notification` — durable, bound to `driver.events` direct exchange with routing key `driver.location.updated`
- [ ] Set `x-message-ttl: 60000` (1 minute) on `driver.location.notification` to auto-drop stale GPS messages if the Notification Service is slow

---

### 1.6 — Environment Variables (`.env.example`)

Document every required environment variable. Actual `.env` must never be committed.

```
# PostgreSQL
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=food_delivery

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# RabbitMQ
RABBITMQ_URL=amqp://admin:admin123@rabbitmq:5672

# Service ports
RESTAURANT_MENU_PORT=3001
ORDER_SERVICE_PORT=3002
DRIVER_LOCATION_PORT=3003
NOTIFICATION_PORT=3004
API_GATEWAY_PORT=8080

# Node
NODE_ENV=development
```

- [ ] Create `.env.example` with all keys above (empty values)
- [ ] Ensure `.env` is in `.gitignore`

---

### 1.7 — Shared TypeScript Config

- [ ] Create a root `tsconfig.base.json` with strict settings (`strict: true`, `target: ES2022`, `module: NodeNext`, `moduleResolution: NodeNext`)
- [ ] Each service's `tsconfig.json` extends `../../tsconfig.base.json`

---

## Acceptance Criteria

- [ ] `docker compose up --build` starts all containers without errors
- [ ] `psql -U <user> -d food_delivery -c "\dt"` lists all 6 tables
- [ ] `redis-cli ping` returns `PONG`
- [ ] RabbitMQ Management UI (`http://localhost:15672`) shows all 3 exchanges and 3 queues
- [ ] All four service containers reach `healthy` status before the API Gateway starts
- [ ] Postgres data persists across `docker compose down` + `docker compose up` (named volume)
