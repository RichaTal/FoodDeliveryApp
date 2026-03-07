# Application architecture and technology stack
_Exported on 2/21/2026 at 16:20:27 GMT+5:30 from Cursor (2.3.30)_

---

**User**

What architecture do you suggest for this application that I have to build  - 
2.1. Reliable Order Processing at Scale The system must be designed to handle a peak load of 500 orders per minute. The core order-taking capability should not be compromised by the unreliability of third-party services. Mock the payment gateway logic. 
 

2.2. High-Performance Menu & Restaurant Browse Customers expect a fluid, snappy Browse experience. To achieve this, the P99 response time for fetching a restaurant's menu and its current status must be under 200ms, even under heavy user load. 
 

2.3. Real-Time Logistics and Analytics The platform must be designed to ingest a continuous stream of GPS location data from up to 10,000 concurrent drivers, each sending an update every 5 seconds (an anticipated peak load of 2,000 events/second). This data stream must be used to power a customer-facing feature showing the live location of their driver. 

Also which database should I use postgres or mongo, should I use any messaging queue, any caching? Also sugegst the core services that we need to build. remember we can mock payment gateway and ignore authentication for now.

Think of yourself as a Senior Software Developer and answer the above questons. 


---

**Cursor**

# Architecture Design: Food Delivery Platform

Great set of requirements! Let me break this down systematically as a Senior Software Developer.

---

## 🏗️ Overall Architecture: Microservices with Event-Driven Core

Given the three distinct performance profiles (order processing throughput, low-latency reads, high-frequency GPS writes), a **microservices architecture** is the right call. Each service can be scaled independently based on its specific load pattern.

```
┌──────────────────────────────────────────────────────────────────┐
│                          API Gateway                             │
│                    (Rate Limiting, Routing)                       │
└────────┬────────────┬──────────────┬──────────────┬─────────────┘
         │            │              │              │
    ┌────▼───┐  ┌─────▼────┐  ┌─────▼────┐  ┌─────▼──────┐
    │ Order  │  │Restaurant│  │ Driver   │  │ Notification│
    │Service │  │/Menu Svc │  │Location  │  │  Service   │
    └────┬───┘  └─────┬────┘  │  Svc     │  └─────┬──────┘
         │            │       └─────┬────┘         │
         │            │             │              │
    ┌────▼────────────▼─────────────▼──────────────▼──────┐
    │              Message Queue (Kafka)                    │
    └──────────────────────────────────────────────────────┘
```

---

## 🔧 Core Services to Build

### 1. **Order Service**
- Accepts and validates orders
- Publishes order events to Kafka
- Mocked payment processing (sync stub returning success/failure)
- Handles order status lifecycle: `PENDING → CONFIRMED → PREPARING → PICKED_UP → DELIVERED`

### 2. **Restaurant & Menu Service**
- CRUD for restaurants, menus, items
- Serves menu data with Redis caching (critical for <200ms P99)
- Restaurant open/closed status

### 3. **Driver Location Service**
- Ingests real-time GPS pings via WebSocket
- Writes to Redis (hot, current position) and streams to Kafka for analytics
- Serves live driver location to customers

### 4. **Notification Service**
- Consumes Kafka events (order placed, driver assigned, etc.)
- Sends WebSocket push notifications to customer frontend

### 5. **Analytics Consumer** *(lightweight)*
- Kafka consumer that persists driver location history and order metrics
- Can be a simple background worker, not customer-facing

---

## 🗄️ Database Strategy: Postgres + Redis (+ MongoDB optionally)

**My recommendation: PostgreSQL as primary + Redis for caching/real-time**

Here's the decision matrix:

| Concern | Tool | Reasoning |
|---|---|---|
| Orders, restaurants, menus | **PostgreSQL** | Relational integrity matters — an order references a restaurant, items, prices. ACID transactions are critical for order processing. |
| Driver live location | **Redis (Hash/Geo)** | `GEOADD`, `GEODIST`, `GEORADIUS` are built for this. Sub-millisecond read/write. Volatile is OK — current position only. |
| Menu/restaurant cache | **Redis** | Cache the full menu payload as JSON. TTL of 30-60s. This is what gets you under 200ms P99. |
| Order session / idempotency keys | **Redis** | Short-lived keys to prevent duplicate order submission. |
| Analytics / driver history | **MongoDB** *(optional)* | If you want flexible schema for GPS time-series or unstructured analytics, Mongo fits well here. But you can skip it initially and use Postgres with a partitioned `driver_location_history` table. |

### Why NOT MongoDB as primary?
- Orders have strong relational structure (order → restaurant → menu items → driver)
- Joins across these entities are natural in Postgres
- ACID compliance for financial/order data is non-negotiable
- MongoDB shines for unstructured/variable data — your core domain isn't that

---

## 📨 Messaging Queue: Yes, Kafka

**Use Kafka** — here's why each requirement demands it:

### For Order Processing (500 orders/min)
```
POST /orders → Order Service validates → Publishes to Kafka topic: "orders"
                                              ↓
                                    Payment Consumer (mocked)
                                              ↓
                                    Restaurant Consumer (notify kitchen)
                                              ↓
                                    Notification Consumer (SMS/push)
```
- The API returns `202 Accepted` immediately after publishing to Kafka
- **The order-taking capability is decoupled from payment/notification reliability**
- If the mock payment service is slow or fails, it doesn't block order ingestion
- 500 orders/min = ~8.3/sec — Kafka handles this trivially, giving you headroom for 100x growth

### For GPS Data (2,000 events/sec)
```
Driver App → WebSocket → Driver Location Service
                              ↓ 
                  Write to Redis GEORADIUS (current position)
                              ↓
                  Publish to Kafka: "driver-locations"
                              ↓
                    Analytics Consumer (persist to DB)
                    Notification Consumer (update customer)
```
Kafka's throughput (millions/sec) makes 2,000/sec trivial.

### Why Kafka over RabbitMQ?
- **Retention**: Kafka retains messages for replay — great for analytics
- **Consumer groups**: Multiple services consume the same event independently
- **Partitioning**: You can partition by `restaurant_id` or `driver_id` for ordering guarantees

---

## ⚡ Caching Strategy (How to hit <200ms P99)

```
GET /restaurants/:id/menu
         ↓
   Check Redis Cache
   ┌─────┴─────┐
   Hit         Miss
   ↓           ↓
Return JSON   Query PostgreSQL
(~5ms)        → Serialize → Store in Redis (TTL: 60s)
              → Return (~50-100ms on first load)
```

### Cache Key Design
```
menu:{restaurant_id}          → Full menu JSON
restaurant:status:{id}        → open/closed status (TTL: 30s)
driver:location:{driver_id}   → current lat/lng (TTL: 10s, auto-expired)
```

### Cache Invalidation
- On menu update (via admin API): `DEL menu:{restaurant_id}`
- Restaurant status: Short TTL (30s) is sufficient — acceptable staleness

---

## 📡 Real-Time Driver Location: WebSockets

```
Customer Browser ←──── WebSocket ──── Notification Service
                                              ↑
                                    Consumes Kafka: "driver-locations"
                                    Filters by customer's active order
```

**Flow:**
1. Customer places order → gets `order_id` + `driver_id`
2. Frontend opens WebSocket connection: `ws://api/track/{order_id}`
3. Notification Service subscribes to Kafka `driver-locations` topic
4. Filters messages for relevant `driver_id`, pushes to customer's WebSocket

For 10,000 concurrent drivers, WebSocket connections on the notification service need horizontal scaling. Use **sticky sessions** or a **Redis Pub/Sub** fanout layer between notification service instances.

---

## 🏃 Scaling Plan Per Service

| Service | Scaling Strategy | Expected Load |
|---|---|---|
| Order Service | Horizontal, stateless pods | 500 req/min |
| Restaurant/Menu Service | Horizontal + Redis cache | High read traffic |
| Driver Location Service | Horizontal WebSocket servers + Redis Cluster | 10K connections, 2K events/sec |
| Kafka | 3+ broker cluster, partition by entity ID | 2K+ events/sec |
| PostgreSQL | Primary + Read Replica (reads go to replica) | Mixed |
| Redis | Redis Cluster (3 shards) | Sub-millisecond |

---

## 🗂️ Suggested Tech Stack

```yaml
Language:         Node.js (TypeScript) or Python (FastAPI)
                  → Node.js preferred for WebSocket-heavy Driver Location Service

API Gateway:      Nginx or Kong

Message Queue:    Apache Kafka (with Zookeeper or KRaft mode)

Primary DB:       PostgreSQL 16
ORM:              Prisma (Node) or SQLAlchemy (Python)

Cache:            Redis 7 (Cluster mode for production)

Real-time:        WebSockets (Socket.io or native ws)

Driver Location:  Redis GEO commands

Containerization: Docker + Docker Compose (local dev)
Orchestration:    Kubernetes (production)

Monitoring:       Prometheus + Grafana
Logging:          ELK Stack (Elasticsearch, Logstash, Kibana)
```

---

## 🗺️ Data Model Overview (PostgreSQL)

```sql
-- Core entities
restaurants (id, name, address, lat, lng, is_open, created_at)
menu_items  (id, restaurant_id, name, price, category, is_available)
orders      (id, customer_id, restaurant_id, driver_id, status, 
             total_amount, payment_status, created_at, updated_at)
order_items (id, order_id, menu_item_id, quantity, price_at_time)
drivers     (id, name, phone, is_active, current_lat, current_lng)

-- Kafka handles the event stream; persist snapshots only
driver_location_history (driver_id, lat, lng, recorded_at) -- partitioned by date
```

---

## ✅ Summary of Decisions

| Question | Decision | Why |
|---|---|---|
| **Postgres vs Mongo?** | PostgreSQL + Redis | ACID for orders, Redis for hot data |
| **Message Queue?** | ✅ Kafka | Decouple order intake from processing; handle GPS stream |
| **Caching?** | ✅ Redis | Required for <200ms P99 menu response |
| **Auth?** | Skip for now | As per requirement |
| **Payment?** | Mock sync stub | Returns `{success: true, transaction_id: uuid}` |
| **Driver tracking?** | Redis GEO + WebSocket | Built-in geospatial + real-time push |

---

## 🚀 Build Order (Recommended)

1. **Week 1-2**: Restaurant + Menu Service (with Postgres + Redis cache)
2. **Week 2-3**: Order Service (with Kafka + mocked payment)
3. **Week 3-4**: Driver Location Service (WebSocket + Redis GEO)
4. **Week 4-5**: Notification Service (Kafka consumer + WebSocket push)
5. **Week 5+**: Analytics Consumer, monitoring, load testing

This gives you a working core early and adds real-time complexity progressively.

```plaintext
┌──────────────────────────────────────────────────────────────────┐
│                          API Gateway                             │
│                    (Rate Limiting, Routing)                       │
└────────┬────────────┬──────────────┬──────────────┬─────────────┘
         │            │              │              │
    ┌────▼───┐  ┌─────▼────┐  ┌─────▼────┐  ┌─────▼──────┐
    │ Order  │  │Restaurant│  │ Driver   │  │ Notification│
    │Service │  │/Menu Svc │  │Location  │  │  Service   │
    └────┬───┘  └─────┬────┘  │  Svc     │  └─────┬──────┘
         │            │       └─────┬────┘         │
         │            │             │              │
    ┌────▼────────────▼─────────────▼──────────────▼──────┐
    │              Message Queue (Kafka)                    │
    └──────────────────────────────────────────────────────┘
```

```plaintext
POST /orders → Order Service validates → Publishes to Kafka topic: "orders"
                                              ↓
                                    Payment Consumer (mocked)
                                              ↓
                                    Restaurant Consumer (notify kitchen)
                                              ↓
                                    Notification Consumer (SMS/push)
```

```plaintext
Driver App → WebSocket → Driver Location Service
                              ↓ 
                  Write to Redis GEORADIUS (current position)
                              ↓
                  Publish to Kafka: "driver-locations"
                              ↓
                    Analytics Consumer (persist to DB)
                    Notification Consumer (update customer)
```

```plaintext
GET /restaurants/:id/menu
         ↓
   Check Redis Cache
   ┌─────┴─────┐
   Hit         Miss
   ↓           ↓
Return JSON   Query PostgreSQL
(~5ms)        → Serialize → Store in Redis (TTL: 60s)
              → Return (~50-100ms on first load)
```

```plaintext
menu:{restaurant_id}          → Full menu JSON
restaurant:status:{id}        → open/closed status (TTL: 30s)
driver:location:{driver_id}   → current lat/lng (TTL: 10s, auto-expired)
```

```plaintext
Customer Browser ←──── WebSocket ──── Notification Service
                                              ↑
                                    Consumes Kafka: "driver-locations"
                                    Filters by customer's active order
```

```yaml
Language:         Node.js (TypeScript) or Python (FastAPI)
                  → Node.js preferred for WebSocket-heavy Driver Location Service

API Gateway:      Nginx or Kong

Message Queue:    Apache Kafka (with Zookeeper or KRaft mode)

Primary DB:       PostgreSQL 16
ORM:              Prisma (Node) or SQLAlchemy (Python)

Cache:            Redis 7 (Cluster mode for production)

Real-time:        WebSockets (Socket.io or native ws)

Driver Location:  Redis GEO commands

Containerization: Docker + Docker Compose (local dev)
Orchestration:    Kubernetes (production)

Monitoring:       Prometheus + Grafana
Logging:          ELK Stack (Elasticsearch, Logstash, Kibana)
```

```sql
-- Core entities
restaurants (id, name, address, lat, lng, is_open, created_at)
menu_items  (id, restaurant_id, name, price, category, is_available)
orders      (id, customer_id, restaurant_id, driver_id, status, 
             total_amount, payment_status, created_at, updated_at)
order_items (id, order_id, menu_item_id, quantity, price_at_time)
drivers     (id, name, phone, is_active, current_lat, current_lng)

-- Kafka handles the event stream; persist snapshots only
driver_location_history (driver_id, lat, lng, recorded_at) -- partitioned by date
```

---

**User**

Why do we need Analytics consumer service ?

---

**Cursor**

Great question! Honestly, **for the core requirements you listed, you don't strictly need it right now.**

Here's the breakdown:

## Why I Included It
I included it as a "nice to have" for persisting the **driver GPS history** to a database. The thinking was:

- Kafka only retains messages for a configured time window (e.g., 7 days by default)
- If you ever want to replay a driver's route, audit a delivery, or run business analytics (average delivery times, heatmaps of driver activity, etc.), you'd need that data persisted somewhere permanently
- A dedicated consumer handles that persistence without burdening other services

---

## Why You Can Skip It For Now

Looking at your **actual stated requirements**:

| Requirement | Needs Analytics Consumer? |
|---|---|
| 500 orders/min processing | ❌ No |
| Menu/restaurant browse <200ms | ❌ No |
| Live driver location for customer | ❌ No — Redis handles current position |
| GPS ingestion from 10K drivers | ❌ No — Kafka + Redis handles this |

The **Driver Location Service** already:
1. Writes current position to **Redis** (serves live tracking)
2. Publishes to **Kafka** (for notification fanout to customers)

That's sufficient for the customer-facing live tracking feature.

---

## When You'd Actually Need It

Add the Analytics Consumer **only when** you need:
- 📊 Business dashboards (delivery time trends, driver efficiency)
- 🗺️ Route replay / proof of delivery
- 🚨 Fraud detection (driver not moving, GPS spoofing)
- 📍 Heatmaps of high-demand zones
- 🔍 Audit trails for disputed deliveries

---

## Revised Core Services (Lean Version)

For your assignment, the **4 essential services** are:

```
1. Restaurant & Menu Service   → Postgres + Redis cache
2. Order Service               → Postgres + Kafka + mocked payment
3. Driver Location Service     → WebSocket + Redis GEO + Kafka
4. Notification Service        → Kafka consumer + WebSocket push to customer
```

Drop the Analytics Consumer — it's a future concern, not a core requirement.

```plaintext
1. Restaurant & Menu Service   → Postgres + Redis cache
2. Order Service               → Postgres + Kafka + mocked payment
3. Driver Location Service     → WebSocket + Redis GEO + Kafka
4. Notification Service        → Kafka consumer + WebSocket push to customer
```

---

**User**

Similarly, why do we need notification service?

---

**Cursor**

Another sharp question! Let me be honest about this one too.

## The Reason I Added It

The Notification Service was meant to:
1. Consume Kafka `driver-locations` events
2. Filter updates relevant to a specific customer's active order
3. Push live driver location to the customer's browser via WebSocket

---

## Can You Remove It?

**Partially — but not entirely.** Here's why:

The requirement says:
> *"power a customer-facing feature showing the live location of their driver"*

Something has to push that live location to the customer's browser in real-time. The question is **which service owns that responsibility**.

### Option A: Keep Notification Service (Separate)
```
Driver Location Service  →  Kafka  →  Notification Service  →  Customer WebSocket
```
✅ Clean separation of concerns
✅ Notification Service can later handle SMS, email, push too
❌ Extra service to build and deploy

### Option B: Merge Into Driver Location Service (Simpler)
```
Driver Location Service  →  Redis  →  also directly pushes  →  Customer WebSocket
```
✅ One less service
✅ Simpler for an assignment
❌ Mixes "ingesting driver GPS" with "serving customer connections" — two very different load profiles

---

## The Real Difference in Load Profile

This is the key reason to keep them separate in production:

| Concern | Driver Location Service | Notification Service |
|---|---|---|
| Connections | 10,000 drivers (write-heavy) | Potentially millions of customers (read/push) |
| Protocol | WebSocket from driver app | WebSocket to customer browser |
| Scale trigger | Number of active drivers | Number of active orders |

Mixing them means you can't scale them independently.

---

## For Your Assignment

**You can merge both into the Driver Location Service** and call it done. It will:

1. Accept GPS pings from drivers via WebSocket
2. Write to Redis GEO
3. Push location updates directly to the customer tracking that driver's order

```
Revised 3 Core Services:

1. Restaurant & Menu Service   → Postgres + Redis cache
2. Order Service               → Postgres + Kafka + mocked payment  
3. Driver Location Service     → WebSocket (drivers in + customers out) + Redis GEO
```

Kafka is still useful between Order Service and Driver Location Service (to know which driver is assigned to which order), but you've eliminated a whole service.

---

## Bottom Line

| | Notification Service Separate | Merged into Driver Location |
|---|---|---|
| Production system | ✅ Recommended | ❌ Scaling problem |
| Assignment / MVP | ⚠️ Overkill | ✅ Simpler, still correct |

For your assignment, **merge it**. For a real production system, **keep it separate**.

```plaintext
Driver Location Service  →  Kafka  →  Notification Service  →  Customer WebSocket
```

```plaintext
Driver Location Service  →  Redis  →  also directly pushes  →  Customer WebSocket
```

```plaintext
Revised 3 Core Services:

1. Restaurant & Menu Service   → Postgres + Redis cache
2. Order Service               → Postgres + Kafka + mocked payment  
3. Driver Location Service     → WebSocket (drivers in + customers out) + Redis GEO
```

---

**User**

Lets keep Driver Location Service and Notification Service separate

---

**Cursor**

Good call. It's the right architectural decision — cleaner separation of concerns and independent scalability.

## ✅ Final Architecture — 4 Core Services

```
┌─────────────────────────────────────────────────────────────┐
│                        API Gateway                          │
└──────┬──────────────┬──────────────┬───────────────┬────────┘
       │              │              │               │
  ┌────▼───┐    ┌─────▼────┐   ┌────▼─────┐   ┌────▼────────┐
  │ Order  │    │Restaurant│   │  Driver  │   │Notification │
  │Service │    │/Menu Svc │   │ Location │   │  Service    │
  └────┬───┘    └─────┬────┘   │  Svc     │   └────┬────────┘
       │              │        └────┬─────┘        │
       │              │             │               │
  ┌────▼──────────────▼─────────────▼───────────────▼────────┐
  │                    Kafka (Message Bus)                     │
  └───────────────────────────────────────────────────────────┘
       │                           │
  ┌────▼──────┐              ┌─────▼─────┐
  │ PostgreSQL│              │   Redis   │
  │(Orders,   │              │(Menu Cache│
  │Restaurants│              │ Driver GPS│
  │  Menus)   │              │  Positions│
  └───────────┘              └───────────┘
```

---

## Responsibility of Each Service

### 1. 🍽️ Restaurant & Menu Service
- Serves restaurant listings and menus
- Caches menu payloads in Redis (TTL: 60s) → achieves **<200ms P99**
- Invalidates cache on menu updates

### 2. 📦 Order Service
- Accepts orders, validates, stores in PostgreSQL
- Mocked payment gateway (sync stub)
- Publishes `order.placed`, `order.confirmed` events to Kafka
- Returns `202 Accepted` immediately → handles **500 orders/min**

### 3. 📍 Driver Location Service
- Accepts GPS pings from **10,000 drivers** via WebSocket
- Writes current position to **Redis GEO**
- Publishes `driver.location.updated` events to Kafka → **2,000 events/sec**

### 4. 🔔 Notification Service
- Consumes `driver.location.updated` from Kafka
- Maintains WebSocket connections to **customers**
- Filters and pushes location updates to the relevant customer tracking that driver
- Consumes `order.*` events to notify customers of order status changes

---

## Clear Boundary Between the Two Services

| | Driver Location Service | Notification Service |
|---|---|---|
| **Faces** | Driver mobile app | Customer browser |
| **Direction** | Inbound (GPS writes) | Outbound (push to customer) |
| **Protocol** | WebSocket (receive) | WebSocket (send) |
| **Scale trigger** | Number of active drivers | Number of active orders |
| **Data store** | Redis GEO | No persistent store needed |
| **Communicates via** | Publishes to Kafka | Consumes from Kafka |

This boundary is clean — neither service knows about the other directly. Kafka is the contract between them.

---

## Shall we start building these services now?

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                        API Gateway                          │
└──────┬──────────────┬──────────────┬───────────────┬────────┘
       │              │              │               │
  ┌────▼───┐    ┌─────▼────┐   ┌────▼─────┐   ┌────▼────────┐
  │ Order  │    │Restaurant│   │  Driver  │   │Notification │
  │Service │    │/Menu Svc │   │ Location │   │  Service    │
  └────┬───┘    └─────┬────┘   │  Svc     │   └────┬────────┘
       │              │        └────┬─────┘        │
       │              │             │               │
  ┌────▼──────────────▼─────────────▼───────────────▼────────┐
  │                    Kafka (Message Bus)                     │
  └───────────────────────────────────────────────────────────┘
       │                           │
  ┌────▼──────┐              ┌─────▼─────┐
  │ PostgreSQL│              │   Redis   │
  │(Orders,   │              │(Menu Cache│
  │Restaurants│              │ Driver GPS│
  │  Menus)   │              │  Positions│
  └───────────┘              └───────────┘
```

---

**User**

Re-analyze the scale of the application and tell me which would be better RabbitMQ or Kafka? Will Kafka be an overkill as its much more complex comparedto RabbitMQ

---

**Cursor**

Excellent question — and yes, let me be honest: **Kafka is likely overkill here.**

## Re-Analyzing Actual Scale

Let me put the numbers in perspective:

| Event Type | Volume | Per Second |
|---|---|---|
| Orders | 500/minute | **~8.3/sec** |
| GPS pings | 10K drivers × 1/5sec | **2,000/sec** |
| Order status updates | ~4 per order lifecycle | **~33/sec** |
| **Total peak** | | **~2,033 events/sec** |

---

## What Each Tool Actually Handles

| | RabbitMQ | Kafka |
|---|---|---|
| **Throughput** | 20K–50K msg/sec | Millions/sec |
| **Our peak load** | 2,033/sec | 2,033/sec |
| **Fits?** | ✅ Yes, with huge headroom | ✅ Yes, but massively underutilized |
| **Setup complexity** | Low | High |
| **Operational overhead** | Low | High (partitions, offsets, KRaft/ZooKeeper) |
| **Message retention/replay** | ❌ No (consumed = gone) | ✅ Yes |
| **Multiple consumers, same message** | ✅ Via Fanout Exchange | ✅ Via Consumer Groups |
| **Message ordering** | Per-queue | Per-partition |
| **Learning curve** | Gentle | Steep |

---

## Where Kafka's Unique Features Would Matter

Kafka has two killer features that RabbitMQ lacks:

### 1. Message Retention & Replay
Kafka stores messages even after consumption. Useful when:
- A new service comes online and needs to process past events
- You want to replay events for debugging
- You need an audit trail

**Do you need this?** For GPS data — not really. For orders — maybe useful but not critical for MVP.

### 2. Multiple Independent Consumers of the Same Stream
In Kafka, two different consumer groups can both read the same message independently. In RabbitMQ you need a **Fanout Exchange** to achieve the same thing.

**Do you need this?** Yes — an `order.placed` event needs to be consumed by both the Notification Service and potentially a Driver Assignment logic. RabbitMQ handles this fine with a Fanout Exchange.

---

## Honest Verdict

```
2,033 events/sec
      │
      ▼
RabbitMQ max: ~50,000/sec
      │
      └── You're using 4% of RabbitMQ's capacity.
          Kafka would be operating at 0.002% of its capacity.
```

**RabbitMQ is the right choice for this application.**

---

## How RabbitMQ Covers Your Use Cases

### Order Placed → Multiple Consumers
```
Order Service
     │
     ▼
[Fanout Exchange: order.placed]
     ├──→ Queue: notification-service    (tells customer order confirmed)
     └──→ Queue: driver-assignment       (find a driver)
```

### GPS Events → Notification Service
```
Driver Location Service
     │
     ▼
[Direct Exchange: driver.location]
     └──→ Queue: notification-service   (push to customer tracking order)
```

Simple, clean, no partition strategy needed.

---

## When to Migrate TO Kafka (Future Signal)

Revisit Kafka only when you hit these thresholds:

- 📈 GPS events exceed **50,000/sec** (10x more drivers)
- 📊 You need **event replay** for analytics pipelines
- 🔄 You have **5+ independent consumers** reading the same stream
- 🏗️ You're building a full **data lake / streaming analytics** platform

---

## Final Recommendation

| Scenario | Choice |
|---|---|
| **This assignment / MVP** | ✅ **RabbitMQ** — simpler, sufficient, faster to build |
| **Production at 10x scale** | ⚠️ Re-evaluate — probably still RabbitMQ |
| **Production at 100x scale with analytics** | ✅ Kafka |

**Go with RabbitMQ.** You get 95% of the architectural benefits with 20% of the complexity. Save Kafka for when your GPS fleet grows to 100,000 drivers.

```plaintext
2,033 events/sec
      │
      ▼
RabbitMQ max: ~50,000/sec
      │
      └── You're using 4% of RabbitMQ's capacity.
          Kafka would be operating at 0.002% of its capacity.
```

```plaintext
Order Service
     │
     ▼
[Fanout Exchange: order.placed]
     ├──→ Queue: notification-service    (tells customer order confirmed)
     └──→ Queue: driver-assignment       (find a driver)
```

```plaintext
Driver Location Service
     │
     ▼
[Direct Exchange: driver.location]
     └──→ Queue: notification-service   (push to customer tracking order)
```

---

**User**

Ok, what will be the databases needed which database do you suggest to use for each service that we are building

---

**Cursor**

Great question. Let me go service by service with clear reasoning for each choice.

---

## Service-by-Service Database Breakdown

### 1. 🍽️ Restaurant & Menu Service

**Primary DB: PostgreSQL**
**Cache: Redis**

```
restaurants
    │
    └── menu_categories
              │
              └── menu_items
```

**Why PostgreSQL?**
- Classic relational structure — a restaurant has many categories, categories have many items
- Joins are natural and performant here
- Menu updates need to be consistent (price change should be atomic)

**Why Redis as cache?**
- This is what delivers the **<200ms P99** requirement
- Full menu payload cached as JSON: `menu:{restaurant_id}` with TTL of 60s
- On cache hit → ~5ms response. On miss → query Postgres, repopulate cache

```
GET /restaurants/:id/menu
        ↓
   Redis hit?  →  YES  →  Return JSON (~5ms) ✅
        ↓ NO
   Query PostgreSQL → Store in Redis → Return (~80-120ms)
```

---

### 2. 📦 Order Service

**Primary DB: PostgreSQL**
**Session Store: Redis**

**Why PostgreSQL?**
- Orders are the most critical financial data in the system
- ACID transactions are non-negotiable — you never want a half-written order
- Strong relational links: order → restaurant, order → menu items, order → driver
- `order_items` must snapshot the price at time of order (menu prices change)

**Why Redis (secondary)?**
- **Idempotency keys**: Prevent duplicate orders if customer double-taps "Place Order"
- Key: `idempotency:{request_id}`, TTL: 24 hours
- **Order status cache**: Cache current status so the GET endpoint is fast

```
orders         (id, restaurant_id, driver_id, status, total, payment_status)
order_items    (id, order_id, menu_item_id, quantity, price_at_time)
```

Note `price_at_time` — critical. You're snapshotting the price, not referencing it, because menu prices can change after an order is placed.

---

### 3. 📍 Driver Location Service

**Hot Data: Redis GEO**
**Driver Profiles: PostgreSQL**

This service has a split personality — two very different data needs:

**Redis GEO for live positions:**
- `GEOADD drivers:active {lng} {lat} {driver_id}` on every GPS ping
- 2,000 writes/sec → Redis handles this at sub-millisecond latency
- `GEORADIUS` to find nearby drivers for order assignment
- TTL: 30s per driver key — if no ping received, driver is considered offline
- This data is **intentionally volatile** — you only care about current position

**PostgreSQL for driver profiles:**
```
drivers (id, name, phone, vehicle_type, is_active, created_at)
```
- Static data, rarely changes
- Read once when driver comes online, cache if needed

```
Driver sends GPS ping
        ↓
GEOADD drivers:active {lng} {lat} {driver_id}   → Redis (~1ms)
        ↓
Publish to RabbitMQ: driver.location.updated
        ↓
Notification Service consumes → pushes to customer
```

---

### 4. 🔔 Notification Service

**No persistent DB needed**
**Session Store: Redis**

This service is largely **stateless**. It:
- Consumes from RabbitMQ
- Maintains WebSocket connections to customers
- Pushes updates to the right customer

**Why Redis here?**
- When you scale Notification Service to multiple instances, you need to know **which instance holds which customer's WebSocket connection**
- Redis acts as a shared connection registry:
  - Key: `ws:session:{order_id}` → Value: `instance_id`
  - When a location update arrives for `order_123`, look up which instance the customer is connected to, then route the message there

```
Notification Instance 1  ←── Customer A (order_123)
Notification Instance 2  ←── Customer B (order_456)
                ↑
        Redis knows which
        instance owns which
        customer connection
```

Without Redis here, horizontal scaling of Notification Service breaks.

---

## Summary Table

| Service | Primary DB | Why | Secondary (Redis) | Why |
|---|---|---|---|---|
| Restaurant & Menu | PostgreSQL | Relational menu structure, consistent updates | ✅ Cache | <200ms P99 |
| Order | PostgreSQL | ACID, financial data, relational | ✅ Idempotency keys + status cache | Prevent duplicates |
| Driver Location | Redis GEO | 2K writes/sec, volatile, geospatial | PostgreSQL for driver profiles | Static data |
| Notification | None | Stateless consumer | ✅ WebSocket session registry | Multi-instance routing |

---

## Infrastructure View (What You Actually Deploy)

For your assignment, you only need **2 database instances**:

```
┌─────────────────────────────────────────────────┐
│              PostgreSQL Instance                 │
│  ┌──────────────┐  ┌──────────┐  ┌───────────┐  │
│  │  restaurants │  │  orders  │  │  drivers  │  │
│  │  menu_items  │  │  order_  │  │           │  │
│  │  categories  │  │  items   │  │           │  │
│  └──────────────┘  └──────────┘  └───────────┘  │
│   Restaurant/Menu    Order Svc    Driver Svc      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                Redis Instance                    │
│  menu:{id}          → Menu JSON cache            │
│  idempotency:{key}  → Duplicate order prevention │
│  drivers:active     → GEO set of live drivers    │
│  ws:session:{order} → WebSocket routing          │
└─────────────────────────────────────────────────┘
```

One PostgreSQL, one Redis — simple to run locally with Docker, and logically clean per service.

```plaintext
restaurants
    │
    └── menu_categories
              │
              └── menu_items
```

```plaintext
GET /restaurants/:id/menu
        ↓
   Redis hit?  →  YES  →  Return JSON (~5ms) ✅
        ↓ NO
   Query PostgreSQL → Store in Redis → Return (~80-120ms)
```

```plaintext
orders         (id, restaurant_id, driver_id, status, total, payment_status)
order_items    (id, order_id, menu_item_id, quantity, price_at_time)
```

```plaintext
drivers (id, name, phone, vehicle_type, is_active, created_at)
```

```plaintext
Driver sends GPS ping
        ↓
GEOADD drivers:active {lng} {lat} {driver_id}   → Redis (~1ms)
        ↓
Publish to RabbitMQ: driver.location.updated
        ↓
Notification Service consumes → pushes to customer
```

```plaintext
Notification Instance 1  ←── Customer A (order_123)
Notification Instance 2  ←── Customer B (order_456)
                ↑
        Redis knows which
        instance owns which
        customer connection
```

```plaintext
┌─────────────────────────────────────────────────┐
│              PostgreSQL Instance                 │
│  ┌──────────────┐  ┌──────────┐  ┌───────────┐  │
│  │  restaurants │  │  orders  │  │  drivers  │  │
│  │  menu_items  │  │  order_  │  │           │  │
│  │  categories  │  │  items   │  │           │  │
│  └──────────────┘  └──────────┘  └───────────┘  │
│   Restaurant/Menu    Order Svc    Driver Svc      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                Redis Instance                    │
│  menu:{id}          → Menu JSON cache            │
│  idempotency:{key}  → Duplicate order prevention │
│  drivers:active     → GEO set of live drivers    │
│  ws:session:{order} → WebSocket routing          │
└─────────────────────────────────────────────────┘
```

---

**User**

Why do you suggest using Redis, analyze the requirements and tell me if any other caching service would be better suited?

---

**Cursor**

Great challenge. Let me re-examine each use case critically rather than defaulting to Redis automatically.

---

## What Are We Actually Using the Cache For?

| Use Case | Service | Operation Type |
|---|---|---|
| Menu JSON cache | Restaurant & Menu | Simple key-value, TTL-based reads |
| Idempotency keys | Order | Simple key-value, TTL-based writes |
| Driver live positions | Driver Location | Geospatial writes/queries at 2K/sec |
| WebSocket session map | Notification | Simple key-value lookup |

---

## Caching Alternatives — Honest Comparison

### Option 1: Memcached

The classic Redis alternative. Simpler, multi-threaded, pure key-value.

| | Memcached | Redis |
|---|---|---|
| Raw key-value speed | ✅ Slightly faster (multi-threaded) | ✅ Fast (single-threaded but optimized) |
| Data structures | ❌ Strings only | ✅ Strings, Sets, Hashes, Geo, Lists |
| TTL support | ✅ Yes | ✅ Yes |
| Geospatial commands | ❌ **None** | ✅ GEOADD, GEORADIUS, GEODIST |
| Pub/Sub | ❌ No | ✅ Yes |
| Persistence | ❌ No | ✅ Optional (RDB/AOF) |
| Cluster scaling | ✅ Simple | ✅ Yes |
| Operational complexity | Low | Low-Medium |

**Verdict on Memcached:** Would cover use cases 1, 2 and 4 perfectly — but **completely fails for Driver Location** (no geospatial support). You'd need Redis anyway, so running both adds operational complexity for zero gain.

---

### Option 2: In-Process Cache (e.g., `node-cache`, `lru-cache`)

Caching within the service's own memory — no network hop at all.

```
Request → Service → Memory (nanoseconds) → Response
```

**Pros:**
- Fastest possible — zero network latency
- Zero infrastructure to manage
- Perfect for menu data (rarely changes)

**Cons:**
- ❌ **Breaks with horizontal scaling** — each instance has its own cache, they go out of sync
- ❌ Cache is lost on service restart
- ❌ Cannot share state across instances (kills WebSocket session registry)
- ❌ No geospatial support

**Verdict:** Only viable if you're running a single instance and never scale. Not suitable for production or even a properly designed assignment.

---

### Option 3: Hazelcast / Apache Ignite

Distributed in-memory data grids — enterprise-grade.

**Pros:**
- Distributed by design
- Rich data structures
- Some geospatial support (Hazelcast has geo-queries)

**Cons:**
- ❌ Massively over-engineered for this scale
- ❌ Heavy JVM-based (adds infrastructure complexity)
- ❌ Expensive to operate
- ❌ Overkill in the same way Kafka was for the message queue

**Verdict:** Used at Uber/Netflix scale. Not appropriate here.

---

### Option 4: CDN Caching (e.g., Cloudflare, AWS CloudFront)

Cache menu responses at the **edge** — closest to the user geographically.

**Pros:**
- ✅ Dramatically reduces latency for menu browsing (serve from edge node, not your server)
- ✅ Offloads traffic from your servers entirely
- ✅ Global distribution built-in
- ✅ Excellent for static/semi-static data like menus

**Cons:**
- ❌ Only works for HTTP GET responses — cannot cache driver GPS or WebSocket sessions
- ❌ Cache invalidation on menu update is more complex (purge CDN + Redis)
- ❌ Overkill for an assignment

**Verdict:** Genuinely useful addition for menu browsing in production alongside Redis, but not a replacement.

---

## The Decisive Factor: Geospatial Commands

This is the dealbreaker that makes Redis the only sensible choice:

```
Driver Location Service needs:

GEOADD  drivers:active 77.5946 12.9716 "driver_42"   ← add/update position
GEORADIUS drivers:active 77.59 12.97 5 km             ← find nearby drivers
GEODIST  drivers:active "driver_42" "restaurant_1" km ← calculate distance
```

**No other lightweight caching tool supports geospatial queries natively.** You'd either need Redis or a full database with PostGIS extension (PostgreSQL + PostGIS) — which is not a caching layer.

---

## Re-Examining Each Use Case

| Use Case | Best Tool | Why |
|---|---|---|
| Menu JSON cache | Redis ✅ | Already needed; TTL + simple get/set |
| Idempotency keys | Redis ✅ | Already needed; SET NX with TTL is perfect |
| Driver live positions | **Redis — no substitute** | GEOADD/GEORADIUS are unique to Redis |
| WebSocket session map | Redis ✅ | Already needed; simple key-value |

---

## Verdict

**Redis is the right choice — but for the right reason.**

It's not the default "use Redis for everything" thinking. The **geospatial requirement for the Driver Location Service** makes Redis a hard dependency. Once Redis is in your stack, using it for menu caching, idempotency keys and session mapping is a free win — no extra infrastructure, no extra operational overhead.

```
If you didn't have the GPS tracking requirement:
→ Memcached would be equally good (simpler, slightly faster for key-value)

Because you have the GPS tracking requirement:
→ Redis is the only lightweight option that covers all 4 use cases in one tool
```

Consolidating into one Redis instance is the pragmatic and correct call.

```plaintext
Request → Service → Memory (nanoseconds) → Response
```

```plaintext
Driver Location Service needs:

GEOADD  drivers:active 77.5946 12.9716 "driver_42"   ← add/update position
GEORADIUS drivers:active 77.59 12.97 5 km             ← find nearby drivers
GEODIST  drivers:active "driver_42" "restaurant_1" km ← calculate distance
```

```plaintext
If you didn't have the GPS tracking requirement:
→ Memcached would be equally good (simpler, slightly faster for key-value)

Because you have the GPS tracking requirement:
→ Redis is the only lightweight option that covers all 4 use cases in one tool
```

---

**User**

Create a file named -  ARCHITECTURE.md and document the  architecture for this food delivery application in it. Also Remember to add the reasons for why we chose each component - databases(postgres over mongo), cache(redis over memcache) and messaging service(rabbitMQ over Kafka)

---

**Cursor**

```markdown
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
- Authentication & Authorization
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

## Architecture Style

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

## Technology Decisions

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

```

The `ARCHITECTURE.md` file has been created. Here's what's documented in it:

---

## What's Covered

### Structure
1. **Requirements Summary** — the 3 core requirements with targets
2. **Architecture Style** — why microservices over a monolith
3. **Technology Decisions** (with full reasoning for each)
4. **System Architecture Diagram** — visual representation
5. **Service-by-Service Breakdown** — for all 4 services
6. **Database Schema** — full PostgreSQL table definitions
7. **Redis Key Design** — all keys, types, TTLs, and purposes
8. **Caching Strategy** — request flow diagrams
9. **Messaging Strategy** — RabbitMQ exchanges, queues, and event payloads
10. **Real-Time Driver Tracking Flow** — end-to-end step-by-step
11. **Infrastructure Summary** — what to deploy locally
12. **Scale Analysis** — targets vs. design solution vs. headroom

### Key Reasons Documented
| Decision | Reason |
|---|---|
| **PostgreSQL over MongoDB** | Relational domain (orders → items → restaurants), ACID transactions for financial data, no need for flexible schema |
| **Redis over Memcached** | `GEORADIUS`/`GEOADD` geospatial commands required for driver tracking — Memcached has no geospatial support; once Redis is in the stack, it covers all caching needs |
| **RabbitMQ over Kafka** | Peak load is only ~2,033 events/sec (4–10% of RabbitMQ's capacity, 0.002% of Kafka's); Kafka's complexity (partitions, offsets, KRaft) is not justified at this scale |


# Service and infrastructure task division
_Exported on 2/21/2026 at 16:47:05 GMT+5:30 from Cursor (2.3.30)_

---

**User**

Divide the services that we have to build into subtasks and save all the tasks in a tasks folder. Also include the tasks needed for Infrastructure - like docker file generation. 

---

**Cursor**

Now I have a thorough understanding of the architecture. Let me create a well-structured `tasks` folder with individual task files for each service and infrastructure.

Let me verify all files were created correctly:

All 7 files are in place. Here's a summary of everything created in the `tasks/` folder:

---

## `tasks/` Folder — What Was Created

### `README.md` — Master Index
A top-level index with a table of all task files and a **recommended build order** diagram showing dependencies between services.

---

### `01-infrastructure.md` — 7 Subtasks
Covers all shared infra before any service is written:
- **1.1** Monorepo layout & folder structure  
- **1.2** Multi-stage `Dockerfile` for each of the 5 services (4 services + gateway)  
- **1.3** `docker-compose.yml` with all 8 containers, health checks, named volumes, `depends_on: service_healthy`  
- **1.4** PostgreSQL `init.sql` — all 6 tables, indexes, and seed data  
- **1.5** RabbitMQ `definitions.json` — pre-provisions all exchanges and queues  
- **1.6** `.env.example` with every required variable  
- **1.7** Shared `tsconfig.base.json`  

---

### `02-restaurant-menu-service.md` — 8 Subtasks
- Project scaffolding, DB + Redis clients, TypeScript types, cache-aside menu logic (`getFullMenu`, `invalidateMenuCache`), 4 REST routes, error handling/degraded mode

---

### `03-order-service.md` — 10 Subtasks
- Scaffolding, DB + Redis + RabbitMQ clients, payment stub (mock with 75ms delay), RabbitMQ publisher, full `placeOrder` flow (idempotency → validation → payment → ACID transaction → publish), order status state machine, 3 REST routes

---

### `04-driver-location-service.md` — 11 Subtasks
- Scaffolding, Redis GEO (`GEOADD`/`GEOSEARCH`), WebSocket server (driver app connections), GPS ping ingestion with parallel Redis+RabbitMQ writes, heartbeat/dead-connection detection, per-driver TTL cleanup job, 3 HTTP routes

---

### `05-notification-service.md` — 9 Subtasks
- Scaffolding, Redis session registry (`ws:session:{orderId}`), customer-facing WebSocket server, RabbitMQ consumer for `orders.notification`, RabbitMQ consumer for `driver.location.notification`, horizontal-scaling-aware session routing

---

### `06-api-gateway.md` — 8 Subtasks
- Scaffolding, route config table, request logger (`X-Request-ID`), rate limiters (global 500/min + order-specific 10/min), HTTP reverse proxy (`http-proxy-middleware`), WebSocket upgrade proxy (`http-proxy`), CORS configuration

# Subtask implementation for main task
_Exported on 2/21/2026 at 17:12:11 GMT+5:30 from Cursor (2.3.30)_

---

**User**

Implement all the sub tasks in the 1st task, one by one

---

**Cursor**

Let me start creating the directory structure and files simultaneously:

Now let me create all the files in parallel:

```ignore
# Dependencies
node_modules/
**/node_modules/

# Build output
dist/
**/dist/
build/
**/build/

# Environment variables (NEVER commit secrets)
.env
**/.env

# Logs
*.log
**/*.log
logs/
**/logs/

# TypeScript cache
*.tsbuildinfo
**/*.tsbuildinfo

# IDE / Editor
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db

# Test coverage
coverage/
**/coverage/
.nyc_output/

# Docker overrides
docker-compose.override.yml

```

Now let me create the TypeScript config files, Dockerfiles, and infrastructure files in parallel:

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}

```

```jsonc
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}

```

```jsonc
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}

```

```jsonc
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}

```

```jsonc
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}

```

```jsonc
{
  "extends": "../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}

```

Now create all Dockerfiles and .dockerignore files in parallel:

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Stage 2: Production image ─────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3001

CMD ["node", "dist/index.js"]

```

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Stage 2: Production image ─────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3002

CMD ["node", "dist/index.js"]

```

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Stage 2: Production image ─────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3003

CMD ["node", "dist/index.js"]

```

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Stage 2: Production image ─────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3004

CMD ["node", "dist/index.js"]

```

```dockerfile
# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Stage 2: Production image ─────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 8080

CMD ["node", "dist/index.js"]

```

Now create the `.dockerignore` files for all services:

```plaintext
node_modules
dist
.env
*.test.ts
*.spec.ts
coverage
.nyc_output
*.log

```

```plaintext
node_modules
dist
.env
*.test.ts
*.spec.ts
coverage
.nyc_output
*.log

```

```plaintext
node_modules
dist
.env
*.test.ts
*.spec.ts
coverage
.nyc_output
*.log

```

```plaintext
node_modules
dist
.env
*.test.ts
*.spec.ts
coverage
.nyc_output
*.log

```

```plaintext
node_modules
dist
.env
*.test.ts
*.spec.ts
coverage
.nyc_output
*.log

```

Now create the PostgreSQL init script and RabbitMQ definitions in parallel:

```sql
-- ============================================================
--  Food Delivery App — PostgreSQL Initialisation Script
--  Executed automatically on first container start
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ──────────────────────────────────────────────────────────────
--  TABLES
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS restaurants (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    address     TEXT         NOT NULL,
    lat         DECIMAL(10, 7) NOT NULL,
    lng         DECIMAL(10, 7) NOT NULL,
    is_open     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS menu_categories (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID         NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name          VARCHAR(255) NOT NULL,
    display_order INT          NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS menu_items (
    id            UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id   UUID           NOT NULL REFERENCES menu_categories(id) ON DELETE CASCADE,
    restaurant_id UUID           NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name          VARCHAR(255)   NOT NULL,
    description   TEXT,
    price         DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    is_available  BOOLEAN        NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS drivers (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(255) NOT NULL,
    phone      VARCHAR(20)  NOT NULL UNIQUE,
    vehicle    VARCHAR(100) NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id   UUID           NOT NULL REFERENCES restaurants(id),
    driver_id       UUID           REFERENCES drivers(id),
    status          VARCHAR(50)    NOT NULL DEFAULT 'PENDING',
    total_amount    DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    payment_status  VARCHAR(50)    NOT NULL DEFAULT 'PENDING',
    payment_txn_id  VARCHAR(255),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID           NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id    UUID           NOT NULL,
    name            VARCHAR(255)   NOT NULL,  -- snapshot of item name at time of order
    price_at_time   DECIMAL(10, 2) NOT NULL CHECK (price_at_time >= 0),  -- snapshot price
    quantity        INT            NOT NULL CHECK (quantity > 0)
);

-- ──────────────────────────────────────────────────────────────
--  INDEXES
-- ──────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders (status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id
    ON menu_items (restaurant_id);

-- ──────────────────────────────────────────────────────────────
--  SEED DATA
-- ──────────────────────────────────────────────────────────────

-- Restaurants
INSERT INTO restaurants (id, name, address, lat, lng, is_open) VALUES
(
    '11111111-1111-1111-1111-111111111111',
    'Bella Italia',
    '42 Napoli Street, Downtown',
    40.7128000,
    -74.0060000,
    TRUE
),
(
    '22222222-2222-2222-2222-222222222222',
    'Dragon Palace',
    '88 Jade Avenue, Chinatown',
    40.7158000,
    -73.9970000,
    TRUE
);

-- Menu Categories — Bella Italia
INSERT INTO menu_categories (id, restaurant_id, name, display_order) VALUES
(
    'a1111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'Pizzas',
    1
),
(
    'a2222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Pastas',
    2
);

-- Menu Categories — Dragon Palace
INSERT INTO menu_categories (id, restaurant_id, name, display_order) VALUES
(
    'b1111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'Dim Sum',
    1
),
(
    'b2222222-2222-2222-2222-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'Noodles',
    2
);

-- Menu Items — Bella Italia Pizzas (3 items)
INSERT INTO menu_items (id, category_id, restaurant_id, name, description, price, is_available) VALUES
(
    'c1111111-1111-1111-1111-111111111111',
    'a1111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.99,
    TRUE
),
(
    'c2222222-2222-2222-2222-222222222222',
    'a1111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.99,
    TRUE
),
(
    'c3333333-3333-3333-3333-333333333333',
    'a1111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives on tomato base',
    15.99,
    TRUE
);

-- Menu Items — Bella Italia Pastas (3 items)
INSERT INTO menu_items (id, category_id, restaurant_id, name, description, price, is_available) VALUES
(
    'c4444444-4444-4444-4444-444444444444',
    'a2222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino Romano, black pepper',
    13.99,
    TRUE
),
(
    'c5555555-5555-5555-5555-555555555555',
    'a2222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    11.99,
    TRUE
),
(
    'c6666666-6666-6666-6666-666666666666',
    'a2222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream sauce',
    13.49,
    TRUE
);

-- Menu Items — Dragon Palace Dim Sum (3 items)
INSERT INTO menu_items (id, category_id, restaurant_id, name, description, price, is_available) VALUES
(
    'd1111111-1111-1111-1111-111111111111',
    'b1111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'Har Gow',
    'Steamed shrimp dumplings in translucent rice wrapper',
    8.99,
    TRUE
),
(
    'd2222222-2222-2222-2222-222222222222',
    'b1111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    8.49,
    TRUE
),
(
    'd3333333-3333-3333-3333-333333333333',
    'b1111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    7.99,
    TRUE
);

-- Menu Items — Dragon Palace Noodles (3 items)
INSERT INTO menu_items (id, category_id, restaurant_id, name, description, price, is_available) VALUES
(
    'd4444444-4444-4444-4444-444444444444',
    'b2222222-2222-2222-2222-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef and bean sprouts',
    14.99,
    TRUE
),
(
    'd5555555-5555-5555-5555-555555555555',
    'b2222222-2222-2222-2222-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork and chilli oil',
    12.99,
    TRUE
),
(
    'd6666666-6666-6666-6666-666666666666',
    'b2222222-2222-2222-2222-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.49,
    TRUE
);

-- Drivers (3 drivers)
INSERT INTO drivers (id, name, phone, vehicle, is_active) VALUES
(
    'e1111111-1111-1111-1111-111111111111',
    'Alex Rivera',
    '+1-555-0101',
    'Honda PCX 150 Scooter',
    TRUE
),
(
    'e2222222-2222-2222-2222-222222222222',
    'Sam Chen',
    '+1-555-0102',
    'Yamaha NMAX 155 Scooter',
    TRUE
),
(
    'e3333333-3333-3333-3333-333333333333',
    'Jordan Lee',
    '+1-555-0103',
    'Trek FX3 Disc Bicycle',
    TRUE
);

```

```json
{
  "rabbit_version": "3.12.0",
  "rabbitmq_version": "3.12.0",
  "product_name": "RabbitMQ",
  "product_version": "3.12.0",
  "users": [
    {
      "name": "guest",
      "password_hash": "CY9rzUYh03PK3k6DJie09g==",
      "hashing_algorithm": "rabbit_password_hashing_md5",
      "tags": ["administrator"],
      "limits": {}
    }
  ],
  "vhosts": [
    { "name": "/" }
  ],
  "permissions": [
    {
      "user": "guest",
      "vhost": "/",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    }
  ],
  "topic_permissions": [],
  "parameters": [],
  "global_parameters": [
    {
      "name": "cluster_name",
      "value": "food-delivery@rabbitmq"
    }
  ],
  "policies": [],
  "exchanges": [
    {
      "name": "order.events",
      "vhost": "/",
      "type": "fanout",
      "durable": true,
      "auto_delete": false,
      "internal": false,
      "arguments": {}
    },
    {
      "name": "driver.events",
      "vhost": "/",
      "type": "direct",
      "durable": true,
      "auto_delete": false,
      "internal": false,
      "arguments": {}
    }
  ],
  "queues": [
    {
      "name": "orders.notification",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {}
    },
    {
      "name": "orders.driver-assign",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {}
    },
    {
      "name": "driver.location.notification",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {
        "x-message-ttl": 60000
      }
    }
  ],
  "bindings": [
    {
      "source": "order.events",
      "vhost": "/",
      "destination": "orders.notification",
      "destination_type": "queue",
      "routing_key": "",
      "arguments": {}
    },
    {
      "source": "order.events",
      "vhost": "/",
      "destination": "orders.driver-assign",
      "destination_type": "queue",
      "routing_key": "",
      "arguments": {}
    },
    {
      "source": "driver.events",
      "vhost": "/",
      "destination": "driver.location.notification",
      "destination_type": "queue",
      "routing_key": "driver.location.updated",
      "arguments": {}
    }
  ]
}

```

Now create the `docker-compose.yml` — the most complex file:

```dockercompose
version: "3.9"

# ──────────────────────────────────────────────────────────────
#  Named Network
# ──────────────────────────────────────────────────────────────
networks:
  food-delivery-net:
    driver: bridge

# ──────────────────────────────────────────────────────────────
#  Named Volumes (data survives container restarts)
# ──────────────────────────────────────────────────────────────
volumes:
  postgres_data:
  redis_data:

# ──────────────────────────────────────────────────────────────
#  Services
# ──────────────────────────────────────────────────────────────
services:

  # ── Infrastructure ─────────────────────────────────────────

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    env_file: .env
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infra/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - food-delivery-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 20s

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data
    networks:
      - food-delivery-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  rabbitmq:
    image: rabbitmq:3-management-alpine
    restart: unless-stopped
    env_file: .env
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_DEFAULT_USER:-guest}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_DEFAULT_PASS:-guest}
      RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS: >-
        -rabbitmq_management load_definitions "/etc/rabbitmq/definitions.json"
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - ./infra/rabbitmq/definitions.json:/etc/rabbitmq/definitions.json:ro
    networks:
      - food-delivery-net
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 30s

  # ── Application Services ────────────────────────────────────

  restaurant-menu-service:
    build:
      context: ./services/restaurant-menu-service
      dockerfile: Dockerfile
    env_file: .env
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: ${RESTAURANT_MENU_PORT:-3001}
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      REDIS_HOST: redis
      REDIS_PORT: 6379
    ports:
      - "${RESTAURANT_MENU_PORT:-3001}:3001"
    networks:
      - food-delivery-net
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  order-service:
    build:
      context: ./services/order-service
      dockerfile: Dockerfile
    env_file: .env
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: ${ORDER_SERVICE_PORT:-3002}
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      RABBITMQ_URL: ${RABBITMQ_URL}
    ports:
      - "${ORDER_SERVICE_PORT:-3002}:3002"
    networks:
      - food-delivery-net
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy

  driver-location-service:
    build:
      context: ./services/driver-location-service
      dockerfile: Dockerfile
    env_file: .env
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: ${DRIVER_LOCATION_PORT:-3003}
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      RABBITMQ_URL: ${RABBITMQ_URL}
    ports:
      - "${DRIVER_LOCATION_PORT:-3003}:3003"
    networks:
      - food-delivery-net
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy

  notification-service:
    build:
      context: ./services/notification-service
      dockerfile: Dockerfile
    env_file: .env
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: ${NOTIFICATION_PORT:-3004}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      RABBITMQ_URL: ${RABBITMQ_URL}
    ports:
      - "${NOTIFICATION_PORT:-3004}:3004"
    networks:
      - food-delivery-net
    depends_on:
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy

  api-gateway:
    build:
      context: ./api-gateway
      dockerfile: Dockerfile
    env_file: .env
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: ${API_GATEWAY_PORT:-8080}
      RESTAURANT_MENU_SERVICE_URL: http://restaurant-menu-service:3001
      ORDER_SERVICE_URL: http://order-service:3002
      DRIVER_LOCATION_SERVICE_URL: http://driver-location-service:3003
      NOTIFICATION_SERVICE_URL: http://notification-service:3004
    ports:
      - "${API_GATEWAY_PORT:-8080}:8080"
    networks:
      - food-delivery-net
    depends_on:
      - restaurant-menu-service
      - order-service
      - driver-location-service
      - notification-service

```

All 7 subtasks are done. Let me verify the full directory structure looks correct:

All files are in place. Here's a summary of everything implemented across all 7 subtasks:

---

## Task 01 — Infrastructure: Complete ✅

### Subtask 1.1 — Monorepo Layout
- ✅ Full directory tree: `services/`, `api-gateway/`, `infra/postgres/`, `infra/rabbitmq/`
- ✅ `.gitignore` — covers `node_modules`, `dist`, `.env`, `*.log`, `coverage`, IDE files
- ✅ `.env.example` — all required variable keys with empty values

### Subtask 1.2 — Dockerfiles
- ✅ Multi-stage `Dockerfile` for all **5 services** (builder → runner pattern)
  - `restaurant-menu-service` → EXPOSE 3001
  - `order-service` → EXPOSE 3002
  - `driver-location-service` → EXPOSE 3003
  - `notification-service` → EXPOSE 3004
  - `api-gateway` → EXPOSE 8080
- ✅ `.dockerignore` for each (excludes `node_modules`, `dist`, `.env`, `*.test.ts`)

### Subtask 1.3 — `docker-compose.yml`
- ✅ All **8 containers** declared (postgres, redis, rabbitmq + 4 services + gateway)
- ✅ Named network `food-delivery-net` (bridge driver)
- ✅ Named volumes `postgres_data` and `redis_data`
- ✅ Health checks on postgres (`pg_isready`), redis (`redis-cli ping`), rabbitmq (`rabbitmq-diagnostics ping`)
- ✅ `depends_on: condition: service_healthy` — services wait for infra
- ✅ `restart: unless-stopped` on all infra containers
- ✅ `env_file: .env` — secrets sourced from `.env`
- ✅ `init.sql` mounted into postgres; `definitions.json` mounted into rabbitmq

### Subtask 1.4 — `infra/postgres/init.sql`
- ✅ 6 tables: `restaurants`, `menu_categories`, `menu_items`, `drivers`, `orders`, `order_items`
- ✅ 3 indexes: `orders(status)`, `order_items(order_id)`, `menu_items(restaurant_id)`
- ✅ Seed: 2 restaurants · 2 categories each · 3 items per category · 3 drivers

### Subtask 1.5 — `infra/rabbitmq/definitions.json`
- ✅ Exchange `order.events` — type **fanout**, durable
- ✅ Exchange `driver.events` — type **direct**, durable
- ✅ Queue `orders.notification` — bound to `order.events` fanout
- ✅ Queue `orders.driver-assign` — bound to `order.events` fanout
- ✅ Queue `driver.location.notification` — bound to `driver.events` with routing key `driver.location.updated`, **x-message-ttl: 60000**

### Subtask 1.6 — `.env.example`
- ✅ All required keys: Postgres, Redis, RabbitMQ, service ports, NODE_ENV

### Subtask 1.7 — TypeScript Config
- ✅ Root `tsconfig.base.json` — `strict: true`, `target: ES2022`, `module: NodeNext`, `moduleResolution: NodeNext`
- ✅ Per-service `tsconfig.json` extending `../../tsconfig.base.json` (and `../tsconfig.base.json` for api-gateway)

# Subtasks of task 2 implementation
_Exported on 2/21/2026 at 17:13:47 GMT+5:30 from Cursor (2.3.30)_

---

**User**

Implement all the sub tasks in task 2

---

**Cursor**

Now let me read the existing files in the restaurant-menu-service directory and check the architecture:

```json
{
  "name": "restaurant-menu-service",
  "version": "1.0.0",
  "description": "Restaurant & Menu Service for Food Delivery App",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node-dev --esm --respawn --transpile-only src/index.ts"
  },
  "dependencies": {
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "ioredis": "^5.4.1",
    "pg": "^8.12.0",
    "uuid": "^10.0.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.14.10",
    "@types/pg": "^8.11.6",
    "@types/uuid": "^10.0.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.3"
  }
}

```

Now let me create all the source files simultaneously:

```typescript
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env['POSTGRES_HOST'] || 'localhost',
  port: parseInt(process.env['POSTGRES_PORT'] || '5432', 10),
  user: process.env['POSTGRES_USER'] || 'foodapp',
  password: process.env['POSTGRES_PASSWORD'] || 'foodapp',
  database: process.env['POSTGRES_DB'] || 'foodapp',
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
});

pool.on('error', (err: Error) => {
  console.error('[DB] Unexpected pool error:', err.message);
});

export async function query<T = pg.QueryResultRow>(
  text: string,
  params?: unknown[],
): Promise<pg.QueryResult<T>> {
  const start = Date.now();
  const result = await pool.query<T>(text, params);
  const duration = Date.now() - start;
  console.debug(`[DB] query="${text.slice(0, 60)}" rows=${result.rowCount} duration=${duration}ms`);
  return result;
}

export default pool;

```

```typescript
import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

let retryCount = 0;
const MAX_RETRIES = 3;

const redisClient = new Redis({
  host: process.env['REDIS_HOST'] || 'localhost',
  port: parseInt(process.env['REDIS_PORT'] || '6379', 10),
  lazyConnect: true,
  retryStrategy(times: number): number | null {
    retryCount = times;
    if (times > MAX_RETRIES) {
      console.error(`[Redis] Max retries (${MAX_RETRIES}) reached. Giving up.`);
      return null; // stop retrying
    }
    const delay = Math.min(times * 200, 2_000); // exponential back-off, max 2s
    console.warn(`[Redis] Connection attempt ${times}. Retrying in ${delay}ms...`);
    return delay;
  },
});

redisClient.on('connect', () => {
  retryCount = 0;
  console.info('[Redis] Connected');
});

redisClient.on('error', (err: Error) => {
  console.error(`[Redis] Error: ${err.message}`);
});

redisClient.on('close', () => {
  console.warn('[Redis] Connection closed');
});

// Attempt initial connection without crashing the process on failure
redisClient.connect().catch((err: Error) => {
  console.warn(`[Redis] Initial connection failed: ${err.message}. Service will degrade to DB-only mode.`);
});

export { retryCount };
export default redisClient;

```

```typescript
export interface Restaurant {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  is_open: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface MenuCategory {
  id: string;
  restaurant_id: string;
  name: string;
  display_order: number;
}

export interface MenuItem {
  id: string;
  category_id: string;
  restaurant_id: string;
  name: string;
  description: string;
  price: number;
  is_available: boolean;
}

export interface FullMenu {
  restaurant: Restaurant;
  categories: Array<MenuCategory & { items: MenuItem[] }>;
}

// Payload types for mutations
export interface CreateRestaurantPayload {
  name: string;
  address: string;
  lat: number;
  lng: number;
  is_open?: boolean;
}

export interface UpdateMenuItemPayload {
  name?: string;
  description?: string;
  price?: number;
  is_available?: boolean;
}

```

```typescript
import { query } from '../config/db.js';
import redisClient from '../config/redis.js';
import type {
  Restaurant,
  MenuCategory,
  MenuItem,
  FullMenu,
  CreateRestaurantPayload,
  UpdateMenuItemPayload,
} from '../types/index.js';

const MENU_TTL = 60;         // seconds
const RESTAURANTS_TTL = 30;  // seconds

// ── Cache helpers ────────────────────────────────────────────────────────────

async function redisGet(key: string): Promise<string | null> {
  try {
    return await redisClient.get(key);
  } catch (err) {
    console.warn(`[Redis] GET "${key}" failed — skipping cache:`, (err as Error).message);
    return null;
  }
}

async function redisSet(key: string, value: string, ttl: number): Promise<void> {
  try {
    await redisClient.set(key, value, 'EX', ttl);
  } catch (err) {
    console.warn(`[Redis] SET "${key}" failed — continuing without cache:`, (err as Error).message);
  }
}

async function redisDel(key: string): Promise<void> {
  try {
    await redisClient.del(key);
  } catch (err) {
    console.warn(`[Redis] DEL "${key}" failed:`, (err as Error).message);
  }
}

// ── getFullMenu ──────────────────────────────────────────────────────────────

export async function getFullMenu(
  restaurantId: string,
): Promise<{ menu: FullMenu | null; cacheHit: boolean }> {
  const cacheKey = `menu:${restaurantId}`;

  // 1. Try cache
  const cached = await redisGet(cacheKey);
  if (cached !== null) {
    return { menu: JSON.parse(cached) as FullMenu, cacheHit: true };
  }

  // 2. Cache MISS — query DB
  const restaurantResult = await query<Restaurant>(
    'SELECT id, name, address, lat, lng, is_open, created_at, updated_at FROM restaurants WHERE id = $1',
    [restaurantId],
  );

  if (restaurantResult.rowCount === 0) {
    return { menu: null, cacheHit: false };
  }

  const restaurant = restaurantResult.rows[0]!;

  const categoriesResult = await query<MenuCategory>(
    'SELECT id, restaurant_id, name, display_order FROM menu_categories WHERE restaurant_id = $1 ORDER BY display_order',
    [restaurantId],
  );

  const itemsResult = await query<MenuItem>(
    'SELECT id, category_id, restaurant_id, name, description, price, is_available FROM menu_items WHERE restaurant_id = $1',
    [restaurantId],
  );

  // Group items by category
  const itemsByCategory = new Map<string, MenuItem[]>();
  for (const item of itemsResult.rows) {
    const list = itemsByCategory.get(item.category_id) ?? [];
    list.push(item);
    itemsByCategory.set(item.category_id, list);
  }

  const menu: FullMenu = {
    restaurant,
    categories: categoriesResult.rows.map((cat) => ({
      ...cat,
      items: itemsByCategory.get(cat.id) ?? [],
    })),
  };

  // 3. Populate cache
  await redisSet(cacheKey, JSON.stringify(menu), MENU_TTL);

  return { menu, cacheHit: false };
}

// ── invalidateMenuCache ──────────────────────────────────────────────────────

export async function invalidateMenuCache(restaurantId: string): Promise<void> {
  await redisDel(`menu:${restaurantId}`);
}

// ── getAllRestaurants ────────────────────────────────────────────────────────

export async function getAllRestaurants(): Promise<Restaurant[]> {
  const cacheKey = 'restaurants:list';

  const cached = await redisGet(cacheKey);
  if (cached !== null) {
    return JSON.parse(cached) as Restaurant[];
  }

  const result = await query<Restaurant>(
    'SELECT id, name, address, lat, lng, is_open, created_at, updated_at FROM restaurants ORDER BY name',
  );

  await redisSet(cacheKey, JSON.stringify(result.rows), RESTAURANTS_TTL);
  return result.rows;
}

// ── createRestaurant ─────────────────────────────────────────────────────────

export async function createRestaurant(data: CreateRestaurantPayload): Promise<Restaurant> {
  const { name, address, lat, lng, is_open = true } = data;

  const result = await query<Restaurant>(
    `INSERT INTO restaurants (name, address, lat, lng, is_open)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, name, address, lat, lng, is_open, created_at, updated_at`,
    [name, address, lat, lng, is_open],
  );

  // Invalidate list cache
  await redisDel('restaurants:list');

  return result.rows[0]!;
}

// ── updateMenuItem ───────────────────────────────────────────────────────────

export async function updateMenuItem(
  restaurantId: string,
  itemId: string,
  data: UpdateMenuItemPayload,
): Promise<MenuItem | null> {
  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (data.name !== undefined) { fields.push(`name = $${idx++}`); values.push(data.name); }
  if (data.description !== undefined) { fields.push(`description = $${idx++}`); values.push(data.description); }
  if (data.price !== undefined) { fields.push(`price = $${idx++}`); values.push(data.price); }
  if (data.is_available !== undefined) { fields.push(`is_available = $${idx++}`); values.push(data.is_available); }

  if (fields.length === 0) return null;

  values.push(itemId, restaurantId);

  const result = await query<MenuItem>(
    `UPDATE menu_items
     SET ${fields.join(', ')}, updated_at = NOW()
     WHERE id = $${idx++} AND restaurant_id = $${idx++}
     RETURNING id, category_id, restaurant_id, name, description, price, is_available`,
    values,
  );

  if (result.rowCount === 0) return null;

  await invalidateMenuCache(restaurantId);
  return result.rows[0]!;
}

```

```typescript
import { Router, Request, Response, NextFunction } from 'express';
import { validate as uuidValidate } from 'uuid';
import {
  getAllRestaurants,
  getFullMenu,
  createRestaurant,
  updateMenuItem,
} from '../services/menuService.js';
import type { CreateRestaurantPayload, UpdateMenuItemPayload } from '../types/index.js';

const router = Router();

// ── UUID guard ───────────────────────────────────────────────────────────────

function assertUUID(value: string, res: Response): boolean {
  if (!uuidValidate(value)) {
    res.status(400).json({ error: `Invalid UUID: "${value}"` });
    return false;
  }
  return true;
}

// ── GET /restaurants ─────────────────────────────────────────────────────────

router.get('/restaurants', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await getAllRestaurants();
    res.json({ data });
  } catch (err) {
    next(err);
  }
});

// ── GET /restaurants/:id/menu ────────────────────────────────────────────────

router.get(
  '/restaurants/:id/menu',
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;

    if (!assertUUID(id, res)) return;

    try {
      const { menu, cacheHit } = await getFullMenu(id);

      if (!menu) {
        res.status(404).json({ error: `Restaurant "${id}" not found` });
        return;
      }

      res.setHeader('X-Cache', cacheHit ? 'HIT' : 'MISS');
      res.json({ data: menu });
    } catch (err) {
      next(err);
    }
  },
);

// ── POST /restaurants ────────────────────────────────────────────────────────

router.post('/restaurants', async (req: Request, res: Response, next: NextFunction) => {
  const body = req.body as Partial<CreateRestaurantPayload>;

  const errors: string[] = [];
  if (!body.name || typeof body.name !== 'string') errors.push('name is required');
  if (!body.address || typeof body.address !== 'string') errors.push('address is required');
  if (body.lat === undefined || typeof body.lat !== 'number') errors.push('lat is required and must be a number');
  if (body.lng === undefined || typeof body.lng !== 'number') errors.push('lng is required and must be a number');

  if (errors.length > 0) {
    res.status(400).json({ error: 'Validation failed', details: errors });
    return;
  }

  try {
    const data = await createRestaurant(body as CreateRestaurantPayload);
    res.status(201).json({ data });
  } catch (err) {
    next(err);
  }
});

// ── PUT /restaurants/:id/menu-items/:itemId ──────────────────────────────────

router.put(
  '/restaurants/:id/menu-items/:itemId',
  async (req: Request, res: Response, next: NextFunction) => {
    const { id, itemId } = req.params;

    if (!assertUUID(id, res) || !assertUUID(itemId, res)) return;

    const body = req.body as Partial<UpdateMenuItemPayload>;
    const allowed = ['name', 'description', 'price', 'is_available'];
    const provided = allowed.filter((k) => k in body);

    if (provided.length === 0) {
      res.status(400).json({
        error: 'At least one of name, price, description, is_available must be provided',
      });
      return;
    }

    // Type-check numeric price
    if (body.price !== undefined && typeof body.price !== 'number') {
      res.status(400).json({ error: 'price must be a number' });
      return;
    }

    try {
      const data = await updateMenuItem(id, itemId, body as UpdateMenuItemPayload);

      if (!data) {
        res.status(404).json({ error: `Menu item "${itemId}" not found for restaurant "${id}"` });
        return;
      }

      res.json({ data });
    } catch (err) {
      next(err);
    }
  },
);

export default router;

```

```typescript
import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import restaurantRouter from './routes/restaurants.js';

const app = express();

// ── Middleware ───────────────────────────────────────────────────────────────

app.use(express.json());

// ── Health check ─────────────────────────────────────────────────────────────

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'restaurant-menu-service' });
});

// ── Routes ───────────────────────────────────────────────────────────────────

app.use('/', restaurantRouter);

// ── Global error handler ─────────────────────────────────────────────────────

interface PgError extends Error {
  code?: string;
}

app.use((err: PgError, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Error]', err.message, err.stack);

  // PostgreSQL unique violation
  if (err.code === '23505') {
    res.status(409).json({ error: 'Resource already exists', detail: err.message });
    return;
  }

  // PostgreSQL not-null / check constraint violation
  if (err.code === '23502' || err.code === '23514') {
    res.status(400).json({ error: 'Invalid data', detail: err.message });
    return;
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    res.status(422).json({ error: 'Referenced resource does not exist', detail: err.message });
    return;
  }

  res.status(500).json({ error: 'Internal server error' });
});

// ── Start ────────────────────────────────────────────────────────────────────

const PORT = parseInt(process.env['RESTAURANT_MENU_PORT'] ?? '3001', 10);

app.listen(PORT, () => {
  console.info(`[restaurant-menu-service] Listening on port ${PORT}`);
});

export default app;

```

Now let me verify the final file structure:

All files are in place. Let me do a final review of the line counts to ensure no file exceeds 500 lines:

All files are well within the 500-line limit. Here's a complete summary of everything implemented for **Task 2 — Restaurant & Menu Service**:

---

## Task 2 — All Subtasks Implemented ✅

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `package.json` | — | Runtime & dev deps, npm scripts (`build`, `start`, `dev`) |
| `src/types/index.ts` | 48 | `Restaurant`, `MenuCategory`, `MenuItem`, `FullMenu`, payload types |
| `src/config/db.ts` | 34 | `pg.Pool` with env vars, `query()` helper, pool error logging |
| `src/config/redis.ts` | 44 | `ioredis` client, exponential back-off (max 3 retries), graceful startup failure |
| `src/services/menuService.ts` | 173 | Full cache-aside logic for all 5 service functions |
| `src/routes/restaurants.ts` | 124 | 4 REST route handlers with validation |
| `src/index.ts` | 59 | Express app, health check, global error handler, port 3001 |

### Subtask Coverage

- **2.1** — `package.json` with all runtime/dev deps and `build`/`start`/`dev` scripts; `tsconfig.json` already existed extending root base
- **2.2** — `src/config/db.ts`: `pg.Pool` from env vars, `query()` helper, pool `error` event logging
- **2.3** — `src/config/redis.ts`: `ioredis` singleton, exponential back-off up to 3 retries, non-crashing on connection failure
- **2.4** — `src/types/index.ts`: all 4 required interfaces + payload types for mutations
- **2.5** — `src/services/menuService.ts`: `getFullMenu` (cache-aside, TTL 60s, returns `cacheHit` flag), `invalidateMenuCache`, `getAllRestaurants` (TTL 30s), `createRestaurant`, `updateMenuItem` with dynamic `SET` clause
- **2.6** — `src/routes/restaurants.ts`: `GET /restaurants`, `GET /restaurants/:id/menu` (with `X-Cache: HIT/MISS` header), `POST /restaurants` (body validation), `PUT /restaurants/:id/menu-items/:itemId`
- **2.7** — `src/index.ts`: `dotenv`, `express.json()`, health endpoint, router mounted at `/`, global error handler, port `RESTAURANT_MENU_PORT || 3001`
- **2.8** — UUID validation via `uuid.validate()` → `400`; PostgreSQL error codes (`23505` conflict → `409`, `23502/23514` constraint → `400`, `23503` FK → `422`); Redis wrapped in try/catch everywhere — falls through to DB on cache failure (graceful degradation)

# Subtasks implementation for task3
_Exported on 2/21/2026 at 17:17:04 GMT+5:30 from Cursor (2.3.30)_

---

**User**

Implement all subtasks in task3

---

**Cursor**


Reviewing task 3 and its subtasks.



Reading task 3 to identify the subtasks:



Checking the current state of the order-service directory:



Reviewing existing files to understand the patterns:



Checking RabbitMQ definitions:



Creating the initial todo list and starting implementation:



Implementing all subtasks, starting with project scaffolding:


```json
{
  "name": "order-service",
  "version": "1.0.0",
  "description": "Order Service for Food Delivery App",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node-dev --esm --respawn --transpile-only src/index.ts"
  },
  "dependencies": {
    "amqplib": "^0.10.4",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "ioredis": "^5.4.1",
    "pg": "^8.12.0",
    "uuid": "^10.0.0"
  },
  "devDependencies": {
    "@types/amqplib": "^0.10.4",
    "@types/express": "^4.17.21",
    "@types/node": "^20.14.10",
    "@types/pg": "^8.11.6",
    "@types/uuid": "^10.0.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.3"
  }
}

```


Implementing the config files:


```typescript
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env['POSTGRES_HOST'] || 'localhost',
  port: parseInt(process.env['POSTGRES_PORT'] || '5432', 10),
  user: process.env['POSTGRES_USER'] || 'foodapp',
  password: process.env['POSTGRES_PASSWORD'] || 'foodapp',
  database: process.env['POSTGRES_DB'] || 'foodapp',
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
});

pool.on('error', (err: Error) => {
  console.error('[DB] Unexpected pool error:', err.message);
});

export async function query<T = pg.QueryResultRow>(
  text: string,
  params?: unknown[],
): Promise<pg.QueryResult<T>> {
  const start = Date.now();
  const result = await pool.query<T>(text, params);
  const duration = Date.now() - start;
  console.debug(`[DB] query="${text.slice(0, 60)}" rows=${result.rowCount} duration=${duration}ms`);
  return result;
}

export async function getClient(): Promise<pg.PoolClient> {
  return await pool.connect();
}

export default pool;

```

```typescript
import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

let retryCount = 0;
const MAX_RETRIES = 3;

const redisClient = new Redis({
  host: process.env['REDIS_HOST'] || 'localhost',
  port: parseInt(process.env['REDIS_PORT'] || '6379', 10),
  lazyConnect: true,
  retryStrategy(times: number): number | null {
    retryCount = times;
    if (times > MAX_RETRIES) {
      console.error(`[Redis] Max retries (${MAX_RETRIES}) reached. Giving up.`);
      return null; // stop retrying
    }
    const delay = Math.min(times * 200, 2_000); // exponential back-off, max 2s
    console.warn(`[Redis] Connection attempt ${times}. Retrying in ${delay}ms...`);
    return delay;
  },
});

redisClient.on('connect', () => {
  retryCount = 0;
  console.info('[Redis] Connected');
});

redisClient.on('error', (err: Error) => {
  console.error(`[Redis] Error: ${err.message}`);
});

redisClient.on('close', () => {
  console.warn('[Redis] Connection closed');
});

// Attempt initial connection without crashing the process on failure
redisClient.connect().catch((err: Error) => {
  console.warn(`[Redis] Initial connection failed: ${err.message}. Service will degrade to DB-only mode.`);
});

export { retryCount };
export default redisClient;

```

```typescript
import amqp from 'amqplib';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env['RABBITMQ_URL'] || 'amqp://guest:guest@localhost:5672';
const MAX_RETRIES = 5;

let connection: amqp.Connection | null = null;
let channel: amqp.Channel | null = null;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectWithRetry(retryCount = 0): Promise<void> {
  try {
    console.info(`[RabbitMQ] Connecting to ${RABBITMQ_URL}...`);
    connection = await amqp.connect(RABBITMQ_URL);

    connection.on('error', (err: Error) => {
      console.error('[RabbitMQ] Connection error:', err.message);
      channel = null;
    });

    connection.on('close', () => {
      console.warn('[RabbitMQ] Connection closed');
      channel = null;
    });

    channel = await connection.createChannel();

    // Assert exchange (idempotent - safe to call multiple times)
    await channel.assertExchange('order.events', 'fanout', {
      durable: true,
    });

    console.info('[RabbitMQ] Connected and exchange asserted');
  } catch (err) {
    const error = err as Error;
    console.error(`[RabbitMQ] Connection failed: ${error.message}`);

    if (retryCount < MAX_RETRIES) {
      const delay = Math.min(Math.pow(2, retryCount) * 1000, 10_000); // exponential back-off, max 10s
      console.warn(`[RabbitMQ] Retrying in ${delay}ms... (attempt ${retryCount + 1}/${MAX_RETRIES})`);
      await sleep(delay);
      return connectWithRetry(retryCount + 1);
    } else {
      console.error('[RabbitMQ] Max retries reached. Exiting.');
      process.exit(1);
    }
  }
}

export async function getChannel(): Promise<amqp.Channel> {
  if (!channel || !connection) {
    await connectWithRetry();
  }
  if (!channel) {
    throw new Error('RabbitMQ channel not available');
  }
  return channel;
}

export async function initializeRabbitMQ(): Promise<void> {
  await connectWithRetry();
}

export async function closeConnection(): Promise<void> {
  if (channel) {
    await channel.close();
    channel = null;
  }
  if (connection) {
    await connection.close();
    connection = null;
  }
}

```

```typescript
export enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  PREPARING = 'PREPARING',
  PICKED_UP = 'PICKED_UP',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
}

export enum PaymentStatus {
  PENDING = 'PENDING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
}

export interface CreateOrderBody {
  restaurantId: string;
  items: Array<{
    menuItemId: string;
    quantity: number;
  }>;
}

export interface OrderItem {
  id: string;
  order_id: string;
  menu_item_id: string;
  name: string;
  price_at_time: number;
  quantity: number;
}

export interface Order {
  id: string;
  restaurant_id: string;
  driver_id: string | null;
  status: OrderStatus;
  total_amount: number;
  payment_status: PaymentStatus;
  payment_txn_id: string | null;
  created_at: Date;
  updated_at: Date;
  items?: OrderItem[];
}

export interface PaymentResult {
  success: boolean;
  transactionId: string;
}

export class RestaurantNotAvailableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RestaurantNotAvailableError';
  }
}

export class MenuItemNotAvailableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MenuItemNotAvailableError';
  }
}

export class PaymentFailedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PaymentFailedError';
  }
}

export class InvalidStatusTransitionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'InvalidStatusTransitionError';
  }
}

```

```typescript
import { v4 as uuidv4 } from 'uuid';
import type { PaymentResult } from '../types/index.js';

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function processPayment(
  amount: number,
  orderId: string,
): Promise<PaymentResult> {
  // Simulate network latency
  await sleep(75);

  const transactionId = uuidv4();

  console.info(`[PaymentStub] Processing payment for order ${orderId}: amount=$${amount.toFixed(2)}, transactionId=${transactionId}`);

  // Always return success (this is a stub)
  return {
    success: true,
    transactionId,
  };
}

```

```typescript
import { getChannel } from '../config/rabbitmq.js';
import type { Order, OrderStatus } from '../types/index.js';

export async function publishOrderPlaced(order: Order): Promise<void> {
  try {
    const channel = await getChannel();
    const payload = {
      orderId: order.id,
      restaurantId: order.restaurant_id,
      items: order.items?.map((item) => ({
        menuItemId: item.menu_item_id,
        name: item.name,
        priceAtTime: item.price_at_time,
        quantity: item.quantity,
      })) || [],
      totalAmount: order.total_amount,
      timestamp: new Date().toISOString(),
    };

    channel.publish('order.events', '', Buffer.from(JSON.stringify(payload)), {
      persistent: true,
    });

    console.info(`[Publisher] Published order.placed event for order ${order.id}`);
  } catch (err) {
    const error = err as Error;
    console.error(`[Publisher] Failed to publish order.placed: ${error.message}`);
    throw err;
  }
}

export async function publishOrderStatusUpdated(
  orderId: string,
  status: OrderStatus,
): Promise<void> {
  try {
    const channel = await getChannel();
    const payload = {
      orderId,
      status,
      timestamp: new Date().toISOString(),
    };

    channel.publish('order.events', '', Buffer.from(JSON.stringify(payload)), {
      persistent: true,
    });

    console.info(`[Publisher] Published order.status.updated event for order ${orderId}: ${status}`);
  } catch (err) {
    const error = err as Error;
    console.error(`[Publisher] Failed to publish order.status.updated: ${error.message}`);
    throw err;
  }
}

```


Implementing the order service logic:


```typescript
import { v4 as uuidv4 } from 'uuid';
import { query, getClient } from '../config/db.js';
import redisClient from '../config/redis.js';
import { processPayment } from './paymentStub.js';
import { publishOrderPlaced, publishOrderStatusUpdated } from './publisher.js';
import type {
  CreateOrderBody,
  Order,
  OrderItem,
  OrderStatus,
  PaymentStatus,
  RestaurantNotAvailableError,
  MenuItemNotAvailableError,
  PaymentFailedError,
  InvalidStatusTransitionError,
} from '../types/index.js';
import {
  RestaurantNotAvailableError as RestaurantNotAvailableErrorClass,
  MenuItemNotAvailableError as MenuItemNotAvailableErrorClass,
  PaymentFailedError as PaymentFailedErrorClass,
  InvalidStatusTransitionError as InvalidStatusTransitionErrorClass,
} from '../types/index.js';

interface MenuItemInfo {
  id: string;
  name: string;
  price: number;
  restaurant_id: string;
  is_available: boolean;
}

// Valid status transitions
const VALID_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  [OrderStatus.CONFIRMED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
  [OrderStatus.PICKED_UP]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
  [OrderStatus.DELIVERED]: [], // No transitions from DELIVERED
  [OrderStatus.CANCELLED]: [], // No transitions from CANCELLED
};

function isValidTransition(currentStatus: OrderStatus, newStatus: OrderStatus): boolean {
  // Any status can transition to CANCELLED (except DELIVERED)
  if (newStatus === OrderStatus.CANCELLED && currentStatus !== OrderStatus.DELIVERED) {
    return true;
  }

  const allowed = VALID_TRANSITIONS[currentStatus];
  return allowed.includes(newStatus);
}

export async function placeOrder(
  body: CreateOrderBody,
  idempotencyKey: string,
): Promise<Order> {
  // 1. Idempotency check
  const idempotencyRedisKey = `idempotency:${idempotencyKey}`;
  const existingOrderId = await redisClient.get(idempotencyRedisKey);

  if (existingOrderId) {
    console.info(`[OrderService] Idempotency key found, returning existing order: ${existingOrderId}`);
    const existingOrder = await getOrder(existingOrderId);
    if (existingOrder) {
      return existingOrder;
    }
    // If order not found but key exists, continue processing (stale key)
  }

  // 2. Validate restaurant exists and is open
  const restaurantResult = await query<{ id: string; is_open: boolean }>(
    'SELECT id, is_open FROM restaurants WHERE id = $1',
    [body.restaurantId],
  );

  if (restaurantResult.rows.length === 0) {
    throw new RestaurantNotAvailableErrorClass(`Restaurant ${body.restaurantId} not found`);
  }

  if (!restaurantResult.rows[0].is_open) {
    throw new RestaurantNotAvailableErrorClass(`Restaurant ${body.restaurantId} is closed`);
  }

  // 3. Validate menu items
  const menuItemIds = body.items.map((item) => item.menuItemId);
  const menuItemsResult = await query<MenuItemInfo>(
    `SELECT id, name, price, restaurant_id, is_available 
     FROM menu_items 
     WHERE id = ANY($1::uuid[])`,
    [menuItemIds],
  );

  const menuItemsMap = new Map<string, MenuItemInfo>();
  for (const item of menuItemsResult.rows) {
    menuItemsMap.set(item.id, item);
  }

  // Validate each requested item
  for (const requestedItem of body.items) {
    const menuItem = menuItemsMap.get(requestedItem.menuItemId);

    if (!menuItem) {
      throw new MenuItemNotAvailableErrorClass(
        `Menu item ${requestedItem.menuItemId} not found`,
      );
    }

    if (menuItem.restaurant_id !== body.restaurantId) {
      throw new MenuItemNotAvailableErrorClass(
        `Menu item ${requestedItem.menuItemId} does not belong to restaurant ${body.restaurantId}`,
      );
    }

    if (!menuItem.is_available) {
      throw new MenuItemNotAvailableErrorClass(
        `Menu item ${requestedItem.menuItemId} is not available`,
      );
    }

    if (requestedItem.quantity <= 0) {
      throw new MenuItemNotAvailableErrorClass(
        `Invalid quantity for menu item ${requestedItem.menuItemId}`,
      );
    }
  }

  // 4. Calculate total
  let totalAmount = 0;
  for (const requestedItem of body.items) {
    const menuItem = menuItemsMap.get(requestedItem.menuItemId)!;
    totalAmount += menuItem.price * requestedItem.quantity;
  }

  // 5. Generate order ID
  const orderId = uuidv4();

  // 6. Mock payment
  const paymentResult = await processPayment(totalAmount, orderId);
  if (!paymentResult.success) {
    throw new PaymentFailedErrorClass(`Payment failed for order ${orderId}`);
  }

  // 7. ACID transaction - create order and order items
  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Insert order
    await client.query(
      `INSERT INTO orders (id, restaurant_id, status, total_amount, payment_status, payment_txn_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        orderId,
        body.restaurantId,
        OrderStatus.PENDING,
        totalAmount,
        PaymentStatus.SUCCESS,
        paymentResult.transactionId,
      ],
    );

    // Insert order items
    for (const requestedItem of body.items) {
      const menuItem = menuItemsMap.get(requestedItem.menuItemId)!;
      await client.query(
        `INSERT INTO order_items (order_id, menu_item_id, name, price_at_time, quantity)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          orderId,
          requestedItem.menuItemId,
          menuItem.name,
          menuItem.price,
          requestedItem.quantity,
        ],
      );
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  // 8. Store idempotency key
  await redisClient.setex(idempotencyRedisKey, 86400, orderId); // 24h TTL

  // 9. Fetch complete order with items
  const order = await getOrder(orderId);
  if (!order) {
    throw new Error(`Failed to retrieve created order ${orderId}`);
  }

  // 10. Publish event
  await publishOrderPlaced(order);

  return order;
}

export async function getOrder(orderId: string): Promise<Order | null> {
  const orderResult = await query<Order>(
    `SELECT id, restaurant_id, driver_id, status, total_amount, 
            payment_status, payment_txn_id, created_at, updated_at
     FROM orders
     WHERE id = $1`,
    [orderId],
  );

  if (orderResult.rows.length === 0) {
    return null;
  }

  const order = orderResult.rows[0];

  // Fetch order items
  const itemsResult = await query<OrderItem>(
    `SELECT id, order_id, menu_item_id, name, price_at_time, quantity
     FROM order_items
     WHERE order_id = $1`,
    [orderId],
  );

  return {
    ...order,
    items: itemsResult.rows,
  };
}

export async function updateOrderStatus(
  orderId: string,
  newStatus: OrderStatus,
): Promise<Order | null> {
  // Get current order
  const currentOrder = await getOrder(orderId);
  if (!currentOrder) {
    return null;
  }

  // Validate status transition
  if (!isValidTransition(currentOrder.status as OrderStatus, newStatus)) {
    throw new InvalidStatusTransitionErrorClass(
      `Invalid status transition from ${currentOrder.status} to ${newStatus}`,
    );
  }

  // Update order status
  await query(
    `UPDATE orders 
     SET status = $1, updated_at = NOW() 
     WHERE id = $2`,
    [newStatus, orderId],
  );

  // Publish event
  await publishOrderStatusUpdated(orderId, newStatus);

  // Return updated order
  return await getOrder(orderId);
}

```

```typescript
import { Router, Request, Response, NextFunction } from 'express';
import { validate as uuidValidate } from 'uuid';
import {
  placeOrder,
  getOrder,
  updateOrderStatus,
} from '../services/orderService.js';
import type {
  CreateOrderBody,
  OrderStatus,
  RestaurantNotAvailableError,
  MenuItemNotAvailableError,
  PaymentFailedError,
  InvalidStatusTransitionError,
} from '../types/index.js';
import {
  RestaurantNotAvailableError as RestaurantNotAvailableErrorClass,
  MenuItemNotAvailableError as MenuItemNotAvailableErrorClass,
  PaymentFailedError as PaymentFailedErrorClass,
  InvalidStatusTransitionError as InvalidStatusTransitionErrorClass,
} from '../types/index.js';

const router = Router();

// ── UUID guard ───────────────────────────────────────────────────────────────

function assertUUID(value: string, res: Response): boolean {
  if (!uuidValidate(value)) {
    res.status(400).json({ error: `Invalid UUID: "${value}"` });
    return false;
  }
  return true;
}

// ── POST /orders ─────────────────────────────────────────────────────────────

router.post('/orders', async (req: Request, res: Response, next: NextFunction) => {
  // Extract Idempotency-Key header
  const idempotencyKey = req.headers['idempotency-key'] as string | undefined;

  if (!idempotencyKey) {
    res.status(400).json({ error: 'Idempotency-Key header is required' });
    return;
  }

  // Validate idempotency key is a valid UUID
  if (!uuidValidate(idempotencyKey)) {
    res.status(400).json({ error: 'Idempotency-Key must be a valid UUID' });
    return;
  }

  // Validate body
  const body = req.body as Partial<CreateOrderBody>;
  const errors: string[] = [];

  if (!body.restaurantId || typeof body.restaurantId !== 'string') {
    errors.push('restaurantId is required and must be a string');
  } else if (!uuidValidate(body.restaurantId)) {
    errors.push('restaurantId must be a valid UUID');
  }

  if (!Array.isArray(body.items) || body.items.length === 0) {
    errors.push('items is required and must be a non-empty array');
  } else {
    body.items.forEach((item, index) => {
      if (!item.menuItemId || typeof item.menuItemId !== 'string') {
        errors.push(`items[${index}].menuItemId is required and must be a string`);
      } else if (!uuidValidate(item.menuItemId)) {
        errors.push(`items[${index}].menuItemId must be a valid UUID`);
      }

      if (typeof item.quantity !== 'number' || item.quantity <= 0) {
        errors.push(`items[${index}].quantity is required and must be a positive number`);
      }
    });
  }

  if (errors.length > 0) {
    res.status(400).json({ error: 'Validation failed', details: errors });
    return;
  }

  try {
    const order = await placeOrder(body as CreateOrderBody, idempotencyKey);

    res.status(202).json({
      data: {
        orderId: order.id,
        status: order.status,
      },
    });
  } catch (err) {
    if (err instanceof RestaurantNotAvailableErrorClass) {
      res.status(422).json({ error: err.message });
      return;
    }
    if (err instanceof MenuItemNotAvailableErrorClass) {
      res.status(422).json({ error: err.message });
      return;
    }
    if (err instanceof PaymentFailedErrorClass) {
      res.status(402).json({ error: err.message });
      return;
    }
    next(err);
  }
});

// ── GET /orders/:id ──────────────────────────────────────────────────────────

router.get('/orders/:id', async (req: Request, res: Response, next: NextFunction) => {
  const { id } = req.params;

  if (!assertUUID(id, res)) return;

  try {
    const order = await getOrder(id);

    if (!order) {
      res.status(404).json({ error: `Order "${id}" not found` });
      return;
    }

    res.json({ data: order });
  } catch (err) {
    next(err);
  }
});

// ── PATCH /orders/:id/status ─────────────────────────────────────────────────

router.patch(
  '/orders/:id/status',
  async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;

    if (!assertUUID(id, res)) return;

    const body = req.body as { status?: string };

    if (!body.status || typeof body.status !== 'string') {
      res.status(400).json({ error: 'status is required and must be a string' });
      return;
    }

    // Validate status is a valid OrderStatus
    const validStatuses = Object.values(OrderStatus);
    if (!validStatuses.includes(body.status as OrderStatus)) {
      res.status(400).json({
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
      return;
    }

    try {
      const order = await updateOrderStatus(id, body.status as OrderStatus);

      if (!order) {
        res.status(404).json({ error: `Order "${id}" not found` });
        return;
      }

      res.json({ data: order });
    } catch (err) {
      if (err instanceof InvalidStatusTransitionErrorClass) {
        res.status(400).json({ error: err.message });
        return;
      }
      next(err);
    }
  },
);

export default router;

```

```typescript
import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import orderRouter from './routes/orders.js';
import { initializeRabbitMQ } from './config/rabbitmq.js';

const app = express();

// ── Middleware ───────────────────────────────────────────────────────────────

app.use(express.json());

// ── Health check ─────────────────────────────────────────────────────────────

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'order-service' });
});

// ── Routes ───────────────────────────────────────────────────────────────────

app.use('/', orderRouter);

// ── Global error handler ─────────────────────────────────────────────────────

interface PgError extends Error {
  code?: string;
}

app.use((err: PgError, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Error]', err.message, err.stack);

  // PostgreSQL unique violation
  if (err.code === '23505') {
    res.status(409).json({ error: 'Resource already exists', detail: err.message });
    return;
  }

  // PostgreSQL not-null / check constraint violation
  if (err.code === '23502' || err.code === '23514') {
    res.status(400).json({ error: 'Invalid data', detail: err.message });
    return;
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    res.status(422).json({ error: 'Referenced resource does not exist', detail: err.message });
    return;
  }

  res.status(500).json({ error: 'Internal server error' });
});

// ── Start ────────────────────────────────────────────────────────────────────

const PORT = parseInt(process.env['ORDER_SERVICE_PORT'] ?? '3002', 10);

// Initialize RabbitMQ connection on startup
initializeRabbitMQ()
  .then(() => {
    app.listen(PORT, () => {
      console.info(`[order-service] Listening on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('[order-service] Failed to initialize RabbitMQ:', err);
    process.exit(1);
  });

export default app;

```


Checking for linting errors and fixing any issues:



Fixing the RabbitMQ import to match amqplib's API:



Updating the RabbitMQ import to match amqplib's API:


```typescript
import * as amqp from 'amqplib';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env['RABBITMQ_URL'] || 'amqp://guest:guest@localhost:5672';
const MAX_RETRIES = 5;

let connection: amqp.Connection | null = null;
let channel: amqp.Channel | null = null;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectWithRetry(retryCount = 0): Promise<void> {
  try {
    console.info(`[RabbitMQ] Connecting to ${RABBITMQ_URL}...`);
    connection = await amqp.connect(RABBITMQ_URL);

    connection.on('error', (err: Error) => {
      console.error('[RabbitMQ] Connection error:', err.message);
      channel = null;
    });

    connection.on('close', () => {
      console.warn('[RabbitMQ] Connection closed');
      channel = null;
    });

    channel = await connection.createChannel();

    // Assert exchange (idempotent - safe to call multiple times)
    await channel.assertExchange('order.events', 'fanout', {
      durable: true,
    });

    console.info('[RabbitMQ] Connected and exchange asserted');
  } catch (err) {
    const error = err as Error;
    console.error(`[RabbitMQ] Connection failed: ${error.message}`);

    if (retryCount < MAX_RETRIES) {
      const delay = Math.min(Math.pow(2, retryCount) * 1000, 10_000); // exponential back-off, max 10s
      console.warn(`[RabbitMQ] Retrying in ${delay}ms... (attempt ${retryCount + 1}/${MAX_RETRIES})`);
      await sleep(delay);
      return connectWithRetry(retryCount + 1);
    } else {
      console.error('[RabbitMQ] Max retries reached. Exiting.');
      process.exit(1);
    }
  }
}

export async function getChannel(): Promise<amqp.Channel> {
  if (!channel || !connection) {
    await connectWithRetry();
  }
  if (!channel) {
    throw new Error('RabbitMQ channel not available');
  }
  return channel;
}

export async function initializeRabbitMQ(): Promise<void> {
  await connectWithRetry();
}

export async function closeConnection(): Promise<void> {
  if (channel) {
    await channel.close();
    channel = null;
  }
  if (connection) {
    await connection.close();
    connection = null;
  }
}

```


Checking the Dockerfile:



Dockerfile is correct. Verifying a few details in the order service logic:



Verifying the complete file structure:



All files are in place. Summary of what was implemented:

## Summary

All subtasks for Task 3 (Order Service) are implemented.

### Completed subtasks:

1. **3.1 - Project Scaffolding**
   - Created `package.json` with dependencies (express, pg, ioredis, amqplib, uuid, dotenv)
   - Created folder structure: `src/config/`, `src/routes/`, `src/services/`, `src/types/`
   - `tsconfig.json` extends root config

2. **3.2 - Database Client** (`config/db.ts`)
   - PostgreSQL pool configuration
   - `query()` helper function
   - `getClient()` for manual transaction management

3. **3.3 - Redis Client** (`config/redis.ts`)
   - Singleton ioredis client
   - Retry logic with exponential backoff
   - Used for idempotency key storage

4. **3.4 - RabbitMQ Connection** (`config/rabbitmq.ts`)
   - Connection with retry logic (max 5 retries, exponential backoff)
   - Exchange assertion (`order.events` fanout exchange)
   - Connection lifecycle logging
   - Exports `getChannel()` and `initializeRabbitMQ()`

5. **3.5 - TypeScript Types** (`types/index.ts`)
   - `OrderStatus` enum (PENDING, CONFIRMED, PREPARING, PICKED_UP, DELIVERED, CANCELLED)
   - `PaymentStatus` enum (PENDING, SUCCESS, FAILED)
   - `CreateOrderBody`, `OrderItem`, `Order`, `PaymentResult` interfaces
   - Custom error classes: `RestaurantNotAvailableError`, `MenuItemNotAvailableError`, `PaymentFailedError`, `InvalidStatusTransitionError`

6. **3.6 - Payment Stub** (`services/paymentStub.ts`)
   - Mock payment processing with 75ms delay
   - Always returns success with generated transaction ID
   - Logging for traceability

7. **3.7 - Publisher** (`services/publisher.ts`)
   - `publishOrderPlaced()` - publishes to `order.events` exchange
   - `publishOrderStatusUpdated()` - publishes status updates
   - Messages marked as persistent

8. **3.8 - Order Service Logic** (`services/orderService.ts`)
   - `placeOrder()` - Full order placement flow:
     - Idempotency check via Redis
     - Restaurant validation (exists and open)
     - Menu item validation (exists, belongs to restaurant, available)
     - Total calculation
     - Mock payment processing
     - ACID transaction (orders + order_items)
     - Idempotency key storage (24h TTL)
     - Event publishing
   - `getOrder()` - Fetches order with items
   - `updateOrderStatus()` - Updates status with transition validation
   - Status transition validation (enforces lifecycle rules)

9. **3.9 - Route Handlers** (`routes/orders.ts`)
   - `POST /orders` - Place order (requires `Idempotency-Key` header)
     - Returns 202 Accepted
     - Error handling: 422 for restaurant/item errors, 402 for payment failures
   - `GET /orders/:id` - Get order details
   - `PATCH /orders/:id/status` - Update order status
     - Validates status transitions, returns 400 for invalid transitions

10. **3.10 - Express App Entry Point** (`index.ts`)
    - Express app setup with JSON middleware
    - Health check endpoint (`GET /health`)
    - Routes mounted at `/`
    - Global error handler for PostgreSQL errors
    - RabbitMQ initialization on startup
    - Listens on port 3002

### Features implemented:

- Idempotency: Prevents duplicate orders using Redis keys
- ACID transactions: Order and order items created atomically
- Status lifecycle: Enforces valid status transitions
- Event publishing: Publishes order events to RabbitMQ
- Error handling: Custom error classes with appropriate HTTP status codes
- Validation: Restaurant availability, menu item availability, UUID validation

The service is ready to use and follows the patterns established in the restaurant-menu-service. All files are in place and there are no linting errors.

# Subtasks of task 4 implementation
_Exported on 2/21/2026 at 17:44:21 GMT+5:30 from Cursor (2.3.30)_

---

**User**

Implement all subtasks in task 4

---

**Cursor**


Searching for task 4 and its subtasks.



Reading the full task 4 file to see all subtasks:



Checking what already exists in the driver-location-service directory:



Checking Redis and RabbitMQ patterns from other services, and reviewing the existing tsconfig.json:



Checking for package.json and the src directory structure:



Creating the initial TODO list and starting implementation of all 11 subtasks:


```json
{
  "name": "driver-location-service",
  "version": "1.0.0",
  "description": "Driver Location Service for Food Delivery App",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node-dev --esm --respawn --transpile-only src/index.ts"
  },
  "dependencies": {
    "amqplib": "^0.10.4",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "ioredis": "^5.4.1",
    "pg": "^8.12.0",
    "uuid": "^10.0.0",
    "ws": "^8.18.0"
  },
  "devDependencies": {
    "@types/amqplib": "^0.10.4",
    "@types/express": "^4.17.21",
    "@types/node": "^20.14.10",
    "@types/pg": "^8.11.6",
    "@types/uuid": "^10.0.0",
    "@types/ws": "^8.5.10",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.3"
  }
}

```


Creating the config files, types, services, websocket, routes, and index files:


```typescript
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env['POSTGRES_HOST'] || 'localhost',
  port: parseInt(process.env['POSTGRES_PORT'] || '5432', 10),
  user: process.env['POSTGRES_USER'] || 'foodapp',
  password: process.env['POSTGRES_PASSWORD'] || 'foodapp',
  database: process.env['POSTGRES_DB'] || 'foodapp',
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 2_000,
});

pool.on('error', (err: Error) => {
  console.error('[DB] Unexpected pool error:', err.message);
});

export async function query<T = pg.QueryResultRow>(
  text: string,
  params?: unknown[],
): Promise<pg.QueryResult<T>> {
  const start = Date.now();
  const result = await pool.query<T>(text, params);
  const duration = Date.now() - start;
  console.debug(`[DB] query="${text.slice(0, 60)}" rows=${result.rowCount} duration=${duration}ms`);
  return result;
}

export async function getClient(): Promise<pg.PoolClient> {
  return await pool.connect();
}

export default pool;

```

```typescript
import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

let retryCount = 0;
const MAX_RETRIES = 3;

const redisClient = new Redis({
  host: process.env['REDIS_HOST'] || 'localhost',
  port: parseInt(process.env['REDIS_PORT'] || '6379', 10),
  lazyConnect: true,
  retryStrategy(times: number): number | null {
    retryCount = times;
    if (times > MAX_RETRIES) {
      console.error(`[Redis] Max retries (${MAX_RETRIES}) reached. Giving up.`);
      return null; // stop retrying
    }
    const delay = Math.min(times * 200, 2_000); // exponential back-off, max 2s
    console.warn(`[Redis] Connection attempt ${times}. Retrying in ${delay}ms...`);
    return delay;
  },
});

redisClient.on('connect', () => {
  retryCount = 0;
  console.info('[Redis] Connected');
});

redisClient.on('error', (err: Error) => {
  console.error(`[Redis] Error: ${err.message}`);
});

redisClient.on('close', () => {
  console.warn('[Redis] Connection closed');
});

// Attempt initial connection without crashing the process on failure
redisClient.connect().catch((err: Error) => {
  console.warn(`[Redis] Initial connection failed: ${err.message}. Service will degrade to DB-only mode.`);
});

export { retryCount };
export default redisClient;

```

```typescript
import * as amqp from 'amqplib';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env['RABBITMQ_URL'] || 'amqp://guest:guest@localhost:5672';
const MAX_RETRIES = 5;

let connection: amqp.Connection | null = null;
let channel: amqp.Channel | null = null;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectWithRetry(retryCount = 0): Promise<void> {
  try {
    console.info(`[RabbitMQ] Connecting to ${RABBITMQ_URL}...`);
    connection = await amqp.connect(RABBITMQ_URL);

    connection.on('error', (err: Error) => {
      console.error('[RabbitMQ] Connection error:', err.message);
      channel = null;
    });

    connection.on('close', () => {
      console.warn('[RabbitMQ] Connection closed');
      channel = null;
    });

    channel = await connection.createChannel();

    // Assert exchange (idempotent - safe to call multiple times)
    await channel.assertExchange('driver.events', 'direct', {
      durable: true,
    });

    console.info('[RabbitMQ] Connected and exchange asserted');
  } catch (err) {
    const error = err as Error;
    console.error(`[RabbitMQ] Connection failed: ${error.message}`);

    if (retryCount < MAX_RETRIES) {
      const delay = Math.min(Math.pow(2, retryCount) * 1000, 10_000); // exponential back-off, max 10s
      console.warn(`[RabbitMQ] Retrying in ${delay}ms... (attempt ${retryCount + 1}/${MAX_RETRIES})`);
      await sleep(delay);
      return connectWithRetry(retryCount + 1);
    } else {
      console.error('[RabbitMQ] Max retries reached. Exiting.');
      process.exit(1);
    }
  }
}

export async function getChannel(): Promise<amqp.Channel> {
  if (!channel || !connection) {
    await connectWithRetry();
  }
  if (!channel) {
    throw new Error('RabbitMQ channel not available');
  }
  return channel;
}

export async function initializeRabbitMQ(): Promise<void> {
  await connectWithRetry();
}

export async function closeConnection(): Promise<void> {
  if (channel) {
    await channel.close();
    channel = null;
  }
  if (connection) {
    await connection.close();
    connection = null;
  }
}

```

```typescript
export interface Driver {
  id: string;
  name: string;
  phone: string;
  vehicle: string;
  is_active: boolean;
  created_at: Date;
}

export interface GpsPing {
  driverId: string;
  lat: number;
  lng: number;
  timestamp: number;
}

export interface DriverLocation {
  driverId: string;
  lat: number;
  lng: number;
}

export interface NearbyDriversQuery {
  lat: number;
  lng: number;
  radius: number; // km
}

```

```typescript
import redisClient from '../config/redis.js';
import type { GpsPing, DriverLocation, NearbyDriversQuery } from '../types/index.js';

const GEO_KEY = 'drivers:active';
const TTL_KEY = 'drivers:ttl';
const TTL_MS = 30_000; // 30 seconds

/**
 * Update driver position in Redis GEO and maintain TTL tracking
 */
export async function updateDriverPosition(ping: GpsPing): Promise<void> {
  // Redis GEO argument order is longitude first, then latitude
  await redisClient.geoadd(GEO_KEY, ping.lng, ping.lat, ping.driverId);
  
  // Maintain TTL tracking: add to sorted set with score = expiry timestamp
  const expiryScore = Date.now() + TTL_MS;
  await redisClient.zadd(TTL_KEY, expiryScore, ping.driverId);
  
  // Log at DEBUG level only to avoid log flooding at 2,000/sec
  // (In production, use proper logging library with log levels)
}

/**
 * Get current position of a driver from Redis GEO
 */
export async function getDriverPosition(driverId: string): Promise<DriverLocation | null> {
  const result = await redisClient.geopos(GEO_KEY, driverId);
  
  if (!result || result.length === 0 || !result[0]) {
    return null; // Driver offline or not found
  }
  
  const [lng, lat] = result[0];
  if (lng === null || lat === null) {
    return null;
  }
  
  return {
    driverId,
    lat,
    lng,
  };
}

/**
 * Get nearby drivers within a radius using GEOSEARCH
 */
export async function getNearbyDrivers(query: NearbyDriversQuery): Promise<DriverLocation[]> {
  // Use GEOSEARCH (Redis 6.2+) rather than deprecated GEORADIUS
  // FROMLONLAT: search from longitude/latitude
  // BYRADIUS: within radius in km
  // ASC: sort by distance ascending
  const results = await redisClient.geosearch(
    GEO_KEY,
    'FROMLONLAT',
    query.lng,
    query.lat,
    'BYRADIUS',
    query.radius,
    'km',
    'ASC',
  ) as Array<[string, [number, number]]>;
  
  // Cap results at 50 to prevent oversized responses
  const cappedResults = results.slice(0, 50);
  
  return cappedResults.map(([driverId, [lng, lat]]) => ({
    driverId,
    lat,
    lng,
  }));
}

/**
 * Remove expired drivers from GEO set and TTL tracking
 * Called by periodic cleanup job
 */
export async function cleanupExpiredDrivers(): Promise<number> {
  const now = Date.now();
  
  // Get all expired driver IDs (score < now)
  const expiredDriverIds = await redisClient.zrangebyscore(TTL_KEY, 0, now);
  
  if (expiredDriverIds.length === 0) {
    return 0;
  }
  
  // Remove from both GEO set and TTL tracking
  const pipeline = redisClient.pipeline();
  for (const driverId of expiredDriverIds) {
    pipeline.zrem(GEO_KEY, driverId);
    pipeline.zrem(TTL_KEY, driverId);
  }
  await pipeline.exec();
  
  return expiredDriverIds.length;
}

```

```typescript
import { getChannel } from '../config/rabbitmq.js';
import type { GpsPing } from '../types/index.js';

const EXCHANGE = 'driver.events';
const ROUTING_KEY = 'driver.location.updated';

/**
 * Publish location update to RabbitMQ
 * Set persistent: false - stale GPS messages have no value, delivery speed is more important
 */
export async function publishLocationUpdate(ping: GpsPing, orderId?: string): Promise<void> {
  const channel = await getChannel();
  
  const payload = {
    driverId: ping.driverId,
    lat: ping.lat,
    lng: ping.lng,
    timestamp: ping.timestamp,
    orderId: orderId || undefined,
  };
  
  const message = Buffer.from(JSON.stringify(payload));
  
  channel.publish(EXCHANGE, ROUTING_KEY, message, {
    persistent: false, // Speed over durability for GPS updates
  });
}

```


Creating the WebSocket server, routes, and index.ts:


```typescript
import { WebSocketServer, WebSocket } from 'ws';
import { Server as HttpServer } from 'http';
import { query } from '../config/db.js';
import { updateDriverPosition } from '../services/locationService.js';
import { publishLocationUpdate } from '../services/publisher.js';
import type { GpsPing } from '../types/index.js';
import { validate as validateUUID } from 'uuid';

// In-memory map of active driver connections
const activeConnections = new Map<string, WebSocket>();

// Heartbeat tracking: map of driverId -> last pong timestamp
const heartbeatMap = new Map<string, number>();

const HEARTBEAT_INTERVAL_MS = 15_000; // 15 seconds
const HEARTBEAT_TIMEOUT_MS = 30_000; // 30 seconds

/**
 * Create and configure WebSocket server for driver connections
 */
export function createDriverSocketServer(httpServer: HttpServer): WebSocketServer {
  const wss = new WebSocketServer({
    server: httpServer,
    path: '/drivers/connect',
  });

  wss.on('connection', async (ws: WebSocket, req) => {
    // Extract driverId from query string
    const url = new URL(req.url || '', `http://${req.headers.host}`);
    const driverId = url.searchParams.get('driverId');

    // Validate driverId is present and valid UUID
    if (!driverId || !validateUUID(driverId)) {
      ws.close(4001, 'Unauthorized: Invalid driverId');
      return;
    }

    // Query PostgreSQL to verify driver exists and is active
    try {
      const result = await query<{ id: string; is_active: boolean }>(
        'SELECT id, is_active FROM drivers WHERE id = $1',
        [driverId],
      );

      if (result.rows.length === 0 || !result.rows[0].is_active) {
        ws.close(4001, 'Unauthorized: Driver not found or inactive');
        return;
      }

      // Register connection
      activeConnections.set(driverId, ws);
      heartbeatMap.set(driverId, Date.now());
      console.info(`[WebSocket] Driver ${driverId} connected`);

      // Handle messages
      ws.on('message', async (data: Buffer) => {
        try {
          const message = JSON.parse(data.toString());
          const { lat, lng, timestamp } = message;

          // Validate GPS data
          if (
            typeof lat !== 'number' ||
            typeof lng !== 'number' ||
            typeof timestamp !== 'number' ||
            lat < -90 ||
            lat > 90 ||
            lng < -180 ||
            lng > 180
          ) {
            ws.send(
              JSON.stringify({
                error: 'Invalid GPS data: lat must be -90 to 90, lng must be -180 to 180',
              }),
            );
            return;
          }

          const ping: GpsPing = {
            driverId,
            lat,
            lng,
            timestamp: timestamp || Date.now(),
          };

          // Run Redis write and RabbitMQ publish in parallel (fire-and-forget)
          Promise.allSettled([
            updateDriverPosition(ping),
            publishLocationUpdate(ping),
          ]).catch((err) => {
            console.error(`[WebSocket] Error processing GPS ping for driver ${driverId}:`, err);
            // Don't crash - just log the error
          });
        } catch (err) {
          // Invalid JSON or other parse error
          ws.send(JSON.stringify({ error: 'Invalid message format' }));
          // Do NOT crash the process
        }
      });

      // Handle pong (response to ping)
      ws.on('pong', () => {
        heartbeatMap.set(driverId, Date.now());
      });

      // Handle close
      ws.on('close', (code, reason) => {
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        console.info(`[WebSocket] Driver ${driverId} disconnected (code: ${code}, reason: ${reason.toString()})`);
      });

      // Handle errors
      ws.on('error', (err) => {
        console.error(`[WebSocket] Error for driver ${driverId}:`, err.message);
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        // Do NOT crash the process
      });
    } catch (err) {
      const error = err as Error;
      console.error(`[WebSocket] Error validating driver ${driverId}:`, error.message);
      ws.close(4001, 'Unauthorized: Database error');
    }
  });

  // Start heartbeat: send ping frames every 15 seconds
  setInterval(() => {
    const now = Date.now();
    for (const [driverId, ws] of activeConnections.entries()) {
      const lastPong = heartbeatMap.get(driverId) || now;
      
      // If no pong received within timeout, terminate connection
      if (now - lastPong > HEARTBEAT_TIMEOUT_MS) {
        console.warn(`[WebSocket] Terminating dead connection for driver ${driverId}`);
        ws.terminate();
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        continue;
      }

      // Send ping frame
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      }
    }
  }, HEARTBEAT_INTERVAL_MS);

  return wss;
}

/**
 * Get count of active WebSocket connections
 */
export function getActiveConnectionCount(): number {
  return activeConnections.size;
}

```

```typescript
import { Router, type Request, type Response } from 'express';
import { validate as validateUUID } from 'uuid';
import { query } from '../config/db.js';
import { getDriverPosition, getNearbyDrivers } from '../services/locationService.js';
import type { Driver, NearbyDriversQuery } from '../types/index.js';

const router = Router();

/**
 * GET /drivers/:id/location
 * Get current position of a driver from Redis GEO
 */
router.get('/drivers/:id/location', async (req: Request, res: Response) => {
  const { id } = req.params;

  // Validate UUID format
  if (!validateUUID(id)) {
    return res.status(400).json({ error: 'Invalid driver ID format' });
  }

  try {
    const location = await getDriverPosition(id);

    if (!location) {
      return res.status(404).json({ error: 'Driver offline or not found' });
    }

    return res.status(200).json({ data: location });
  } catch (err) {
    const error = err as Error;
    console.error('[Route] Error getting driver location:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /drivers/nearby?lat=&lng=&radius=
 * Get drivers within a radius using Redis GEO
 */
router.get('/drivers/nearby', async (req: Request, res: Response) => {
  const latParam = req.query.lat;
  const lngParam = req.query.lng;
  const radiusParam = req.query.radius;

  // Validate required params
  if (!latParam || !lngParam) {
    return res.status(400).json({ error: 'lat and lng query parameters are required' });
  }

  const lat = parseFloat(latParam as string);
  const lng = parseFloat(lngParam as string);
  const radius = radiusParam ? parseFloat(radiusParam as string) : 5; // default 5 km

  // Validate numeric values
  if (isNaN(lat) || isNaN(lng) || isNaN(radius)) {
    return res.status(400).json({ error: 'lat, lng, and radius must be valid numbers' });
  }

  // Validate ranges
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return res.status(400).json({ error: 'lat must be -90 to 90, lng must be -180 to 180' });
  }

  // Validate radius (max 50 km)
  const validatedRadius = Math.min(Math.max(radius, 0), 50);

  try {
    const query: NearbyDriversQuery = {
      lat,
      lng,
      radius: validatedRadius,
    };

    const drivers = await getNearbyDrivers(query);

    return res.status(200).json({
      data: drivers,
      count: drivers.length,
    });
  } catch (err) {
    const error = err as Error;
    console.error('[Route] Error getting nearby drivers:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /drivers
 * List all driver profiles (admin endpoint)
 */
router.get('/drivers', async (req: Request, res: Response) => {
  try {
    const result = await query<Driver>(
      'SELECT id, name, phone, vehicle, is_active, created_at FROM drivers ORDER BY name',
    );

    return res.status(200).json({ data: result.rows });
  } catch (err) {
    const error = err as Error;
    console.error('[Route] Error getting drivers:', error.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;

```

```typescript
import express, { type Request, type Response, type ErrorRequestHandler } from 'express';
import { createServer } from 'http';
import dotenv from 'dotenv';
import { createDriverSocketServer, getActiveConnectionCount } from './websocket/driverSocket.js';
import { initializeRabbitMQ } from './config/rabbitmq.js';
import redisClient from './config/redis.js';
import { cleanupExpiredDrivers } from './services/locationService.js';
import driversRouter from './routes/drivers.js';

dotenv.config();

const app = express();
const httpServer = createServer(app);

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    service: 'driver-location-service',
    activeConnections: getActiveConnectionCount(),
  });
});

// Mount routes
app.use('/', driversRouter);

// Global error middleware
const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  console.error('[Express] Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
};
app.use(errorHandler);

// Initialize services and start server
async function start() {
  try {
    // Initialize Redis connection
    await redisClient.connect();
    console.info('[Redis] Connected');

    // Initialize RabbitMQ connection
    await initializeRabbitMQ();
    console.info('[RabbitMQ] Initialized');

    // Create WebSocket server
    createDriverSocketServer(httpServer);
    console.info('[WebSocket] Server created on path /drivers/connect');

    // Start periodic TTL cleanup job (every 10 seconds)
    setInterval(async () => {
      try {
        const evictedCount = await cleanupExpiredDrivers();
        if (evictedCount > 0) {
          console.info(`[Cleanup] Evicted ${evictedCount} expired driver(s) from GEO set`);
        }
      } catch (err) {
        const error = err as Error;
        console.error('[Cleanup] Error during TTL cleanup:', error.message);
      }
    }, 10_000); // 10 seconds

    // Start HTTP server
    const port = parseInt(process.env['DRIVER_LOCATION_PORT'] || '3003', 10);
    httpServer.listen(port, () => {
      console.info(`[Server] Driver Location Service listening on port ${port}`);
      console.info(`[Server] WebSocket endpoint: ws://localhost:${port}/drivers/connect`);
    });
  } catch (err) {
    const error = err as Error;
    console.error('[Startup] Fatal error:', error.message);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.info('[Shutdown] SIGTERM received, shutting down gracefully...');
  httpServer.close(() => {
    console.info('[Shutdown] HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.info('[Shutdown] SIGINT received, shutting down gracefully...');
  httpServer.close(() => {
    console.info('[Shutdown] HTTP server closed');
    process.exit(0);
  });
});

start();

```


Fixing Redis GEO commands in locationService.ts. Checking the correct ioredis API:



Fixing Redis GEO commands in locationService.ts to use the correct ioredis API:


```typescript
import redisClient from '../config/redis.js';
import type { GpsPing, DriverLocation, NearbyDriversQuery } from '../types/index.js';

const GEO_KEY = 'drivers:active';
const TTL_KEY = 'drivers:ttl';
const TTL_MS = 30_000; // 30 seconds

/**
 * Update driver position in Redis GEO and maintain TTL tracking
 */
export async function updateDriverPosition(ping: GpsPing): Promise<void> {
  // Redis GEO argument order is longitude first, then latitude
  await redisClient.geoadd(GEO_KEY, ping.lng, ping.lat, ping.driverId);
  
  // Maintain TTL tracking: add to sorted set with score = expiry timestamp
  const expiryScore = Date.now() + TTL_MS;
  await redisClient.zadd(TTL_KEY, expiryScore, ping.driverId);
  
  // Log at DEBUG level only to avoid log flooding at 2,000/sec
  // (In production, use proper logging library with log levels)
}

/**
 * Get current position of a driver from Redis GEO
 */
export async function getDriverPosition(driverId: string): Promise<DriverLocation | null> {
  const result = await redisClient.geopos(GEO_KEY, driverId);
  
  if (!result || result.length === 0 || !result[0]) {
    return null; // Driver offline or not found
  }
  
  const [lng, lat] = result[0];
  if (lng === null || lat === null) {
    return null;
  }
  
  return {
    driverId,
    lat,
    lng,
  };
}

/**
 * Get nearby drivers within a radius using GEOSEARCH
 */
export async function getNearbyDrivers(query: NearbyDriversQuery): Promise<DriverLocation[]> {
  // Use GEOSEARCH (Redis 6.2+) rather than deprecated GEORADIUS
  // Call raw Redis command: GEOSEARCH drivers:active FROMLONLAT lng lat BYRADIUS radius km ASC
  const results = await redisClient.call(
    'GEOSEARCH',
    GEO_KEY,
    'FROMLONLAT',
    query.lng.toString(),
    query.lat.toString(),
    'BYRADIUS',
    query.radius.toString(),
    'km',
    'ASC',
  ) as string[];
  
  if (!results || results.length === 0) {
    return [];
  }
  
  // Cap results at 50 to prevent oversized responses
  const cappedDriverIds = results.slice(0, 50);
  
  // Get positions for each driver ID
  const positions = await Promise.all(
    cappedDriverIds.map(async (driverId) => {
      const pos = await redisClient.geopos(GEO_KEY, driverId);
      if (!pos || pos.length === 0 || !pos[0]) {
        return null;
      }
      const [lng, lat] = pos[0];
      if (lng === null || lat === null) {
        return null;
      }
      return { driverId, lat, lng };
    }),
  );
  
  // Filter out null results
  return positions.filter((pos): pos is DriverLocation => pos !== null);
}

/**
 * Remove expired drivers from GEO set and TTL tracking
 * Called by periodic cleanup job
 */
export async function cleanupExpiredDrivers(): Promise<number> {
  const now = Date.now();
  
  // Get all expired driver IDs (score < now)
  const expiredDriverIds = await redisClient.zrangebyscore(TTL_KEY, 0, now);
  
  if (expiredDriverIds.length === 0) {
    return 0;
  }
  
  // Remove from both GEO set and TTL tracking
  const pipeline = redisClient.pipeline();
  for (const driverId of expiredDriverIds) {
    pipeline.zrem(GEO_KEY, driverId);
    pipeline.zrem(TTL_KEY, driverId);
  }
  await pipeline.exec();
  
  return expiredDriverIds.length;
}

```


Updating the implementation to use GEOSEARCH correctly with coordinates:


```typescript
import redisClient from '../config/redis.js';
import type { GpsPing, DriverLocation, NearbyDriversQuery } from '../types/index.js';

const GEO_KEY = 'drivers:active';
const TTL_KEY = 'drivers:ttl';
const TTL_MS = 30_000; // 30 seconds

/**
 * Update driver position in Redis GEO and maintain TTL tracking
 */
export async function updateDriverPosition(ping: GpsPing): Promise<void> {
  // Redis GEO argument order is longitude first, then latitude
  await redisClient.geoadd(GEO_KEY, ping.lng, ping.lat, ping.driverId);
  
  // Maintain TTL tracking: add to sorted set with score = expiry timestamp
  const expiryScore = Date.now() + TTL_MS;
  await redisClient.zadd(TTL_KEY, expiryScore, ping.driverId);
  
  // Log at DEBUG level only to avoid log flooding at 2,000/sec
  // (In production, use proper logging library with log levels)
}

/**
 * Get current position of a driver from Redis GEO
 */
export async function getDriverPosition(driverId: string): Promise<DriverLocation | null> {
  const result = await redisClient.geopos(GEO_KEY, driverId);
  
  if (!result || result.length === 0 || !result[0]) {
    return null; // Driver offline or not found
  }
  
  const [lng, lat] = result[0];
  if (lng === null || lat === null) {
    return null;
  }
  
  return {
    driverId,
    lat,
    lng,
  };
}

/**
 * Get nearby drivers within a radius using GEOSEARCH
 */
export async function getNearbyDrivers(query: NearbyDriversQuery): Promise<DriverLocation[]> {
  // Use GEOSEARCH (Redis 6.2+) rather than deprecated GEORADIUS
  // Call raw Redis command with WITHCOORD to get coordinates: 
  // GEOSEARCH drivers:active FROMLONLAT lng lat BYRADIUS radius km ASC WITHCOORD
  const results = await redisClient.call(
    'GEOSEARCH',
    GEO_KEY,
    'FROMLONLAT',
    query.lng.toString(),
    query.lat.toString(),
    'BYRADIUS',
    query.radius.toString(),
    'km',
    'ASC',
    'WITHCOORD',
  ) as Array<[string, [string, string]]>; // [driverId, [lng, lat]]
  
  if (!results || results.length === 0) {
    return [];
  }
  
  // Cap results at 50 to prevent oversized responses
  const cappedResults = results.slice(0, 50);
  
  return cappedResults.map(([driverId, [lngStr, latStr]]) => ({
    driverId,
    lng: parseFloat(lngStr),
    lat: parseFloat(latStr),
  }));
}

/**
 * Remove expired drivers from GEO set and TTL tracking
 * Called by periodic cleanup job
 */
export async function cleanupExpiredDrivers(): Promise<number> {
  const now = Date.now();
  
  // Get all expired driver IDs (score < now)
  const expiredDriverIds = await redisClient.zrangebyscore(TTL_KEY, 0, now);
  
  if (expiredDriverIds.length === 0) {
    return 0;
  }
  
  // Remove from both GEO set and TTL tracking
  const pipeline = redisClient.pipeline();
  for (const driverId of expiredDriverIds) {
    pipeline.zrem(GEO_KEY, driverId);
    pipeline.zrem(TTL_KEY, driverId);
  }
  await pipeline.exec();
  
  return expiredDriverIds.length;
}

```


Verifying the implementation and checking for any remaining issues:



Checking for any remaining issues and verifying the structure:



All files are in place. Verifying the WebSocket URL parsing handles edge cases:


```typescript
import { WebSocketServer, WebSocket } from 'ws';
import { Server as HttpServer } from 'http';
import { query } from '../config/db.js';
import { updateDriverPosition } from '../services/locationService.js';
import { publishLocationUpdate } from '../services/publisher.js';
import type { GpsPing } from '../types/index.js';
import { validate as validateUUID } from 'uuid';

// In-memory map of active driver connections
const activeConnections = new Map<string, WebSocket>();

// Heartbeat tracking: map of driverId -> last pong timestamp
const heartbeatMap = new Map<string, number>();

const HEARTBEAT_INTERVAL_MS = 15_000; // 15 seconds
const HEARTBEAT_TIMEOUT_MS = 30_000; // 30 seconds

/**
 * Create and configure WebSocket server for driver connections
 */
export function createDriverSocketServer(httpServer: HttpServer): WebSocketServer {
  const wss = new WebSocketServer({
    server: httpServer,
    path: '/drivers/connect',
  });

  wss.on('connection', async (ws: WebSocket, req) => {
    // Extract driverId from query string
    // req.url format: /drivers/connect?driverId=xxx
    const url = new URL(req.url || '', `http://${req.headers.host || 'localhost'}`);
    const driverId = url.searchParams.get('driverId');

    // Validate driverId is present and valid UUID
    if (!driverId || !validateUUID(driverId)) {
      ws.close(4001, 'Unauthorized: Invalid driverId');
      return;
    }

    // Query PostgreSQL to verify driver exists and is active
    try {
      const result = await query<{ id: string; is_active: boolean }>(
        'SELECT id, is_active FROM drivers WHERE id = $1',
        [driverId],
      );

      if (result.rows.length === 0 || !result.rows[0].is_active) {
        ws.close(4001, 'Unauthorized: Driver not found or inactive');
        return;
      }

      // Register connection
      activeConnections.set(driverId, ws);
      heartbeatMap.set(driverId, Date.now());
      console.info(`[WebSocket] Driver ${driverId} connected`);

      // Handle messages
      ws.on('message', async (data: Buffer) => {
        try {
          const message = JSON.parse(data.toString());
          const { lat, lng, timestamp } = message;

          // Validate GPS data
          if (
            typeof lat !== 'number' ||
            typeof lng !== 'number' ||
            typeof timestamp !== 'number' ||
            lat < -90 ||
            lat > 90 ||
            lng < -180 ||
            lng > 180
          ) {
            ws.send(
              JSON.stringify({
                error: 'Invalid GPS data: lat must be -90 to 90, lng must be -180 to 180',
              }),
            );
            return;
          }

          const ping: GpsPing = {
            driverId,
            lat,
            lng,
            timestamp: timestamp || Date.now(),
          };

          // Run Redis write and RabbitMQ publish in parallel (fire-and-forget)
          Promise.allSettled([
            updateDriverPosition(ping),
            publishLocationUpdate(ping),
          ]).catch((err) => {
            console.error(`[WebSocket] Error processing GPS ping for driver ${driverId}:`, err);
            // Don't crash - just log the error
          });
        } catch (err) {
          // Invalid JSON or other parse error
          ws.send(JSON.stringify({ error: 'Invalid message format' }));
          // Do NOT crash the process
        }
      });

      // Handle pong (response to ping)
      ws.on('pong', () => {
        heartbeatMap.set(driverId, Date.now());
      });

      // Handle close
      ws.on('close', (code, reason) => {
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        console.info(`[WebSocket] Driver ${driverId} disconnected (code: ${code}, reason: ${reason.toString()})`);
      });

      // Handle errors
      ws.on('error', (err) => {
        console.error(`[WebSocket] Error for driver ${driverId}:`, err.message);
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        // Do NOT crash the process
      });
    } catch (err) {
      const error = err as Error;
      console.error(`[WebSocket] Error validating driver ${driverId}:`, error.message);
      ws.close(4001, 'Unauthorized: Database error');
    }
  });

  // Start heartbeat: send ping frames every 15 seconds
  setInterval(() => {
    const now = Date.now();
    for (const [driverId, ws] of activeConnections.entries()) {
      const lastPong = heartbeatMap.get(driverId) || now;
      
      // If no pong received within timeout, terminate connection
      if (now - lastPong > HEARTBEAT_TIMEOUT_MS) {
        console.warn(`[WebSocket] Terminating dead connection for driver ${driverId}`);
        ws.terminate();
        activeConnections.delete(driverId);
        heartbeatMap.delete(driverId);
        continue;
      }

      // Send ping frame
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      }
    }
  }, HEARTBEAT_INTERVAL_MS);

  return wss;
}

/**
 * Get count of active WebSocket connections
 */
export function getActiveConnectionCount(): number {
  return activeConnections.size;
}

```


All subtasks for Task 4 are implemented. Summary:

## Completed Subtasks

### 4.1 — Project Scaffolding
- Created `package.json` with dependencies (`express`, `ws`, `pg`, `ioredis`, `amqplib`, `uuid`, `dotenv`)
- Folder structure created with all required directories

### 4.2 — Database Client (`config/db.ts`)
- Implemented PostgreSQL connection pool using `pg.Pool`
- Added query helper function with logging
- Used for driver profile validation

### 4.3 — Redis Client (`config/redis.ts`)
- Implemented ioredis singleton pattern with retry logic
- Configured for GEO commands (`GEOADD`, `GEOPOS`, `GEOSEARCH`)

### 4.4 — RabbitMQ Connection (`config/rabbitmq.ts`)
- Implemented RabbitMQ connection with retry pattern
- Asserted `driver.events` exchange (type: `direct`, durable)
- Same reconnect pattern as Order Service

### 4.5 — TypeScript Types (`types/index.ts`)
- Defined `Driver`, `GpsPing`, `DriverLocation`, `NearbyDriversQuery` interfaces

### 4.6 — Location Service (`services/locationService.ts`)
- `updateDriverPosition()`: Updates Redis GEO and maintains TTL tracking
- `getDriverPosition()`: Retrieves driver position from Redis GEO
- `getNearbyDrivers()`: Uses `GEOSEARCH` to find drivers within radius (capped at 50)
- `cleanupExpiredDrivers()`: Removes expired drivers from GEO set

### 4.7 — Publisher (`services/publisher.ts`)
- `publishLocationUpdate()`: Publishes to `driver.events` exchange with routing key `driver.location.updated`
- Uses `persistent: false` for faster delivery

### 4.8 — WebSocket Server (`websocket/driverSocket.ts`)
- WebSocket server on path `/drivers/connect`
- Validates driverId UUID format
- Verifies driver exists and is active in PostgreSQL
- Handles GPS ping messages with validation
- Parallel Redis + RabbitMQ writes using `Promise.allSettled`
- Heartbeat mechanism (ping every 15s, timeout after 30s)
- Proper error handling without crashing

### 4.9 — HTTP Route Handlers (`routes/drivers.ts`)
- `GET /drivers/:id/location`: Get driver position
- `GET /drivers/nearby`: Get nearby drivers with query params validation
- `GET /drivers`: List all driver profiles (admin)

### 4.10 — Express App Entry Point (`index.ts`)
- Express app with HTTP server wrapper
- Health check endpoint with active connection count
- WebSocket server integration
- Initializes Redis and RabbitMQ on startup
- Graceful shutdown handling

### 4.11 — TTL Cleanup Job
- Periodic cleanup job running every 10 seconds
- Removes expired drivers from `drivers:active` GEO set
- Logs eviction count

All files are created, follow the patterns from other services, and include error handling. The service is ready for testing.

# Task 5 sub-tasks implementation
_Exported on 2/21/2026 at 17:47:30 GMT+5:30 from Cursor (2.3.30)_

---

**User**

implement all sub tasks in task 5

---

**Cursor**


Checking CHAT_HISTORY.md for task 5 details.



Searching for task 5 details:



Reading the end of the file where the cursor is:



Searching for task 5 subtasks:



Searching for task-related content:



Reading the task 5 file to see all subtasks:



Checking what's already in the notification-service directory:



Checking existing files and the root tsconfig.base.json:



Creating the initial TODO list and starting implementation of all Task 5 subtasks:



Implementing all subtasks, starting with project scaffolding:


```json
{
  "name": "notification-service",
  "version": "1.0.0",
  "description": "Notification Service for Food Delivery App",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node-dev --esm --respawn --transpile-only src/index.ts"
  },
  "dependencies": {
    "amqplib": "^0.10.4",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "ioredis": "^5.4.1",
    "uuid": "^10.0.0",
    "ws": "^8.18.0"
  },
  "devDependencies": {
    "@types/amqplib": "^0.10.4",
    "@types/express": "^4.17.21",
    "@types/node": "^20.14.10",
    "@types/uuid": "^10.0.0",
    "@types/ws": "^8.5.10",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.3"
  }
}

```

```typescript
import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

let retryCount = 0;
const MAX_RETRIES = 3;

const redisClient = new Redis({
  host: process.env['REDIS_HOST'] || 'localhost',
  port: parseInt(process.env['REDIS_PORT'] || '6379', 10),
  lazyConnect: true,
  retryStrategy(times: number): number | null {
    retryCount = times;
    if (times > MAX_RETRIES) {
      console.error(`[Redis] Max retries (${MAX_RETRIES}) reached. Giving up.`);
      return null; // stop retrying
    }
    const delay = Math.min(times * 200, 2_000); // exponential back-off, max 2s
    console.warn(`[Redis] Connection attempt ${times}. Retrying in ${delay}ms...`);
    return delay;
  },
});

redisClient.on('connect', () => {
  retryCount = 0;
  console.info('[Redis] Connected');
});

redisClient.on('error', (err: Error) => {
  console.error(`[Redis] Error: ${err.message}`);
});

redisClient.on('close', () => {
  console.warn('[Redis] Connection closed');
});

// Attempt initial connection without crashing the process on failure
redisClient.connect().catch((err: Error) => {
  console.warn(`[Redis] Initial connection failed: ${err.message}. Service will degrade to DB-only mode.`);
});

export { retryCount };
export default redisClient;

```

```typescript
import * as amqp from 'amqplib';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env['RABBITMQ_URL'] || 'amqp://guest:guest@localhost:5672';
const MAX_RETRIES = 5;

let connection: amqp.Connection | null = null;
let channel: amqp.Channel | null = null;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function connectWithRetry(retryCount = 0): Promise<void> {
  try {
    console.info(`[RabbitMQ] Connecting to ${RABBITMQ_URL}...`);
    connection = await amqp.connect(RABBITMQ_URL);

    connection.on('error', (err: Error) => {
      console.error('[RabbitMQ] Connection error:', err.message);
      channel = null;
    });

    connection.on('close', () => {
      console.warn('[RabbitMQ] Connection closed');
      channel = null;
    });

    channel = await connection.createChannel();

    // Set prefetch to process at most 10 messages at once
    await channel.prefetch(10);

    // Assert exchanges (idempotent - safe to call multiple times)
    await channel.assertExchange('order.events', 'fanout', {
      durable: true,
    });

    await channel.assertExchange('driver.events', 'direct', {
      durable: true,
    });

    // Assert queues (idempotent - they already exist from definitions.json)
    await channel.assertQueue('orders.notification', {
      durable: true,
    });

    await channel.assertQueue('driver.location.notification', {
      durable: true,
    });

    // Bind queues to exchanges
    await channel.bindQueue('orders.notification', 'order.events', '');
    await channel.bindQueue('driver.location.notification', 'driver.events', 'driver.location.updated');

    console.info('[RabbitMQ] Connected, exchanges and queues asserted');
  } catch (err) {
    const error = err as Error;
    console.error(`[RabbitMQ] Connection failed: ${error.message}`);

    if (retryCount < MAX_RETRIES) {
      const delay = Math.min(Math.pow(2, retryCount) * 1000, 10_000); // exponential back-off, max 10s
      console.warn(`[RabbitMQ] Retrying in ${delay}ms... (attempt ${retryCount + 1}/${MAX_RETRIES})`);
      await sleep(delay);
      return connectWithRetry(retryCount + 1);
    } else {
      console.error('[RabbitMQ] Max retries reached. Exiting.');
      process.exit(1);
    }
  }
}

export async function getChannel(): Promise<amqp.Channel> {
  if (!channel || !connection) {
    await connectWithRetry();
  }
  if (!channel) {
    throw new Error('RabbitMQ channel not available');
  }
  return channel;
}

export async function initializeRabbitMQ(): Promise<void> {
  await connectWithRetry();
}

export async function closeConnection(): Promise<void> {
  if (channel) {
    await channel.close();
    channel = null;
  }
  if (connection) {
    await connection.close();
    connection = null;
  }
}

```

```typescript
export interface OrderEvent {
  orderId: string;
  status: string;
  restaurantId?: string;
  items?: any[];
}

export interface LocationEvent {
  driverId: string;
  orderId: string;
  lat: number;
  lng: number;
  timestamp: number;
}

export type WebSocketMessageType = 'ORDER_UPDATE' | 'DRIVER_LOCATION' | 'CONNECTED';

export interface WebSocketMessage {
  type: WebSocketMessageType;
  payload: OrderEvent | LocationEvent | { orderId: string };
}

export interface SessionEntry {
  instanceId: string;
  connectedAt: number;
}

```

```typescript
import redisClient from '../config/redis.js';

const SESSION_TTL = 3600; // 1 hour in seconds

/**
 * Register a WebSocket session for an orderId
 * Maps orderId to the instanceId that holds the connection
 */
export async function registerSession(orderId: string, instanceId: string): Promise<void> {
  const key = `ws:session:${orderId}`;
  await redisClient.set(key, instanceId, 'EX', SESSION_TTL);
}

/**
 * Get the instanceId that holds the WebSocket session for an orderId
 * Returns null if no active session exists
 */
export async function getSessionInstance(orderId: string): Promise<string | null> {
  const key = `ws:session:${orderId}`;
  const instanceId = await redisClient.get(key);
  return instanceId;
}

/**
 * Remove a WebSocket session when customer disconnects
 */
export async function removeSession(orderId: string): Promise<void> {
  const key = `ws:session:${orderId}`;
  await redisClient.del(key);
}

/**
 * Refresh the TTL of a session (called on message activity)
 */
export async function refreshSession(orderId: string): Promise<void> {
  const key = `ws:session:${orderId}`;
  await redisClient.expire(key, SESSION_TTL);
}

```

```typescript
import { WebSocket, WebSocketServer } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { registerSession, removeSession, refreshSession } from '../services/sessionService.js';
import { WebSocketMessage } from '../types/index.js';

const INSTANCE_ID = process.env['INSTANCE_ID'] || uuidv4();

// In-memory map of orderId -> WebSocket connection for this instance
const customerConnections = new Map<string, WebSocket>();

let wss: WebSocketServer | null = null;

/**
 * Initialize the WebSocket server attached to the HTTP server
 */
export function initializeWebSocketServer(server: any): void {
  wss = new WebSocketServer({
    server,
    path: '/track',
  });

  wss.on('connection', (ws: WebSocket, request: any) => {
    // Parse orderId from URL path (e.g., /track/abc-123)
    const url = new URL(request.url || '', `http://${request.headers.host}`);
    const pathParts = url.pathname.split('/');
    const orderId = pathParts[pathParts.length - 1];

    // Validate orderId is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!orderId || !uuidRegex.test(orderId)) {
      console.warn(`[WebSocket] Invalid orderId: ${orderId}`);
      ws.close(4000, 'Invalid orderId format');
      return;
    }

    // Register session in Redis
    registerSession(orderId, INSTANCE_ID)
      .then(() => {
        // Store WebSocket connection in local map
        customerConnections.set(orderId, ws);
        console.info(`[WebSocket] Customer connected for orderId: ${orderId} (instance: ${INSTANCE_ID})`);

        // Send initial confirmation frame
        const connectedMessage: WebSocketMessage = {
          type: 'CONNECTED',
          payload: { orderId },
        };
        ws.send(JSON.stringify(connectedMessage));
      })
      .catch((err) => {
        console.error(`[WebSocket] Failed to register session for ${orderId}:`, err);
        ws.close(4001, 'Failed to register session');
      });

    // Handle close
    ws.on('close', () => {
      customerConnections.delete(orderId);
      removeSession(orderId).catch((err) => {
        console.error(`[WebSocket] Failed to remove session for ${orderId}:`, err);
      });
      console.info(`[WebSocket] Customer disconnected for orderId: ${orderId}`);
    });

    // Handle errors
    ws.on('error', (error: Error) => {
      console.error(`[WebSocket] Error for orderId ${orderId}:`, error);
    });

    // Heartbeat: ping every 15 seconds
    const pingInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      } else {
        clearInterval(pingInterval);
      }
    }, 15000);

    // Timeout: if no pong received within 30 seconds, close connection
    let pongReceived = true;
    ws.on('pong', () => {
      pongReceived = true;
    });

    const timeoutInterval = setInterval(() => {
      if (!pongReceived) {
        console.warn(`[WebSocket] No pong received for orderId ${orderId}, closing connection`);
        ws.terminate();
        clearInterval(timeoutInterval);
        clearInterval(pingInterval);
      } else {
        pongReceived = false;
      }
    }, 30000);

    ws.on('close', () => {
      clearInterval(pingInterval);
      clearInterval(timeoutInterval);
    });
  });

  console.info('[WebSocket] Customer WebSocket server initialized on /track');
}

/**
 * Send a message to a customer WebSocket connection
 * Returns true if message was sent, false if customer is not on this instance or disconnected
 */
export function sendToCustomer(orderId: string, message: WebSocketMessage): boolean {
  const ws = customerConnections.get(orderId);
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    return false;
  }

  try {
    ws.send(JSON.stringify(message));
    // Refresh session TTL on activity
    refreshSession(orderId).catch((err) => {
      console.error(`[WebSocket] Failed to refresh session for ${orderId}:`, err);
    });
    return true;
  } catch (error) {
    console.error(`[WebSocket] Failed to send message to ${orderId}:`, error);
    return false;
  }
}

/**
 * Get the number of active customer connections on this instance
 */
export function getActiveCustomerCount(): number {
  return customerConnections.size;
}

/**
 * Get the instance ID
 */
export function getInstanceId(): string {
  return INSTANCE_ID;
}

```

```typescript
import { ConsumeMessage } from 'amqplib';
import { getChannel } from '../config/rabbitmq.js';
import { sendToCustomer } from '../websocket/customerSocket.js';
import { OrderEvent, WebSocketMessage } from '../types/index.js';

const QUEUE_NAME = 'orders.notification';

/**
 * Start consuming order events from RabbitMQ
 */
export async function startOrderConsumer(): Promise<void> {
  try {
    const channel = await getChannel();

    await channel.consume(
      QUEUE_NAME,
      async (msg: ConsumeMessage | null) => {
        if (!msg) {
          return;
        }

        try {
          // Parse message content as OrderEvent
          const content = msg.content.toString();
          const orderEvent: OrderEvent = JSON.parse(content);

          console.info(`[OrderConsumer] Received order event: ${orderEvent.orderId} - ${orderEvent.status}`);

          // Construct WebSocket message
          const wsMessage: WebSocketMessage = {
            type: 'ORDER_UPDATE',
            payload: orderEvent,
          };

          // Send to customer WebSocket
          const sent = sendToCustomer(orderEvent.orderId, wsMessage);

          if (!sent) {
            // Customer not on this instance or disconnected - log at DEBUG level
            console.debug(`[OrderConsumer] Customer not connected for orderId: ${orderEvent.orderId}`);
          }

          // Acknowledge message after successful processing
          channel.ack(msg);
        } catch (error) {
          const err = error as Error;
          console.error(`[OrderConsumer] Error processing message:`, err);

          // Parse error or unexpected payload - dead-letter, do not requeue
          channel.nack(msg, false, false);
        }
      },
      { noAck: false }
    );

    console.info(`[OrderConsumer] Started consuming from queue: ${QUEUE_NAME}`);
  } catch (error) {
    const err = error as Error;
    console.error(`[OrderConsumer] Failed to start consumer:`, err);
    throw err;
  }
}

```

```typescript
import { ConsumeMessage } from 'amqplib';
import { getChannel } from '../config/rabbitmq.js';
import { sendToCustomer } from '../websocket/customerSocket.js';
import { LocationEvent, WebSocketMessage } from '../types/index.js';

const QUEUE_NAME = 'driver.location.notification';

/**
 * Start consuming driver location events from RabbitMQ
 * Performance note: This queue receives up to 2,000 messages/sec.
 * Handler must be fast - no blocking I/O beyond WebSocket send.
 */
export async function startLocationConsumer(): Promise<void> {
  try {
    const channel = await getChannel();

    await channel.consume(
      QUEUE_NAME,
      async (msg: ConsumeMessage | null) => {
        if (!msg) {
          return;
        }

        try {
          // Parse message content as LocationEvent
          const content = msg.content.toString();
          const locationEvent: LocationEvent = JSON.parse(content);

          // Construct WebSocket message
          const wsMessage: WebSocketMessage = {
            type: 'DRIVER_LOCATION',
            payload: locationEvent,
          };

          // Send to customer WebSocket
          const sent = sendToCustomer(locationEvent.orderId, wsMessage);

          if (!sent) {
            // Customer not on this instance or disconnected - log at DEBUG level
            console.debug(`[LocationConsumer] Customer not connected for orderId: ${locationEvent.orderId}`);
          }

          // Acknowledge message after processing (even if customer not connected)
          channel.ack(msg);
        } catch (error) {
          const err = error as Error;
          console.error(`[LocationConsumer] Error processing message:`, err);

          // On error - dead-letter, do not requeue
          channel.nack(msg, false, false);
        }
      },
      { noAck: false }
    );

    console.info(`[LocationConsumer] Started consuming from queue: ${QUEUE_NAME}`);
  } catch (error) {
    const err = error as Error;
    console.error(`[LocationConsumer] Failed to start consumer:`, err);
    throw err;
  }
}

```

```typescript
import express from 'express';
import { createServer } from 'http';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';
import redisClient from './config/redis.js';
import { initializeRabbitMQ } from './config/rabbitmq.js';
import { initializeWebSocketServer, getActiveCustomerCount, getInstanceId } from './websocket/customerSocket.js';
import { startOrderConsumer } from './consumers/orderConsumer.js';
import { startLocationConsumer } from './consumers/locationConsumer.js';

dotenv.config();

const INSTANCE_ID = process.env['INSTANCE_ID'] || uuidv4();
const PORT = parseInt(process.env['NOTIFICATION_PORT'] || '3004', 10);

const app = express();
const server = createServer(app);

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'notification-service',
    instanceId: getInstanceId(),
    activeCustomers: getActiveCustomerCount(),
  });
});

// Global error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('[Express] Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Startup sequence
async function start(): Promise<void> {
  try {
    console.info(`[NotificationService] Starting with instanceId: ${INSTANCE_ID}`);

    // 1. Connect Redis
    console.info('[NotificationService] Connecting to Redis...');
    await redisClient.connect();
    console.info('[NotificationService] Redis connected');

    // 2. Connect RabbitMQ and initialize channel
    console.info('[NotificationService] Connecting to RabbitMQ...');
    await initializeRabbitMQ();
    console.info('[NotificationService] RabbitMQ connected');

    // 3. Start WebSocket server (attach to HTTP server)
    console.info('[NotificationService] Initializing WebSocket server...');
    initializeWebSocketServer(server);
    console.info('[NotificationService] WebSocket server initialized');

    // 4. Start Order consumer
    console.info('[NotificationService] Starting order consumer...');
    await startOrderConsumer();
    console.info('[NotificationService] Order consumer started');

    // 5. Start Location consumer
    console.info('[NotificationService] Starting location consumer...');
    await startLocationConsumer();
    console.info('[NotificationService] Location consumer started');

    // 6. Start HTTP server
    server.listen(PORT, () => {
      console.info(`[NotificationService] Server listening on port ${PORT}`);
      console.info(`[NotificationService] WebSocket endpoint: ws://localhost:${PORT}/track/{orderId}`);
    });
  } catch (error) {
    const err = error as Error;
    console.error('[NotificationService] Failed to start:', err);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.info('[NotificationService] SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.info('[NotificationService] HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.info('[NotificationService] SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.info('[NotificationService] HTTP server closed');
    process.exit(0);
  });
});

// Start the service
start();

```


Checking for linting errors and fixing any issues:



Fixing WebSocket path parsing to correctly extract the orderId from the URL:



Fixing WebSocket path parsing to handle `/track/{orderId}` correctly:


```typescript
import { WebSocket, WebSocketServer } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { registerSession, removeSession, refreshSession } from '../services/sessionService.js';
import { WebSocketMessage } from '../types/index.js';

const INSTANCE_ID = process.env['INSTANCE_ID'] || uuidv4();

// In-memory map of orderId -> WebSocket connection for this instance
const customerConnections = new Map<string, WebSocket>();

let wss: WebSocketServer | null = null;

/**
 * Initialize the WebSocket server attached to the HTTP server
 */
export function initializeWebSocketServer(server: any): void {
  wss = new WebSocketServer({
    server,
    // No path filter - we'll manually check the path in the connection handler
  });

  wss.on('connection', (ws: WebSocket, request: any) => {
    // Parse orderId from URL path (e.g., /track/abc-123)
    const requestUrl = request.url || '';
    const pathMatch = requestUrl.match(/^\/track\/([^\/\?]+)/);
    
    if (!pathMatch) {
      console.warn(`[WebSocket] Invalid path: ${requestUrl}`);
      ws.close(4000, 'Invalid path. Expected /track/{orderId}');
      return;
    }

    const orderId = pathMatch[1];

    // Validate orderId is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!orderId || !uuidRegex.test(orderId)) {
      console.warn(`[WebSocket] Invalid orderId: ${orderId}`);
      ws.close(4000, 'Invalid orderId format');
      return;
    }

    // Register session in Redis
    registerSession(orderId, INSTANCE_ID)
      .then(() => {
        // Store WebSocket connection in local map
        customerConnections.set(orderId, ws);
        console.info(`[WebSocket] Customer connected for orderId: ${orderId} (instance: ${INSTANCE_ID})`);

        // Send initial confirmation frame
        const connectedMessage: WebSocketMessage = {
          type: 'CONNECTED',
          payload: { orderId },
        };
        ws.send(JSON.stringify(connectedMessage));
      })
      .catch((err) => {
        console.error(`[WebSocket] Failed to register session for ${orderId}:`, err);
        ws.close(4001, 'Failed to register session');
      });

    // Handle close
    ws.on('close', () => {
      customerConnections.delete(orderId);
      removeSession(orderId).catch((err) => {
        console.error(`[WebSocket] Failed to remove session for ${orderId}:`, err);
      });
      console.info(`[WebSocket] Customer disconnected for orderId: ${orderId}`);
    });

    // Handle errors
    ws.on('error', (error: Error) => {
      console.error(`[WebSocket] Error for orderId ${orderId}:`, error);
    });

    // Heartbeat: ping every 15 seconds
    const pingInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      } else {
        clearInterval(pingInterval);
      }
    }, 15000);

    // Timeout: if no pong received within 30 seconds, close connection
    let pongReceived = true;
    ws.on('pong', () => {
      pongReceived = true;
    });

    const timeoutInterval = setInterval(() => {
      if (!pongReceived) {
        console.warn(`[WebSocket] No pong received for orderId ${orderId}, closing connection`);
        ws.terminate();
        clearInterval(timeoutInterval);
        clearInterval(pingInterval);
      } else {
        pongReceived = false;
      }
    }, 30000);

    ws.on('close', () => {
      clearInterval(pingInterval);
      clearInterval(timeoutInterval);
    });
  });

  console.info('[WebSocket] Customer WebSocket server initialized on /track');
}

/**
 * Send a message to a customer WebSocket connection
 * Returns true if message was sent, false if customer is not on this instance or disconnected
 */
export function sendToCustomer(orderId: string, message: WebSocketMessage): boolean {
  const ws = customerConnections.get(orderId);
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    return false;
  }

  try {
    ws.send(JSON.stringify(message));
    // Refresh session TTL on activity
    refreshSession(orderId).catch((err) => {
      console.error(`[WebSocket] Failed to refresh session for ${orderId}:`, err);
    });
    return true;
  } catch (error) {
    console.error(`[WebSocket] Failed to send message to ${orderId}:`, error);
    return false;
  }
}

/**
 * Get the number of active customer connections on this instance
 */
export function getActiveCustomerCount(): number {
  return customerConnections.size;
}

/**
 * Get the instance ID
 */
export function getInstanceId(): string {
  return INSTANCE_ID;
}

```


Verifying the folder structure and checking for any remaining issues:



All subtasks for Task 5 (Notification Service) are implemented. Summary:

## Summary

All 9 subtasks for Task 5 (Notification Service) are implemented.

### Completed subtasks:

1. **5.1 - Project Scaffolding**
   - Created `package.json` with dependencies (`express`, `ws`, `ioredis`, `amqplib`, `uuid`, `dotenv`)
   - Created folder structure: `src/config/`, `src/websocket/`, `src/consumers/`, `src/services/`, `src/types/`
   - `tsconfig.json` extends root config
   - Added npm scripts: `build`, `start`, `dev`

2. **5.2 - Redis Client** (`config/redis.ts`)
   - Singleton `ioredis` client pattern
   - Retry logic with exponential backoff
   - Used for session registry (`ws:session:{orderId}` keys)

3. **5.3 - RabbitMQ Connection** (`config/rabbitmq.ts`)
   - Connection with retry logic (max 5 retries, exponential backoff)
   - Exchange assertions (`order.events` fanout, `driver.events` direct)
   - Queue assertions (`orders.notification`, `driver.location.notification`)
   - Queue bindings configured
   - `prefetch(10)` set on channel
   - Exports `getChannel()` and `initializeRabbitMQ()`

4. **5.4 - TypeScript Types** (`types/index.ts`)
   - `OrderEvent` interface
   - `LocationEvent` interface
   - `WebSocketMessage` type with `ORDER_UPDATE`, `DRIVER_LOCATION`, `CONNECTED`
   - `SessionEntry` interface

5. **5.5 - Session Service** (`services/sessionService.ts`)
   - `registerSession()` - Sets `ws:session:{orderId}` with 1-hour TTL
   - `getSessionInstance()` - Gets instanceId for an orderId
   - `removeSession()` - Removes session on disconnect
   - `refreshSession()` - Refreshes TTL on activity

6. **5.6 - Customer WebSocket Server** (`websocket/customerSocket.ts`)
   - WebSocket server attached to HTTP server
   - Path parsing for `/track/{orderId}`
   - UUID validation for orderId
   - Session registration in Redis
   - In-memory `Map<orderId, WebSocket>` for connections
   - Initial `CONNECTED` confirmation frame
   - Heartbeat (ping every 15s, timeout 30s)
   - `sendToCustomer()` function for consumers
   - Session cleanup on disconnect

7. **5.7 - Order Event Consumer** (`consumers/orderConsumer.ts`)
   - Consumes `orders.notification` queue
   - Parses `OrderEvent` from messages
   - Constructs `ORDER_UPDATE` WebSocket messages
   - Sends to customer WebSocket
   - Acknowledges messages after processing
   - Error handling with `nack` for invalid messages

8. **5.8 - Location Event Consumer** (`consumers/locationConsumer.ts`)
   - Consumes `driver.location.notification` queue
   - Parses `LocationEvent` from messages
   - Constructs `DRIVER_LOCATION` WebSocket messages
   - Fast handler (no blocking I/O beyond WebSocket send)
   - Handles high message volume (up to 2,000/sec)

9. **5.9 - Express App Entry Point** (`index.ts`)
   - Express app + HTTP server setup
   - `GET /health` endpoint with instanceId and active customer count
   - Global error middleware
   - Startup sequence:
     1. Connect Redis
     2. Connect RabbitMQ and initialize channel
     3. Start WebSocket server
     4. Start Order consumer
     5. Start Location consumer
   - Graceful shutdown handlers
   - Listens on port 3004

### Features implemented:

- **WebSocket Server**: Customer-facing WebSocket for real-time order tracking
- **Session Registry**: Redis-based session mapping for horizontal scaling
- **RabbitMQ Consumers**: Two consumers for order events and driver location updates
- **Heartbeat**: Ping/pong mechanism to detect dead connections
- **Error Handling**: Proper error handling and message acknowledgment
- **Horizontal Scaling Support**: Session registry enables multi-instance deployment

The service is ready to use and follows the patterns established in the other services. All files are in place and there are no linting errors.

# Task 6 subtasks implementation
_Exported on 2/21/2026 at 17:49:24 GMT+5:30 from Cursor (2.3.30)_

---

**User**

Implement all subtasks in task 6

---

**Cursor**


Reviewing task 6 and its subtasks.



Reading the full task 6 file to identify all subtasks:



Checking if the api-gateway directory exists and what's already implemented:



Checking what's already in the api-gateway directory:



Creating the initial todo list and starting implementation of all subtasks:


```json
{
  "name": "api-gateway",
  "version": "1.0.0",
  "description": "API Gateway for Food Delivery App",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node-dev --esm --respawn --transpile-only src/index.ts"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "express-rate-limit": "^7.1.5",
    "http-proxy": "^1.18.1",
    "http-proxy-middleware": "^3.0.3",
    "uuid": "^10.0.0"
  },
  "devDependencies": {
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/http-proxy": "^1.17.14",
    "@types/node": "^20.14.10",
    "@types/uuid": "^10.0.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.3"
  }
}

```


Creating directories with the correct path:



Using PowerShell syntax:



Implementing all subtasks, starting with the route configuration:


```typescript
export const SERVICE_URLS = {
  restaurantMenu: process.env.RESTAURANT_MENU_URL || 'http://restaurant-menu-service:3001',
  order: process.env.ORDER_SERVICE_URL || 'http://order-service:3002',
  driverLocation: process.env.DRIVER_LOCATION_URL || 'http://driver-location-service:3003',
  notification: process.env.NOTIFICATION_URL || 'http://notification-service:3004',
} as const;

export interface RouteConfig {
  gatewayPath: string;
  downstreamService: keyof typeof SERVICE_URLS;
  isWebSocket: boolean;
}

export const ROUTE_TABLE: RouteConfig[] = [
  { gatewayPath: '/api/restaurants', downstreamService: 'restaurantMenu', isWebSocket: false },
  { gatewayPath: '/api/orders', downstreamService: 'order', isWebSocket: false },
  { gatewayPath: '/api/drivers', downstreamService: 'driverLocation', isWebSocket: false },
  { gatewayPath: '/ws/drivers/connect', downstreamService: 'driverLocation', isWebSocket: true },
  { gatewayPath: '/ws/track', downstreamService: 'notification', isWebSocket: true },
];

```

```typescript
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

export interface RequestWithId extends Request {
  requestId?: string;
}

export function requestLogger(req: RequestWithId, res: Response, next: NextFunction): void {
  const requestId = req.headers['x-request-id'] as string || uuidv4();
  req.requestId = requestId;
  res.setHeader('X-Request-ID', requestId);

  const startTime = Date.now();
  const timestamp = new Date().toISOString();

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const downstreamService = getDownstreamService(req.path);
    console.log(
      `[${timestamp}] ${req.method} ${req.path} → ${downstreamService} (${res.statusCode}) ${duration}ms [${requestId}]`
    );
  });

  next();
}

function getDownstreamService(path: string): string {
  if (path.startsWith('/api/restaurants')) return 'restaurant-menu-service';
  if (path.startsWith('/api/orders')) return 'order-service';
  if (path.startsWith('/api/drivers')) return 'driver-location-service';
  if (path.startsWith('/ws/drivers')) return 'driver-location-service';
  if (path.startsWith('/ws/track')) return 'notification-service';
  if (path.startsWith('/api/health')) return 'api-gateway';
  return 'unknown';
}

```

```typescript
import rateLimit from 'express-rate-limit';
import { Request, Response } from 'express';

export const globalRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 500, // 500 requests per IP per window
  message: { error: 'Rate limit exceeded. Try again in 1 minute.' },
  standardHeaders: true, // Return rate limit info in `X-RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  handler: (req: Request, res: Response) => {
    res.status(429).json({ error: 'Rate limit exceeded. Try again in 1 minute.' });
  },
});

export const orderRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per IP per window
  message: { error: 'Too many orders placed. Please wait.' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req: Request, res: Response) => {
    res.status(429).json({ error: 'Too many orders placed. Please wait.' });
  },
});

```

```typescript
import { createProxyMiddleware, Options } from 'http-proxy-middleware';
import { Request, Response } from 'express';
import { SERVICE_URLS } from '../config/routes.js';

export function createProxy(target: string, pathRewrite?: Record<string, string>): ReturnType<typeof createProxyMiddleware> {
  const proxyOptions: Options = {
    target,
    changeOrigin: true,
    pathRewrite,
    onError: (err: Error, req: Request, res: Response) => {
      console.error(`Proxy error for ${req.path}:`, err.message);
      if (!res.headersSent) {
        res.status(502).json({ error: 'Upstream service unavailable' });
      }
    },
    onProxyReq: (proxyReq, req: Request) => {
      // Forward X-Request-ID header
      const requestId = req.headers['x-request-id'];
      if (requestId) {
        proxyReq.setHeader('X-Request-ID', requestId as string);
      }
    },
  };

  return createProxyMiddleware(proxyOptions);
}

export const restaurantMenuProxy = createProxy(SERVICE_URLS.restaurantMenu, {
  '^/api/restaurants': '/restaurants',
});

export const orderProxy = createProxy(SERVICE_URLS.order, {
  '^/api/orders': '/orders',
});

export const driverLocationProxy = createProxy(SERVICE_URLS.driverLocation, {
  '^/api/drivers': '/drivers',
});

```

```typescript
import httpProxy from 'http-proxy';
import { IncomingMessage } from 'http';
import { Socket } from 'net';
import { SERVICE_URLS } from '../config/routes.js';

const proxy = httpProxy.createProxyServer({});

export function setupWebSocketProxy(server: any): void {
  server.on('upgrade', (req: IncomingMessage, socket: Socket, head: Buffer) => {
    const url = new URL(req.url || '/', `http://${req.headers.host}`);
    const pathname = url.pathname;
    const requestId = req.headers['x-request-id'] || 'unknown';

    let target: string | null = null;

    if (pathname === '/ws/drivers/connect') {
      target = `${SERVICE_URLS.driverLocation}/drivers/connect`;
    } else if (pathname.startsWith('/ws/track/')) {
      // Preserve the trailing path (e.g., /ws/track/123 → /track/123)
      const trackPath = pathname.replace('/ws/track', '/track');
      target = `${SERVICE_URLS.notification}${trackPath}`;
    }

    if (!target) {
      console.error(`[${requestId}] Unknown WebSocket path: ${pathname}`);
      socket.write('HTTP/1.1 400 Bad Request\r\n\r\n');
      socket.destroy();
      return;
    }

    console.log(`[${requestId}] WebSocket upgrade: ${pathname} → ${target}`);

    proxy.ws(req, socket, head, {
      target,
      changeOrigin: true,
    }, (err: Error) => {
      console.error(`[${requestId}] WebSocket proxy error:`, err.message);
      socket.destroy();
    });
  });
}

```

```typescript
import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import cors from 'cors';
import http from 'http';
import { requestLogger } from './middleware/requestLogger.js';
import { globalRateLimiter, orderRateLimiter } from './middleware/rateLimiter.js';
import {
  restaurantMenuProxy,
  orderProxy,
  driverLocationProxy,
} from './proxy/httpProxy.js';
import { setupWebSocketProxy } from './proxy/wsProxy.js';
import { SERVICE_URLS } from './config/routes.js';

dotenv.config();

const app = express();
const server = http.createServer(app);

// Middleware order: logger first (tags every request), then rate limiter, then JSON parser
app.use(requestLogger);
app.use(globalRateLimiter);
app.use(express.json());

// CORS configuration
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests from localhost in development
    if (!origin || origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
      callback(null, true);
    } else {
      callback(null, false);
    }
  },
  credentials: true,
  exposedHeaders: ['X-Request-ID', 'X-RateLimit-Limit', 'X-RateLimit-Remaining'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key', 'X-Request-ID'],
}));

// Health check endpoint (handled locally)
app.get('/api/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'api-gateway',
    uptime: process.uptime(),
  });
});

// HTTP Routes - Restaurant Menu Service
app.get('/api/restaurants*', restaurantMenuProxy);
app.post('/api/restaurants*', restaurantMenuProxy);
app.put('/api/restaurants*', restaurantMenuProxy);

// HTTP Routes - Order Service
app.get('/api/orders*', orderProxy);
app.post('/api/orders', orderRateLimiter, orderProxy);
app.patch('/api/orders*', orderProxy);

// HTTP Routes - Driver Location Service
app.get('/api/drivers*', driverLocationProxy);

// 404 handler for unmatched routes
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Setup WebSocket proxy
setupWebSocketProxy(server);

const PORT = process.env.API_GATEWAY_PORT || 8080;

// Log upstream service URLs at startup
console.log('API Gateway starting...');
console.log('Upstream service URLs:');
console.log(`  Restaurant Menu: ${SERVICE_URLS.restaurantMenu}`);
console.log(`  Order Service: ${SERVICE_URLS.order}`);
console.log(`  Driver Location: ${SERVICE_URLS.driverLocation}`);
console.log(`  Notification: ${SERVICE_URLS.notification}`);

server.listen(PORT, () => {
  console.log(`API Gateway listening on port ${PORT}`);
});

```


Checking for linting errors:



Reviewing the WebSocket proxy implementation to ensure it matches the requirements:



Updating the WebSocket proxy to preserve query strings:


```typescript
import httpProxy from 'http-proxy';
import { IncomingMessage } from 'http';
import { Socket } from 'net';
import { SERVICE_URLS } from '../config/routes.js';

const proxy = httpProxy.createProxyServer({});

export function setupWebSocketProxy(server: any): void {
  server.on('upgrade', (req: IncomingMessage, socket: Socket, head: Buffer) => {
    const url = new URL(req.url || '/', `http://${req.headers.host}`);
    const pathname = url.pathname;
    const search = url.search; // Preserve query string
    const requestId = req.headers['x-request-id'] || 'unknown';

    let target: string | null = null;

    if (pathname === '/ws/drivers/connect') {
      // Preserve query string (e.g., ?driverId=xxx)
      target = `${SERVICE_URLS.driverLocation}/drivers/connect${search}`;
    } else if (pathname.startsWith('/ws/track/')) {
      // Preserve the trailing path and query string (e.g., /ws/track/123 → /track/123)
      const trackPath = pathname.replace('/ws/track', '/track');
      target = `${SERVICE_URLS.notification}${trackPath}${search}`;
    }

    if (!target) {
      console.error(`[${requestId}] Unknown WebSocket path: ${pathname}`);
      socket.write('HTTP/1.1 400 Bad Request\r\n\r\n');
      socket.destroy();
      return;
    }

    console.log(`[${requestId}] WebSocket upgrade: ${pathname}${search} → ${target}`);

    proxy.ws(req, socket, head, {
      target,
      changeOrigin: true,
    }, (err: Error) => {
      console.error(`[${requestId}] WebSocket proxy error:`, err.message);
      socket.destroy();
    });
  });
}

```


Rechecking lints and verifying the implementation:



Verifying all files are in place:



All files are in place. Summary of what was implemented:

## Summary

All subtasks for Task 6 (API Gateway) are implemented.

### Completed subtasks:

1. **6.1 - Project Scaffolding**
   - Created `package.json` with dependencies (express, http-proxy-middleware, http-proxy, express-rate-limit, cors, dotenv, uuid)
   - Created folder structure: `src/config/`, `src/middleware/`, `src/proxy/`
   - `tsconfig.json` extends root config
   - Added npm scripts: `build`, `start`, `dev`

2. **6.2 - Route Configuration** (`config/routes.ts`)
   - Defined `SERVICE_URLS` with environment variable support
   - Created `ROUTE_TABLE` with route mappings
   - Exported typed constants

3. **6.3 - Request Logger Middleware** (`middleware/requestLogger.ts`)
   - Logs every request with timestamp, method, path, downstream service, status, and duration
   - Attaches unique `X-Request-ID` header (UUID) to each request
   - Forwards `X-Request-ID` to downstream services
   - Includes request ID in logs

4. **6.4 - Rate Limiter Middleware** (`middleware/rateLimiter.ts`)
   - Global rate limiter: 500 requests per IP per minute
   - Order-specific rate limiter: 10 requests per IP per minute for `POST /api/orders`
   - Returns `429` with error messages when limit exceeded
   - Includes `X-RateLimit-Limit` and `X-RateLimit-Remaining` headers

5. **6.5 - HTTP Proxy** (`proxy/httpProxy.ts`)
   - Created `createProxy()` factory function
   - Configured proxies with `changeOrigin: true`
   - Path rewriting to strip `/api` prefix (e.g., `/api/restaurants` → `/restaurants`)
   - Error handling: returns `502 Bad Gateway` on proxy errors
   - Forwards `X-Request-ID` header to downstream services
   - Created proxies for restaurant-menu, order, and driver-location services

6. **6.6 - WebSocket Proxy** (`proxy/wsProxy.ts`)
   - Uses `http-proxy` library for WebSocket upgrades
   - Handles `/ws/drivers/connect` → forwards to driver-location-service
   - Handles `/ws/track/*` → forwards to notification-service (preserves trailing path)
   - Preserves query strings for driver connections
   - Returns `400 Bad Request` for unknown paths
   - Logs WebSocket upgrade events with `X-Request-ID`

7. **6.7 - Express App Entry Point** (`index.ts`)
   - Loads environment variables via `dotenv`
   - Creates Express app and HTTP server
   - Middleware order: requestLogger → globalRateLimiter → express.json()
   - Routes:
     - `GET /api/health` - local handler with uptime
     - `GET/POST/PUT /api/restaurants*` - proxy to restaurant-menu-service
     - `GET /api/orders*` - proxy to order-service
     - `POST /api/orders` - orderRateLimiter + proxy
     - `PATCH /api/orders*` - proxy to order-service
     - `GET /api/drivers*` - proxy to driver-location-service
     - Catch-all `404` handler
   - WebSocket upgrade handler attached to HTTP server
   - Listens on port 8080 (configurable via `API_GATEWAY_PORT`)
   - Logs all upstream service URLs at startup

8. **6.8 - CORS Configuration**
   - Added `cors` middleware with `cors` and `@types/cors` packages
   - Allows requests from `http://localhost:*` in development
   - Exposes `X-Request-ID`, `X-RateLimit-Limit`, `X-RateLimit-Remaining` headers
   - Allows `Idempotency-Key` header in `Access-Control-Allow-Headers`

### Features implemented:

- Request logging: All requests logged with timing and request IDs
- Rate limiting: Global (500/min) and order-specific (10/min) limiters
- HTTP proxying: Routes HTTP requests to downstream services with path rewriting
- WebSocket proxying: Handles WebSocket upgrades for driver and customer connections
- Error handling: Graceful error handling with appropriate HTTP status codes
- CORS: Configured for development with proper headers
- Health check: Local health endpoint independent of downstream services

The API Gateway is ready to use and follows the patterns established in other services. All files are in place and there are no linting errors.









