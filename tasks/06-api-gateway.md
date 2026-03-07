# Task 06 — API Gateway

**Port:** 8080  
**Responsibility:** Single entry point for all client traffic. Routes HTTP requests to downstream services, proxies WebSocket upgrades, enforces rate limiting, and provides a unified health check endpoint.  
**Stack:** Node.js 20 + TypeScript, `express`, `http-proxy-middleware` (HTTP), `http-proxy` (WebSocket upgrade)

---

## Subtasks

### 6.1 — Project Scaffolding

- [ ] Initialise `api-gateway/` as a Node.js TypeScript project
  - Runtime deps: `express`, `http-proxy-middleware`, `http-proxy`, `express-rate-limit`, `dotenv`, `uuid`
  - Dev deps: `typescript`, `@types/express`, `@types/node`, `ts-node-dev`
- [ ] Create `tsconfig.json` extending root `tsconfig.base.json`
- [ ] Add npm scripts: `build`, `start`, `dev`
- [ ] Folder structure:
  ```
  src/
  ├── index.ts
  ├── config/
  │   └── routes.ts        ← route-to-service mapping configuration
  ├── middleware/
  │   ├── rateLimiter.ts   ← express-rate-limit configuration
  │   └── requestLogger.ts ← request/response logging
  └── proxy/
      ├── httpProxy.ts     ← HTTP reverse proxy setup
      └── wsProxy.ts       ← WebSocket upgrade proxy setup
  ```

---

### 6.2 — Route Configuration (`config/routes.ts`)

Define the mapping from gateway paths to downstream service URLs:

```typescript
export const SERVICE_URLS = {
  restaurantMenu: process.env.RESTAURANT_MENU_URL || 'http://restaurant-menu-service:3001',
  order:          process.env.ORDER_SERVICE_URL   || 'http://order-service:3002',
  driverLocation: process.env.DRIVER_LOCATION_URL || 'http://driver-location-service:3003',
  notification:   process.env.NOTIFICATION_URL    || 'http://notification-service:3004',
}
```

**Route Table:**

| Gateway Path Prefix | Downstream Service | Notes |
|--------------------|--------------------|-------|
| `/api/restaurants` | restaurant-menu-service:3001 | HTTP only |
| `/api/orders` | order-service:3002 | HTTP only |
| `/api/drivers` | driver-location-service:3003 | HTTP only |
| `/ws/drivers/connect` | driver-location-service:3003 | WebSocket upgrade |
| `/ws/track` | notification-service:3004 | WebSocket upgrade |
| `/api/health` | (handled locally) | Gateway health check |

- [ ] Export `SERVICE_URLS` and the route table as typed constants

---

### 6.3 — Request Logger Middleware (`middleware/requestLogger.ts`)

- [ ] Log every incoming request: `[timestamp] METHOD /path → downstream-service (status) Xms`
- [ ] Attach a unique `X-Request-ID` header (UUID) to each request for distributed tracing
- [ ] Forward `X-Request-ID` to downstream services

---

### 6.4 — Rate Limiter Middleware (`middleware/rateLimiter.ts`)

Use `express-rate-limit` to protect services from excessive traffic.

- [ ] Create a **global rate limiter** applied to all routes:
  - Window: 1 minute
  - Max requests: 500 per IP per window
  - Response on limit exceeded: `429 Too Many Requests` with `{ error: "Rate limit exceeded. Try again in 1 minute." }`
- [ ] Create a **strict rate limiter** for order placement (`POST /api/orders`):
  - Window: 1 minute
  - Max requests: 10 per IP per window (prevents order spam)
  - Response: `429` with `{ error: "Too many orders placed. Please wait." }`
- [ ] Add `X-RateLimit-Limit` and `X-RateLimit-Remaining` headers to all responses

---

### 6.5 — HTTP Proxy (`proxy/httpProxy.ts`)

Use `http-proxy-middleware` to forward requests to downstream services.

- [ ] Create a proxy factory function `createProxy(target: string, pathRewrite?: Record<string, string>)`
- [ ] Configure each proxy:
  - `changeOrigin: true`
  - `pathRewrite` to strip the `/api` prefix before forwarding (e.g. `/api/restaurants` → `/restaurants`)
  - On proxy error → respond `502 Bad Gateway` with `{ error: "Upstream service unavailable" }`
- [ ] Register proxies for all HTTP routes in the route table
- [ ] Forward the `X-Request-ID` header added by the logger middleware

---

### 6.6 — WebSocket Proxy (`proxy/wsProxy.ts`)

WebSocket upgrades must be handled separately from HTTP — `http-proxy-middleware` alone does not reliably proxy WebSocket connections in all configurations.

- [ ] Use the `http-proxy` library to create a dedicated proxy for WebSocket upgrades
- [ ] On the HTTP server's `upgrade` event:
  - Parse the request URL to determine target service
  - `/ws/drivers/connect` → forward to `driver-location-service:3003/drivers/connect`
  - `/ws/track/*` → forward to `notification-service:3004/track/*` (preserve the trailing path)
  - Unknown path → destroy the socket with a `400 Bad Request` response
- [ ] Log WebSocket upgrade events with `X-Request-ID`

---

### 6.7 — Express App Entry Point (`index.ts`)

- [ ] Load env vars via `dotenv`
- [ ] Create Express app
- [ ] Apply middleware in order:
  1. `requestLogger` (first — tags every request with `X-Request-ID`)
  2. `globalRateLimiter`
  3. `express.json()` (for reading body on gateway-handled routes)
- [ ] Mount routes:
  - `GET /api/health` — local handler: `{ status: "ok", service: "api-gateway", uptime: process.uptime() }`
  - `GET /api/restaurants*` — proxy to restaurant-menu-service
  - `POST /api/restaurants*` — proxy (with strict rate limiter removed; admin route)
  - `PUT /api/restaurants*` — proxy
  - `GET /api/orders*` — proxy
  - `POST /api/orders` — apply `orderRateLimiter` then proxy
  - `PATCH /api/orders*` — proxy
  - `GET /api/drivers*` — proxy
  - Catch-all `404` handler for unmatched routes
- [ ] Create `http.Server` from the Express app (needed for WebSocket upgrade handling)
- [ ] Attach WebSocket upgrade handler to the `http.Server`
- [ ] Listen on `process.env.API_GATEWAY_PORT || 8080`
- [ ] Log all upstream service URLs at startup for debuggability

---

### 6.8 — CORS Configuration

- [ ] Add `cors` middleware (install `cors` and `@types/cors`)
- [ ] Allow requests from `http://localhost:*` in development
- [ ] Expose `X-Request-ID`, `X-RateLimit-Limit`, `X-RateLimit-Remaining` headers to browsers
- [ ] Allow `Idempotency-Key` header in `Access-Control-Allow-Headers`

---

## API Contract Summary (Gateway-level)

All client-facing URLs go through port **8080**:

| Client Request | Forwarded To |
|---------------|-------------|
| `GET http://localhost:8080/api/restaurants` | `restaurant-menu-service:3001/restaurants` |
| `GET http://localhost:8080/api/restaurants/:id/menu` | `restaurant-menu-service:3001/restaurants/:id/menu` |
| `POST http://localhost:8080/api/orders` | `order-service:3002/orders` |
| `GET http://localhost:8080/api/orders/:id` | `order-service:3002/orders/:id` |
| `PATCH http://localhost:8080/api/orders/:id/status` | `order-service:3002/orders/:id/status` |
| `GET http://localhost:8080/api/drivers/:id/location` | `driver-location-service:3003/drivers/:id/location` |
| `GET http://localhost:8080/api/drivers/nearby?...` | `driver-location-service:3003/drivers/nearby?...` |
| `ws://localhost:8080/ws/drivers/connect?driverId=` | `driver-location-service:3003/drivers/connect?driverId=` |
| `ws://localhost:8080/ws/track/{orderId}` | `notification-service:3004/track/{orderId}` |

---

## Acceptance Criteria

- [ ] `GET http://localhost:8080/api/restaurants` returns the same response as `GET http://localhost:3001/restaurants`
- [ ] WebSocket connection to `ws://localhost:8080/ws/drivers/connect?driverId=<id>` works end-to-end
- [ ] WebSocket connection to `ws://localhost:8080/ws/track/<orderId>` works end-to-end
- [ ] Sending more than 10 `POST /api/orders` requests in 1 minute from the same IP returns `429`
- [ ] Every response includes `X-Request-ID` header
- [ ] When a downstream service is down, the gateway returns `502` (not an unhandled crash)
- [ ] `GET /api/health` returns `200` regardless of downstream service state
