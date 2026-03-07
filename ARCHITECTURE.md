# Food Delivery Application — Architecture Document

## Table of Contents

1. [Overview](#overview)
2. [Requirements Summary](#requirements-summary)
3. [Architecture Style](#architecture-style)
4. [Core Services](#core-services)
5. [Technology Decisions](#technology-decisions)
   - [Database — PostgreSQL over MongoDB](#database--postgresql-over-mongodb)
   - [Cache — Redis over Memcached](#cache--redis-over-memcached)
   - [Messaging — RabbitMQ over Kafka](#messaging--rabbitmq-over-kafka)
6. [System Architecture Diagram](#system-architecture-diagram)
7. [Service-by-Service Breakdown](#service-by-service-breakdown)
   - [Restaurant & Menu Service](#1-restaurant--menu-service)
   - [Order Service](#2-order-service)
   - [Driver Location Service](#3-driver-location-service)
   - [Notification Service](#4-notification-service)
8. [Database Design](#database-design)
9. [Caching Strategy](#caching-strategy)
10. [Messaging Strategy](#messaging-strategy)
11. [Real-Time Driver Tracking Flow](#real-time-driver-tracking-flow)
12. [Infrastructure Summary](#infrastructure-summary)
13. [Scale Analysis](#scale-analysis)

---

## Overview

This document describes the architecture for a food delivery platform designed to handle high-throughput order processing, low-latency menu browsing, and real-time GPS tracking of delivery drivers.

**Out of scope (for now):**
- Payment gateway (mocked with a stub returning success/failure)

---

## Requirements Summary

| # | Requirement | Target |
|---|---|---|
| 2.1 | Peak order processing | 500 orders/minute |
| 2.2 | Menu & restaurant browse P99 response time | < 200ms under heavy load |
| 2.3 | Ingest GPS from concurrent drivers | 10,000 drivers × 1 update/5s = 2,000 events/sec |
| 2.3 | Customer-facing live driver tracking | Real-time location pushed to customer |

---

## Architecture Pattern and why I selected it

**Microservices with an Event-Driven Core**

Each of the three requirements has a fundamentally different performance profile:

- Order processing → **throughput-bound** (high write volume, needs queue-based decoupling)
- Menu browsing → **latency-bound** (fast reads, needs aggressive caching)
- GPS tracking → **frequency-bound** (extreme write rate, needs in-memory geospatial store)

A monolithic architecture cannot scale these three dimensions independently. Microservices allow each service to be scaled, deployed, and optimised in isolation based on its specific load profile.

---

## Core Services

The application is composed of **4 core services**:

| Service | Responsibility |
|---|---|
| Restaurant & Menu Service | Manage restaurants, menus, and serve menu data with caching |
| Order Service | Accept, validate, and process orders; mock payment |
| Driver Location Service | Ingest GPS pings from drivers; maintain live positions |
| Notification Service | Push real-time updates (location, order status) to customers |

---

## Technology Decisions and Justifications for the Decisions

### Database — PostgreSQL over MongoDB

**Decision: PostgreSQL as the primary database**

#### Why PostgreSQL?

The core domain of this application is **inherently relational**:

```
Restaurant ──< MenuCategory ──< MenuItem
    │
Order ──< OrderItem ──> MenuItem (price snapshot)
    │
    └──> Driver
```

An order references a restaurant, line items reference menu items (with a price snapshot at the time of order), and a driver is assigned to an order. These are hard foreign-key relationships that benefit from referential integrity enforced at the database level.

| Concern | PostgreSQL | MongoDB |
|---|---|---|
| ACID transactions | ✅ Full ACID — critical for financial/order data | ⚠️ Multi-document transactions added in v4.0, still have overhead |
| Relational joins | ✅ Native, performant | ❌ No joins — requires `$lookup` or denormalisation |
| Schema enforcement | ✅ Strict schema catches data bugs early | ⚠️ Schema-less is flexible but risky for financial records |
| Price snapshotting on orders | ✅ Natural with `price_at_time` column | ⚠️ Requires careful denormalisation |
| Geospatial queries | ✅ PostGIS extension available | ✅ Built-in geo support |
| Operational familiarity | ✅ Widely understood | ✅ Widely understood |

**Why NOT MongoDB?**

MongoDB's flexible schema is its strength when data is unstructured or highly variable. The food delivery domain does not have that characteristic. Every order has the same well-defined structure. Using MongoDB here would mean:
- Manually enforcing referential integrity in application code
- Denormalising data (storing menu item prices inside orders) to avoid expensive `$lookup` aggregations
- Losing ACID guarantees on multi-collection writes (e.g., creating an order while decrementing stock)

**Conclusion:** PostgreSQL's relational model is a natural fit. MongoDB would add complexity without adding value for this domain.

---

### Cache — Redis over Memcached

**Decision: Redis as the caching and in-memory data layer**

#### Why Redis?

Redis was chosen not purely as a cache, but because the Driver Location Service requires **native geospatial commands** that no other lightweight caching tool provides.

```
GEOADD  drivers:active 77.5946 12.9716 "driver_42"    ← write GPS position
GEORADIUS drivers:active 77.59 12.97 5 km              ← find drivers near restaurant
GEODIST  drivers:active "driver_42" "restaurant_1" km  ← calculate distance
```

| Concern | Redis | Memcached |
|---|---|---|
| Raw key-value speed | ✅ Sub-millisecond | ✅ Sub-millisecond (slightly faster, multi-threaded) |
| Geospatial commands | ✅ GEOADD, GEORADIUS, GEODIST | ❌ **Not supported** |
| TTL support | ✅ Per-key TTL | ✅ Per-key TTL |
| Data structures | ✅ Strings, Hashes, Sets, Sorted Sets, Geo | ❌ Strings only |
| Pub/Sub | ✅ Yes | ❌ No |
| Persistence | ✅ Optional (RDB/AOF) | ❌ No — volatile only |
| Multi-instance coordination | ✅ Shared state across service instances | ⚠️ Requires client-side sharding |

**The Decisive Factor:**

The GPS tracking requirement makes Redis a **hard dependency**. Memcached has no geospatial support — there is no alternative lightweight tool that supports `GEORADIUS`-style queries. Once Redis is in the stack for the Driver Location Service, using it for all other caching needs (menu cache, idempotency keys, session registry) eliminates the need to operate a second caching infrastructure.

**Why NOT Memcached?**

Memcached would cover menu caching, idempotency keys, and WebSocket session mapping adequately — it is simpler and slightly faster for pure key-value workloads. However, it cannot fulfill the geospatial requirement, making it an incomplete solution. Running both Memcached and Redis would add operational overhead with no benefit.

**Why NOT in-process caching (e.g., `node-cache`, `lru-cache`)?**

In-process caches are fastest (no network hop) but break when services scale horizontally — each instance holds a different version of the cache. This is not acceptable for a production system.

**Conclusion:** Redis is the only caching tool that satisfies all four use cases in a single deployment. It is the correct choice.

---

### Messaging — RabbitMQ over Kafka

**Decision: RabbitMQ as the message broker**

#### Scale Reality Check

Before choosing a message broker, the actual event volume was re-examined:

| Event Type | Volume | Events/Second |
|---|---|---|
| Orders | 500/minute | ~8.3/sec |
| GPS pings | 10,000 drivers × 1/5s | 2,000/sec |
| Order status updates | ~4 per order | ~33/sec |
| **Total Peak** | | **~2,033 events/sec** |

#### Capacity Comparison

| Broker | Throughput Capacity | Our Peak Load | Utilisation |
|---|---|---|---|
| RabbitMQ | ~20,000–50,000 msg/sec | ~2,033/sec | ~4–10% |
| Kafka | Millions/sec | ~2,033/sec | ~0.002% |

Kafka would operate at a fraction of a percent of its capacity — it is significantly over-engineered for this scale.

#### Feature Comparison

| Feature | RabbitMQ | Kafka | Do We Need It? |
|---|---|---|---|
| High throughput (>50K/sec) | ❌ | ✅ | ❌ No — 2K/sec is our peak |
| Message retention & replay | ❌ (consumed = deleted) | ✅ | ❌ Not in core requirements |
| Multiple independent consumers | ✅ Via Fanout Exchange | ✅ Via Consumer Groups | ✅ Yes — covered by both |
| Message routing (topic/fanout) | ✅ Flexible exchanges | ✅ Topics | ✅ Yes — covered by both |
| Operational simplicity | ✅ Simple to set up | ❌ Complex (partitions, offsets, KRaft) | ✅ Prefer simpler |
| Learning curve | Gentle | Steep | ✅ Prefer gentler |

#### How RabbitMQ Covers the Use Cases

**Order placed — multiple consumers:**
```
Order Service
      │
      ▼
[Fanout Exchange: order.placed]
      ├──→ Queue: notification-service   (notify customer — order confirmed)
      └──→ Queue: driver-assignment      (find available driver)
```

**GPS update — notification fanout:**
```
Driver Location Service
      │
      ▼
[Direct Exchange: driver.location.updated]
      └──→ Queue: notification-service   (push to customer tracking this order)
```

**Why NOT Kafka?**

Kafka's two unique advantages over RabbitMQ are:
1. **Message retention & replay** — valuable for event sourcing and analytics pipelines
2. **Massive throughput** — millions of messages/second

Neither of these is required in the current scope. Kafka introduces significant operational complexity: partition strategy, offset management, consumer group coordination, and KRaft/ZooKeeper setup. This complexity is not justified at 2,033 events/second.

**When to migrate to Kafka:**
- GPS fleet grows beyond 50,000 concurrent drivers
- Analytics pipeline requiring event replay is introduced
- 5+ independent services consuming the same event stream simultaneously
- Full data streaming / data lake architecture is needed

**Conclusion:** RabbitMQ delivers all required messaging capabilities with a fraction of the operational complexity. It is the correct choice for this scale.

---

## System Architecture Diagram

```
                        ┌──────────────────────────────────┐
                        │           API Gateway            │
                        │    (Routing, Rate Limiting)      │
                        └──────┬──────────┬──────┬─────────┘
                               │          │      │         │
                    ┌──────────▼──┐  ┌────▼────┐  ┌───────▼──────┐  ┌──────────────┐
                    │ Restaurant  │  │  Order  │  │    Driver    │  │ Notification │
                    │  & Menu Svc │  │   Svc   │  │  Location Svc│  │    Service   │
                    └──────┬──────┘  └────┬────┘  └───────┬──────┘  └──────┬───────┘
                           │              │               │                 │
                    ┌──────▼──────┐  ┌────▼────┐   ┌──────▼──────┐         │
                    │  PostgreSQL │  │ Postgres│   │    Redis    │         │
                    │  (menus,   │  │ (orders,│   │  GEO Store  │         │
                    │restaurants)│  │  items) │   │(live driver │         │
                    └─────────────┘  └────┬────┘   │  positions)│         │
                           │              │         └─────────────┘         │
                    ┌──────▼──────┐       │                │                │
                    │    Redis    │       │                │                │
                    │ (menu cache)│       │                │                │
                    └─────────────┘       │                │                │
                                          │                │                │
                                   ┌──────▼────────────────▼────────────────▼──────┐
                                   │              RabbitMQ                          │
                                   │  [order.placed]   [driver.location.updated]    │
                                   └────────────────────────────────────────────────┘
                                                          │
                                              ┌───────────▼───────────┐
                                              │         Redis         │
                                              │ (WebSocket session    │
                                              │  registry)            │
                                              └───────────────────────┘
```

---

## Service-by-Service Breakdown

### 1. Restaurant & Menu Service

**Responsibility:** Manage and serve restaurant and menu data with sub-200ms response times.

**Tech Stack:**
- Runtime: Node.js (TypeScript)
- Database: PostgreSQL
- Cache: Redis

**Key Design Decisions:**
- Full menu payload (restaurant + categories + items) is serialised to JSON and stored in Redis on first request
- Cache key: `menu:{restaurant_id}`, TTL: 60 seconds
- On cache hit: ~5ms response → comfortably under the 200ms P99 target
- On cache miss: query PostgreSQL, populate Redis, return response (~80–120ms)
- On menu update via admin API: explicitly delete `menu:{restaurant_id}` from Redis (cache invalidation)

**Request Flow:**
```
GET /restaurants/:id/menu
        │
   Check Redis: menu:{id}
        │
   ┌────┴──────────────┐
   │ HIT               │ MISS
   ▼                   ▼
Return JSON         Query PostgreSQL
(~5ms) ✅          → Populate Redis
                   → Return (~100ms) ✅
```

**API Endpoints:**
- `GET /restaurants` — list restaurants
- `GET /restaurants/:id/menu` — fetch full menu (cached)
- `POST /restaurants` — create restaurant (admin)
- `PUT /restaurants/:id/menu-items/:itemId` — update menu item (invalidates cache)

---

### 2. Order Service

**Responsibility:** Accept and validate orders, mock payment processing, publish order events.

**Tech Stack:**
- Runtime: Node.js (TypeScript)
- Database: PostgreSQL
- Cache: Redis (idempotency keys)
- Messaging: RabbitMQ (publisher)

**Key Design Decisions:**
- API returns `202 Accepted` immediately after publishing to RabbitMQ — the order-taking capability is decoupled from downstream processing (payment, notifications, driver assignment)
- Idempotency key (`idempotency:{request_id}`) stored in Redis with 24-hour TTL prevents duplicate orders on network retries
- `price_at_time` is stored on `order_items` at the moment of order creation — menu price changes do not retroactively affect existing orders
- Payment gateway is mocked as a synchronous stub returning `{ success: true, transactionId: uuid }`

**Order Lifecycle:**
```
PENDING → CONFIRMED → PREPARING → PICKED_UP → DELIVERED
                                              (or CANCELLED)
```

**Request Flow:**
```
POST /orders
      │
 Check idempotency key in Redis
      │
 Validate order (restaurant open? items available?)
      │
 Mock payment stub → { success: true }
      │
 Write order to PostgreSQL (ACID transaction)
      │
 Publish to RabbitMQ: order.placed
      │
 Return 202 Accepted + orderId
```

**API Endpoints:**
- `POST /orders` — place an order
- `GET /orders/:id` — get order status
- `PATCH /orders/:id/status` — update order status (kitchen/driver)

---

### 3. Driver Location Service

**Responsibility:** Ingest real-time GPS pings from up to 10,000 concurrent drivers, maintain live positions in Redis GEO.

**Tech Stack:**
- Runtime: Node.js (TypeScript)
- Hot Data Store: Redis GEO
- Driver Profiles: PostgreSQL
- Protocol: WebSocket (inbound from driver app)
- Messaging: RabbitMQ (publisher)

**Key Design Decisions:**
- WebSocket is used (not HTTP polling) to sustain 10,000 persistent connections without per-request handshake overhead
- Each GPS ping writes to Redis GEO (`GEOADD`) in under 1ms — the 2,000 events/sec throughput requirement is comfortably met
- Driver position TTL is set to 30 seconds — if no ping is received, the driver is considered offline and removed from the active GEO set
- Each position update is published to RabbitMQ (`driver.location.updated`) for the Notification Service to consume
- Driver profile data (name, vehicle type, etc.) is stored in PostgreSQL as it is static

**GPS Ingestion Flow:**
```
Driver App (WebSocket)
      │
      ▼
Driver Location Service receives: { driverId, lat, lng, timestamp }
      │
      ├──→ GEOADD drivers:active {lng} {lat} {driverId}   [Redis ~1ms]
      │
      └──→ Publish to RabbitMQ: driver.location.updated   [async]
```

**API Endpoints:**
- `WS /drivers/connect` — WebSocket endpoint for driver GPS stream
- `GET /drivers/:id/location` — current position (reads from Redis GEO)
- `GET /drivers/nearby?lat=&lng=&radius=` — find drivers near a point (GEORADIUS)

---

### 4. Notification Service

**Responsibility:** Consume RabbitMQ events and push real-time updates to customers over WebSocket.

**Tech Stack:**
- Runtime: Node.js (TypeScript)
- Session Store: Redis (WebSocket connection registry)
- Protocol: WebSocket (outbound to customer browser)
- Messaging: RabbitMQ (consumer)

**Key Design Decisions:**
- When the Notification Service is horizontally scaled to multiple instances, each instance holds a subset of customer WebSocket connections. Redis is used as a shared registry to map `order_id → instance_id`, so messages are routed to the correct instance holding the customer's connection
- Consumes two RabbitMQ queues:
  - `driver.location.updated` — pushes live coordinates to the customer tracking that driver's order
  - `order.*` (placed, confirmed, picked up, delivered) — pushes order status updates to the customer
- The service itself has no persistent database — it is stateless except for the Redis session registry

**Message Flow:**
```
RabbitMQ: driver.location.updated
      │
Notification Service consumes message: { driverId, lat, lng }
      │
Lookup Redis: ws:session:{orderId} → which instance owns this customer?
      │
Route to correct instance → Push via WebSocket to customer browser
```

**API Endpoints:**
- `WS /track/:orderId` — customer opens WebSocket to track their order

---

## Database Design

### PostgreSQL Schema

```sql
-- Restaurant & Menu Service
CREATE TABLE restaurants (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    address     TEXT NOT NULL,
    lat         DECIMAL(9,6) NOT NULL,
    lng         DECIMAL(9,6) NOT NULL,
    is_open     BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE menu_categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id   UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    display_order   INT DEFAULT 0
);

CREATE TABLE menu_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id     UUID NOT NULL REFERENCES menu_categories(id) ON DELETE CASCADE,
    restaurant_id   UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           DECIMAL(10,2) NOT NULL,
    is_available    BOOLEAN DEFAULT true
);

-- Driver Service
CREATE TABLE drivers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    phone       VARCHAR(20) NOT NULL UNIQUE,
    vehicle     VARCHAR(100),
    is_active   BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Order Service
CREATE TABLE orders (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id     UUID NOT NULL,
    driver_id         UUID,
    status            VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    total_amount      DECIMAL(10,2) NOT NULL,
    payment_status    VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    payment_txn_id    VARCHAR(255),
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id    UUID NOT NULL,
    name            VARCHAR(255) NOT NULL,   -- snapshot at time of order
    price_at_time   DECIMAL(10,2) NOT NULL,  -- snapshot at time of order
    quantity        INT NOT NULL CHECK (quantity > 0)
);
```

> **Note:** `order_items` stores `name` and `price_at_time` as snapshots. This ensures historical order data remains accurate even if menu prices or item names change later.

---

### Redis Key Design

| Key Pattern | Type | TTL | Used By | Purpose |
|---|---|---|---|---|
| `menu:{restaurantId}` | String (JSON) | 60s | Restaurant & Menu Svc | Cached full menu payload |
| `restaurant:status:{id}` | String | 30s | Restaurant & Menu Svc | Open/closed status cache |
| `idempotency:{requestId}` | String | 24h | Order Service | Prevent duplicate orders |
| `drivers:active` | GEO Set | Per-member 30s | Driver Location Svc | Live driver positions |
| `ws:session:{orderId}` | String | Duration of order | Notification Service | WebSocket instance routing |

---

## Caching Strategy

### Menu Caching (Restaurant & Menu Service)

The P99 <200ms target is achieved through a Redis cache-aside pattern:

```
1. Request arrives for menu
2. Check Redis for key: menu:{restaurantId}
3a. CACHE HIT  → Deserialise JSON, return response          (~5ms)
3b. CACHE MISS → Query PostgreSQL, serialise, write Redis,
                 return response                           (~80–120ms)
4. On menu update → DEL menu:{restaurantId}                (explicit invalidation)
```

Short TTL (60s) ensures menu changes propagate to customers within one minute without requiring complex cache invalidation across all menu update paths.

### Driver Position (Driver Location Service)

Redis GEO is used as the live position store — not a cache, but the primary store for this volatile data:

```
1. GPS ping arrives
2. GEOADD drivers:active {lng} {lat} {driverId}    (overwrites previous position)
3. TTL is refreshed to 30s on each update
4. If no update received in 30s → key expires → driver offline
```

---

## Messaging Strategy

### RabbitMQ Exchange & Queue Design

```
Exchange: order.events (Fanout)
  ├── Queue: orders.notification     → Notification Service
  └── Queue: orders.driver-assign   → Driver Assignment logic (future)

Exchange: driver.events (Direct)
  └── Queue: driver.location.notification → Notification Service
```

### Published Events

| Event | Published By | Consumed By | Payload |
|---|---|---|---|
| `order.placed` | Order Service | Notification Service | `{ orderId, customerId, restaurantId, items }` |
| `order.confirmed` | Order Service | Notification Service | `{ orderId, status }` |
| `order.status.updated` | Order Service | Notification Service | `{ orderId, status }` |
| `driver.location.updated` | Driver Location Service | Notification Service | `{ driverId, orderId, lat, lng, timestamp }` |

---

## Real-Time Driver Tracking Flow

End-to-end flow from GPS ping to customer browser:

```
1. Driver app sends GPS ping over WebSocket
         │
2. Driver Location Service receives { driverId, lat, lng }
         │
3. GEOADD drivers:active {lng} {lat} {driverId}     → Redis (~1ms)
         │
4. Publish to RabbitMQ: driver.location.updated     → async
         │
5. Notification Service consumes message
         │
6. Lookup: which order is driverId currently fulfilling?
         │
7. Lookup Redis: ws:session:{orderId} → which instance?
         │
8. Push { lat, lng } via WebSocket to customer browser
         │
9. Customer map updates in real-time                ✅
```

---

## Infrastructure Summary

### What to Deploy

```
┌────────────────────────────────────────────────────────┐
│                  Docker Compose (local dev)             │
│                                                        │
│  Services:                                             │
│  ├── restaurant-menu-service   (port 3001)             │
│  ├── order-service             (port 3002)             │
│  ├── driver-location-service   (port 3003)             │
│  └── notification-service      (port 3004)             │
│                                                        │
│  Infrastructure:                                       │
│  ├── PostgreSQL 16             (port 5432)             │
│  ├── Redis 7                   (port 6379)             │
│  └── RabbitMQ 3 (+ Management UI) (port 5672 / 15672) │
└────────────────────────────────────────────────────────┘
```

### Database Instance Allocation

```
PostgreSQL (single instance, separate schemas/tables per service):
  ├── restaurants, menu_categories, menu_items  ← Restaurant & Menu Service
  ├── orders, order_items                       ← Order Service
  └── drivers                                   ← Driver Location Service

Redis (single instance):
  ├── menu:{id}              ← Restaurant & Menu Service
  ├── idempotency:{key}      ← Order Service
  ├── drivers:active (GEO)   ← Driver Location Service
  └── ws:session:{orderId}   ← Notification Service
```

---

## Scale Analysis

| Requirement | Target | Design Solution | Headroom |
|---|---|---|---|
| 500 orders/minute | ~8.3/sec | RabbitMQ decouples intake from processing; Postgres write capacity ~10K TPS | 1000x |
| Menu P99 < 200ms | 200ms | Redis cache returns in ~5ms on hit; Postgres query ~100ms on miss | 40x on cache hit |
| 10K concurrent drivers | 10,000 WebSocket connections | Node.js handles 10K+ WebSockets per instance; horizontal scaling via load balancer | 5x per instance |
| 2,000 GPS events/sec | 2,000/sec | Redis handles 100K+ ops/sec; RabbitMQ handles 50K msg/sec | 25x |

**Future scaling triggers:**
- Shard PostgreSQL (read replicas) when read traffic exceeds single-node capacity
- Redis Cluster when GPS fleet grows beyond 100,000 drivers
- Migrate from RabbitMQ to Kafka when event volume exceeds 50,000/sec or event replay is required
- Introduce CDN (Cloudflare/CloudFront) for menu responses to serve from edge nodes globally
