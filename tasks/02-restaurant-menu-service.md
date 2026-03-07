# Task 02 — Restaurant & Menu Service

**Port:** 3001  
**Responsibility:** Manage restaurant and menu data. Serve menu responses with Redis cache-aside pattern to achieve P99 < 200ms under load.  
**Stack:** Node.js 20 + TypeScript, PostgreSQL 16, Redis 7

---

## Subtasks

### 2.1 — Project Scaffolding

- [ ] Initialise `services/restaurant-menu-service/` as a Node.js TypeScript project
  - `npm init -y`
  - Install runtime deps: `express`, `pg`, `ioredis`, `uuid`, `dotenv`
  - Install dev deps: `typescript`, `@types/express`, `@types/pg`, `@types/node`, `ts-node-dev`, `@types/uuid`
- [ ] Create `tsconfig.json` extending root `tsconfig.base.json`
- [ ] Add npm scripts: `build` (`tsc`), `start` (`node dist/index.js`), `dev` (`ts-node-dev src/index.ts`)
- [ ] Create folder structure:
  ```
  src/
  ├── index.ts            ← Express app entry point
  ├── config/
  │   └── db.ts           ← PostgreSQL pool
  │   └── redis.ts        ← ioredis client
  ├── routes/
  │   └── restaurants.ts  ← route handlers
  ├── services/
  │   └── menuService.ts  ← business logic + cache logic
  └── types/
      └── index.ts        ← shared TypeScript interfaces
  ```

---

### 2.2 — Database Client (`config/db.ts`)

- [ ] Create a `pg.Pool` using environment variables (`POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`)
- [ ] Export a `query(text, params)` helper that wraps `pool.query`
- [ ] Add connection error logging on pool `error` event

---

### 2.3 — Redis Client (`config/redis.ts`)

- [ ] Create an `ioredis` client using `REDIS_HOST` and `REDIS_PORT`
- [ ] Export a singleton `redisClient`
- [ ] Add reconnect strategy with exponential back-off (max 3 retries)
- [ ] Log connection errors without crashing the process

---

### 2.4 — TypeScript Types (`types/index.ts`)

Define and export the following interfaces:

- [ ] `Restaurant` — id, name, address, lat, lng, is_open, created_at, updated_at
- [ ] `MenuCategory` — id, restaurant_id, name, display_order
- [ ] `MenuItem` — id, category_id, restaurant_id, name, description, price, is_available
- [ ] `FullMenu` — restaurant: Restaurant, categories: Array<MenuCategory & { items: MenuItem[] }>

---

### 2.5 — Menu Service Logic (`services/menuService.ts`)

Implements the cache-aside pattern described in `ARCHITECTURE.md`.

**`getFullMenu(restaurantId: string): Promise<FullMenu | null>`**
- [ ] Check Redis for key `menu:{restaurantId}`
  - Cache HIT → parse JSON, return `FullMenu` (~5ms)
  - Cache MISS → run PostgreSQL query (JOIN restaurants + menu_categories + menu_items), assemble `FullMenu`, write to Redis with TTL 60s, return `FullMenu` (~80–120ms)
- [ ] Return `null` if no restaurant found with that ID

**`invalidateMenuCache(restaurantId: string): Promise<void>`**
- [ ] `DEL menu:{restaurantId}` from Redis
- [ ] Called after any admin mutation (update menu item, create category, etc.)

**`getAllRestaurants(): Promise<Restaurant[]>`**
- [ ] Query `SELECT * FROM restaurants ORDER BY name`
- [ ] Cache result under `restaurants:list` with TTL 30s

**`createRestaurant(data): Promise<Restaurant>`**
- [ ] `INSERT INTO restaurants` and return the created row
- [ ] Invalidate `restaurants:list` cache after insert

**`updateMenuItem(restaurantId, itemId, data): Promise<MenuItem | null>`**
- [ ] `UPDATE menu_items SET ... WHERE id = $1` 
- [ ] Call `invalidateMenuCache(restaurantId)` after successful update
- [ ] Return updated row or `null` if not found

---

### 2.6 — Route Handlers (`routes/restaurants.ts`)

- [ ] `GET /restaurants`
  - Call `getAllRestaurants()`
  - Respond `200` with `{ data: Restaurant[] }`

- [ ] `GET /restaurants/:id/menu`
  - Call `getFullMenu(req.params.id)`
  - Respond `200` with `{ data: FullMenu }` or `404` if not found
  - Add response header `X-Cache: HIT` or `X-Cache: MISS` for observability

- [ ] `POST /restaurants`
  - Validate body: `name` (required), `address` (required), `lat`, `lng` (required, numeric)
  - Call `createRestaurant(body)`
  - Respond `201` with `{ data: Restaurant }`

- [ ] `PUT /restaurants/:id/menu-items/:itemId`
  - Validate body: at least one of `name`, `price`, `description`, `is_available` present
  - Call `updateMenuItem(req.params.id, req.params.itemId, body)`
  - Respond `200` with `{ data: MenuItem }` or `404`

---

### 2.7 — Express App Entry Point (`index.ts`)

- [ ] Load `.env` via `dotenv`
- [ ] Create Express app with `express.json()` middleware
- [ ] Mount `restaurants` router at `/`
- [ ] Add a `GET /health` endpoint returning `{ status: "ok", service: "restaurant-menu-service" }`
- [ ] Add global error-handling middleware (catches unhandled errors, returns `500`)
- [ ] Listen on `process.env.RESTAURANT_MENU_PORT || 3001`
- [ ] Log startup message with port number

---

### 2.8 — Error Handling & Validation

- [ ] Validate UUID format for `:id` and `:itemId` params — return `400` if invalid
- [ ] Catch PostgreSQL errors (`pg` error codes) and return appropriate HTTP responses
- [ ] Catch Redis errors gracefully — on Redis unavailability, fall through to PostgreSQL (degrade gracefully)

---

## API Contract Summary

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| GET | `/health` | Health check | 200 `{ status }` |
| GET | `/restaurants` | List all restaurants | 200 `{ data: Restaurant[] }` |
| GET | `/restaurants/:id/menu` | Get full menu (cached) | 200 `{ data: FullMenu }` / 404 |
| POST | `/restaurants` | Create restaurant | 201 `{ data: Restaurant }` |
| PUT | `/restaurants/:id/menu-items/:itemId` | Update menu item + invalidate cache | 200 `{ data: MenuItem }` / 404 |

---

## Acceptance Criteria

- [ ] `GET /restaurants/:id/menu` returns in < 10ms on cache HIT (verify with `X-Cache: HIT` header)
- [ ] `GET /restaurants/:id/menu` returns in < 150ms on cache MISS
- [ ] After `PUT /restaurants/:id/menu-items/:itemId`, the next `GET` is a cache MISS (cache invalidated)
- [ ] `POST /restaurants` with missing required fields returns `400`
- [ ] Service starts cleanly when Redis is unavailable (degrades to DB-only mode)
- [ ] All routes respond with `Content-Type: application/json`
