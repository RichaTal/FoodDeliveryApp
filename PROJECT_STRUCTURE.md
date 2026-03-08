# Project Structure

This document explains the structure of the Food Delivery Application project and the purpose of each folder and key module.

## Table of Contents

1. [Root Directory Overview](#root-directory-overview)
2. [Services Directory](#services-directory)
3. [API Gateway](#api-gateway)
4. [Infrastructure Directory](#infrastructure-directory)
5. [Scripts Directory](#scripts-directory)
6. [Tasks Directory](#tasks-directory)
7. [Service-Specific Structure](#service-specific-structure)
8. [Key Modules and Their Purposes](#key-modules-and-their-purposes)

---

## Root Directory Overview

```
AIAssignmentFoodDeliveryApp/
├── api-gateway/              # API Gateway service
├── services/                 # Microservices directory
├── infra/                    # Infrastructure configuration files
├── scripts/                  # Utility and test scripts
├── tasks/                    # Task documentation
├── coverage/                 # Test coverage reports
├── docker-compose.yml        # Docker Compose configuration
├── package.json              # Root package.json (monorepo scripts)
├── tsconfig.base.json        # Base TypeScript configuration
├── ARCHITECTURE.md           # Architecture documentation
├── PERFORMANCE_ANALYSIS.md   # Performance analysis documentation
├── PERFORMANCE_OPTIMIZATIONS.md  # Performance optimization notes
├── COVERAGE.md               # Coverage documentation
└── RUN_AND_TEST.md          # Run and test instructions
```

---

## Services Directory

The `services/` directory contains all microservices that make up the food delivery platform. Each service is independently deployable and follows a consistent structure.

### Structure Pattern

Each service follows this standard structure:

```
service-name/
├── src/
│   ├── config/          # Configuration modules (DB, Redis, RabbitMQ, Swagger)
│   ├── routes/          # Express route handlers
│   ├── services/        # Business logic services
│   ├── types/           # TypeScript type definitions
│   ├── websocket/       # WebSocket handlers (if applicable)
│   └── index.ts         # Service entry point
├── coverage/            # Test coverage reports (generated)
├── API-SPECIFICATION.yml # OpenAPI specification
├── Dockerfile           # Docker image definition
├── jest.config.cjs      # Jest test configuration
├── package.json         # Service dependencies
└── tsconfig.json        # TypeScript configuration
```

---

## Service-Specific Structure

### 1. Restaurant Menu Service (`services/restaurant-menu-service/`)

**Purpose:** Manages restaurants, menu categories, and menu items. Provides fast menu browsing with Redis caching.

**Key Modules:**
- `src/config/` - Database (PostgreSQL), Redis, Swagger configuration
- `src/routes/restaurants.ts` - REST API endpoints for restaurants and menus
- `src/services/menuService.ts` - Business logic for menu operations and caching
- `src/types/index.ts` - TypeScript interfaces for restaurants, menus, items

**Responsibilities:**
- Restaurant CRUD operations
- Menu category and item management
- Menu caching strategy (Redis cache-aside pattern)
- Cache invalidation on menu updates

---

### 2. Order Service (`services/order-service/`)

**Purpose:** Handles order creation, validation, payment processing (mocked), and order status management.

**Key Modules:**
- `src/config/` - Database (PostgreSQL), Redis, RabbitMQ, Swagger configuration
- `src/routes/orders.ts` - REST API endpoints for orders
- `src/services/orderService.ts` - Core order processing logic
- `src/services/paymentStub.ts` - Mock payment gateway integration
- `src/services/publisher.ts` - RabbitMQ event publisher
- `src/services/restaurantClient.ts` - HTTP client for restaurant service communication
- `src/types/index.ts` - Order-related type definitions

**Responsibilities:**
- Order creation and validation
- Idempotency key management (Redis)
- Payment processing (mocked)
- Order status updates
- Publishing order events to RabbitMQ

---

### 3. Driver Location Service (`services/driver-location-service/`)

**Purpose:** Ingests real-time GPS pings from drivers, maintains live positions in Redis GEO, and provides driver location queries.

**Key Modules:**
- `src/config/` - Database (PostgreSQL), Redis, Kafka, Swagger configuration
- `src/routes/drivers.ts` - REST API endpoints for driver locations
- `src/services/locationService.ts` - GPS position management and Redis GEO operations
- `src/services/batchWriterService.ts` - Batch writes to PostgreSQL for path history
- `src/services/orderLookupService.ts` - Lookup service for driver-order associations
- `src/services/pathHistoryService.ts` - Driver path history management
- `src/services/publisher.ts` - RabbitMQ/Kafka event publisher for location updates
- `src/websocket/driverSocket.ts` - WebSocket server for driver GPS stream
- `src/types/index.ts` - Driver location type definitions

**Responsibilities:**
- WebSocket connection management for drivers
- Real-time GPS position ingestion (2,000 events/sec)
- Redis GEO operations (GEOADD, GEORADIUS, GEODIST)
- Driver path history storage (PostgreSQL batch writes)
- Publishing location updates to message broker

---

### 4. Notification Service (`services/notification-service/`)

**Purpose:** Consumes Kafka/RabbitMQ events and pushes real-time updates (order status, driver location) to customers via WebSocket.

**Key Modules:**
- `src/config/` - Redis, Kafka, Swagger configuration
- `src/consumers/locationConsumer.ts` - RabbitMQ consumer for driver location events
- `src/consumers/orderConsumer.ts` - RabbitMQ consumer for order events
- `src/services/sessionService.ts` - WebSocket session management (Redis registry)
- `src/websocket/customerSocket.ts` - WebSocket server for customer connections
- `src/types/index.ts` - Notification-related type definitions

**Responsibilities:**
- WebSocket connection management for customers
- Consuming order events from RabbitMQ
- Consuming driver location events from Kafka
- Routing messages to correct WebSocket instances (horizontal scaling)
- Session registry management in Redis

---

## API Gateway

**Location:** `api-gateway/`

**Purpose:** Single entry point for all client requests. Handles routing, rate limiting, and request logging.

**Structure:**
```
api-gateway/
├── src/
│   ├── config/
│   │   └── routes.ts          # Service routing configuration
│   ├── middleware/
│   │   ├── rateLimiter.ts     # Rate limiting middleware
│   │   └── requestLogger.ts   # Request logging middleware
│   ├── proxy/
│   │   ├── httpProxy.ts       # HTTP proxy implementation
│   │   └── wsProxy.ts         # WebSocket proxy implementation
│   └── index.ts               # Gateway entry point
├── Dockerfile
├── package.json
└── tsconfig.json
```

**Key Modules:**
- `src/config/routes.ts` - Defines routing rules for each microservice
- `src/middleware/rateLimiter.ts` - Rate limiting per client/IP
- `src/middleware/requestLogger.ts` - Request/response logging
- `src/proxy/httpProxy.ts` - HTTP request proxying to backend services
- `src/proxy/wsProxy.ts` - WebSocket connection proxying

**Responsibilities:**
- Route requests to appropriate microservices
- Apply rate limiting policies
- Log all incoming requests
- Proxy WebSocket connections for real-time features

---

## Infrastructure Directory

**Location:** `infra/`

**Purpose:** Contains infrastructure configuration files for databases, message brokers, and initialization scripts.

**Structure:**
```
infra/
├── postgres/
│   ├── init-all-databases.sh    # Master initialization script
│   ├── init.sql                 # Common initialization
│   ├── init-restaurant.sql      # Restaurant service schema
│   ├── init-order.sql           # Order service schema
│   ├── init-driver.sql          # Driver service schema
│   └── init-notification.sql    # Notification service schema (if needed)
└── rabbitmq/
    └── definitions.json          # RabbitMQ exchange/queue definitions
```

**Key Files:**
- `infra/postgres/init-all-databases.sh` - Orchestrates database initialization
- `infra/postgres/init-*.sql` - Service-specific database schemas
- `infra/rabbitmq/definitions.json` - RabbitMQ exchanges, queues, and bindings

**Responsibilities:**
- Database schema definitions
- Database initialization scripts
- Message broker configuration
- Infrastructure-as-code definitions

---

## Scripts Directory

**Location:** `scripts/`

**Purpose:** Utility scripts for testing, data generation, coverage reporting, and performance testing.

**Key Scripts:**

| Script | Purpose |
|--------|---------|
| `generate-drivers.js` | Generate test driver data for database |
| `generate-restaurants.js` | Generate test restaurant and menu data |
| `generate-api-specs.ts` | Generate OpenAPI specifications from code |
| `performance-test-driver-location.js` | Performance testing for driver location service |
| `performance-test-menu.js` | Performance testing for menu service |
| `performance-test-order.js` | Performance testing for order service |
| `coverage-all.js` | Aggregate test coverage across all services |
| `remove-all-restaurants.js` | Utility to clean up test restaurant data |
| `remove-bad-indexes.sql` | Database maintenance script |
| `setup-local-restaurant-db.ps1` | PowerShell script for local database setup |
| `split-databases.py` | Database splitting utility |
| `README-driver-location-simulator.md` | Documentation for driver location simulator |

**Responsibilities:**
- Test data generation
- Performance testing
- Coverage reporting
- Database maintenance
- API specification generation

---

## Tasks Directory

**Location:** `tasks/`

**Purpose:** Contains task documentation and implementation guides for each service.

**Structure:**
```
tasks/
├── README.md                      # Tasks overview
├── 01-infrastructure.md           # Infrastructure setup tasks
├── 02-restaurant-menu-service.md  # Restaurant service tasks
├── 03-order-service.md            # Order service tasks
├── 04-driver-location-service.md  # Driver location service tasks
├── 05-notification-service.md     # Notification service tasks
└── 06-api-gateway.md              # API gateway tasks
```

**Purpose:** Provides detailed implementation guides and requirements for each component of the system.

---

## Key Modules and Their Purposes

### Configuration Modules (`src/config/`)

Each service contains configuration modules that initialize external dependencies:

- **`db.ts`** - PostgreSQL database connection pool
- **`redis.ts`** - Redis client initialization
- **`rabbitmq.ts`** - RabbitMQ connection and channel setup
- **`kafka.ts`** - Kafka producer/consumer setup (driver-location-service)
- **`swagger.ts`** - OpenAPI/Swagger specification generation

### Route Modules (`src/routes/`)

Express route handlers that define REST API endpoints:

- **`restaurants.ts`** - Restaurant and menu endpoints
- **`orders.ts`** - Order management endpoints
- **`drivers.ts`** - Driver location endpoints

### Service Modules (`src/services/`)

Business logic layer that implements core functionality:

- **`menuService.ts`** - Menu caching and retrieval logic
- **`orderService.ts`** - Order processing, validation, payment
- **`locationService.ts`** - GPS position management, Redis GEO operations
- **`batchWriterService.ts`** - Batch writing to PostgreSQL for performance
- **`sessionService.ts`** - WebSocket session registry management
- **`publisher.ts`** - Message broker event publishing
- **`paymentStub.ts`** - Mock payment gateway
- **`restaurantClient.ts`** - HTTP client for inter-service communication

### WebSocket Modules (`src/websocket/`)

Real-time communication handlers:

- **`driverSocket.ts`** - WebSocket server for driver GPS stream
- **`customerSocket.ts`** - WebSocket server for customer notifications

### Consumer Modules (`src/consumers/`)

Message broker consumers (Notification Service):

- **`locationConsumer.ts`** - Consumes driver location update events
- **`orderConsumer.ts`** - Consumes order status change events

### Type Definitions (`src/types/`)

TypeScript type definitions and interfaces for each service's domain models.

---

## Common Patterns

### 1. Service Entry Point (`src/index.ts`)

Each service follows this pattern:
- Express app initialization
- Middleware setup (JSON parsing, CORS)
- Swagger UI configuration
- Health check endpoint
- Route registration
- External service initialization (DB, Redis, RabbitMQ)
- HTTP/WebSocket server startup
- Graceful shutdown handlers

### 2. Test Structure

Each service includes:
- `__tests__/` directories alongside source files
- Unit tests for services
- Integration tests for routes
- Configuration tests
- Test coverage reports in `coverage/`

### 3. Docker Configuration

Each service includes:
- `Dockerfile` for containerization
- Multi-stage builds for optimization
- Environment variable configuration
- Health check definitions

### 4. API Documentation

Each service includes:
- `API-SPECIFICATION.yml` - OpenAPI 3.0 specification
- Swagger UI at `/api-docs` endpoint
- Inline JSDoc comments for route documentation

---

## Database Organization

### PostgreSQL

Single PostgreSQL instance with separate database per service-

- **Restaurant Service:** `restaurants`, `menu_categories`, `menu_items` - DB: restaurant_db
- **Order Service:** `orders`, `order_items` -DB: orders_db
- **Driver Service:** `drivers`, `driver_path_history` - DB- driver_db

### Redis

Single Redis instance with namespaced keys:

- **Menu Cache:** `menu:{restaurantId}`
- **Idempotency:** `idempotency:{requestId}`
- **Driver Positions:** `drivers:active` (GEO set)
- **WebSocket Sessions:** `ws:session:{orderId}`

---

## Message Broker Organization

### RabbitMQ

- **Exchanges:**
  - `order.events` (Fanout) - Order lifecycle events

- **Queues:**
  - `orders.notification` - Order events for Notification Service
  - `driver.location.notification` - Location updates for Notification Service

---

## Port Allocation

| Service | Port |
|---------|------|
| Restaurant Menu Service | 3001 |
| Order Service | 3002 |
| Driver Location Service | 3003 |
| Notification Service | 3004 |
| API Gateway | 3000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| RabbitMQ | 5672 |
| RabbitMQ Management UI | 15672 |

---

## Development Workflow

1. **Local Development:**
   - Use `docker-compose.yml` to start infrastructure (PostgreSQL, Redis, RabbitMQ, Kafka)
   - Run services individually with `npm run dev` in each service directory
   - Use scripts in `scripts/` for test data generation

2. **Testing:**
   - Run tests: `npm test` (from root or individual service)
   - Coverage: `npm run test:coverage` (aggregated) or service-specific
   - Performance tests: Use scripts in `scripts/` directory

3. **API Documentation:**
   - Access Swagger UI at `http://localhost:{port}/api-docs` for each service
   - Generate specs: `npm run generate-api-specs`

4. **Deployment:**
   - Each service has its own `Dockerfile`
   - Use `docker-compose.yml` for local deployment
   - Services are independently deployable

---

## Key Design Principles

1. **Separation of Concerns:** Each service has a single, well-defined responsibility
2. **Consistency:** All services follow the same structural pattern
3. **Independence:** Services can be developed, tested, and deployed independently
4. **Scalability:** Each service can be scaled horizontally based on load
5. **Observability:** Health checks, logging, and API documentation in every service
6. **Testability:** Comprehensive test coverage with unit and integration tests

---

## Related Documentation

- **ARCHITECTURE.md** - Detailed architecture decisions and design rationale
- **PERFORMANCE_ANALYSIS.md** - Performance testing results and analysis
- **PERFORMANCE_OPTIMIZATIONS.md** - Optimization strategies implemented
- **COVERAGE.md** - Test coverage metrics and goals
- **RUN_AND_TEST.md** - Instructions for running and testing the application
