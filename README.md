# Food Delivery Application

A microservices-based food delivery platform designed to handle high-throughput order processing, low-latency menu browsing, and real-time GPS tracking of delivery drivers.

## 🎯 Project Overview

This application is built using a **microservices architecture** with an **event-driven core**, allowing each service to be scaled, deployed, and optimized independently based on its specific performance requirements.

### Key Features

- **Restaurant & Menu Management**: Fast menu browsing with Redis caching (P99 < 200ms)
- **Order Processing**: High-throughput order creation and management (500 orders/minute)
- **Real-Time Driver Tracking**: GPS ingestion from 10,000+ concurrent drivers (2,000 events/sec)
- **Customer Notifications**: Real-time order status and driver location updates via WebSocket
- **API Gateway**: Single entry point with rate limiting and request routing

### Architecture

The system consists of **4 core microservices** and an **API Gateway**:

| Service | Port | Responsibility |
|---------|------|----------------|
| **Restaurant Menu Service** | 3001 | Manage restaurants, menus, and serve menu data with caching |
| **Order Service** | 3002 | Accept, validate, and process orders; mock payment processing |
| **Driver Location Service** | 3003 | Ingest GPS pings from drivers; maintain live positions in Redis GEO |
| **Notification Service** | 3004 | Push real-time updates (location, order status) to customers |
| **API Gateway** | 8080 | Single entry point for all client requests |

### Technology Stack

- **Runtime**: Node.js with TypeScript
- **Database**: PostgreSQL 16 (separate database per service)
- **Cache**: Redis 7 (menu caching, idempotency keys, driver positions)
- **Message Broker**: RabbitMQ 3 (order events), Apache Kafka 3.7 (driver location events)
- **Containerization**: Docker & Docker Compose
- **API Documentation**: OpenAPI/Swagger

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your system:

1. **Docker** (version 20.10 or higher)
   - Download: https://www.docker.com/get-started
   - Verify installation: `docker --version`

2. **Docker Compose** (version 2.0 or higher)
   - Usually included with Docker Desktop
   - Verify installation: `docker-compose --version`

3. **Git** (for cloning the repository)
   - Download: https://git-scm.com/downloads

**System Requirements:**
- Minimum 8GB RAM (16GB recommended)
- At least 10GB free disk space
- CPU with virtualization support enabled

---

## 🚀 Step-by-Step Setup Instructions

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd AIAssignmentFoodDeliveryApp
```

### Step 2: Create Environment File

Create a `.env` file in the root directory of the project with the following content:

```env
# PostgreSQL Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_DB=postgres 
POSTGRES_PORT=5432

# Note: Each service uses its own database (restaurant_db, orders_db, driver_db, notification_db)
# created automatically by infra/postgres/init-all-databases.sh on first startup.

# Redis Configuration
REDIS_PORT=6379

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=admin123
RABBITMQ_URL=amqp://admin:admin123@rabbitmq:5672

# Service Ports
RESTAURANT_MENU_PORT=3001
ORDER_SERVICE_PORT=3002
DRIVER_LOCATION_PORT=3003
NOTIFICATION_PORT=3004
API_GATEWAY_PORT=8080

# Node Environment
NODE_ENV=development
```

**Important Notes:**
- The `.env` file is already in `.gitignore` and will not be committed to version control
- You can modify these values according to your local setup
- Ensure passwords are strong in production environments

### Step 3: Build and Start All Services

From the root directory, run the following command:

```bash
# Build and start all services (foreground mode - shows logs)
docker-compose up --build
```

**What happens during startup:**
1. Docker Compose creates a Docker network (`food-delivery-net`) for service communication
2. Creates persistent volumes for PostgreSQL and Redis data
3. Starts infrastructure services first:
   - PostgreSQL (with automatic database initialization)
   - Redis
   - RabbitMQ (with pre-configured exchanges and queues)
   - Kafka (with topic initialization)
4. Builds Docker images for all microservices and the API Gateway
5. Starts application services after infrastructure is healthy:
   - Restaurant Menu Service
   - Order Service
   - Driver Location Service
   - Notification Service
   - API Gateway

**Expected Output:**
```
Creating network "aiassignmentfooddeliveryapp_food-delivery-net" ...
Creating volume "aiassignmentfooddeliveryapp_postgres_data" ...
Creating volume "aiassignmentfooddeliveryapp_redis_data" ...
Creating postgres ... done
Creating redis ... done
Creating rabbitmq ... done
Creating kafka ... done
Creating kafka-init ... done
Building restaurant-menu-service ...
Building order-service ...
Building driver-location-service ...
Building notification-service ...
Building api-gateway ...
Creating restaurant-menu-service ... done
Creating order-service ... done
Creating driver-location-service ... done
Creating notification-service ... done
Creating api-gateway ... done
```

**Alternative: Run in Background Mode**

To run services in detached mode (background), use:

```bash
docker-compose up --build -d
```

This will start all services in the background. You can view logs later using `docker-compose logs -f`.

### Step 4: Verify Services Are Running

Open a new terminal window and check the status of all services:

```bash
# List all running containers with their status
docker-compose ps

# Check health status in a formatted table
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

You should see all services with status `healthy` or `running`. Wait a few moments if services are still starting up.

### Step 5: Test the Application

#### Health Check Endpoints

Test each service individually to ensure they're responding:

```bash
# API Gateway
curl http://localhost:8080/api/health

# Restaurant Menu Service
curl http://localhost:3001/health

# Order Service
curl http://localhost:3002/health

# Driver Location Service
curl http://localhost:3003/health

# Notification Service
curl http://localhost:3004/health
```

All endpoints should return `200 OK` with a JSON response indicating the service is healthy.

#### Access Service Documentation

Each service provides Swagger/OpenAPI documentation:

- **API Gateway Swagger**: http://localhost:8080/api-docs
- **Restaurant Menu Service**: http://localhost:3001/api-docs
- **Order Service**: http://localhost:3002/api-docs
- **Driver Location Service**: http://localhost:3003/api-docs
- **Notification Service**: http://localhost:3004/api-docs

#### Access Infrastructure Management UIs

- **RabbitMQ Management UI**: http://localhost:15672
  - Username: `admin`
  - Password: `admin123`

---

## 🛠️ Common Operations

### View Logs

```bash
# View logs for all services (follow mode)
docker-compose logs -f

# View logs for a specific service
docker-compose logs -f api-gateway
docker-compose logs -f order-service
docker-compose logs -f restaurant-menu-service
docker-compose logs -f driver-location-service
docker-compose logs -f notification-service

# View last 100 lines for a service
docker-compose logs --tail=100 restaurant-menu-service

# View logs without following
docker-compose logs
```

### Stop Services

```bash
# Stop all services (keeps containers)
docker-compose stop

# Stop and remove containers (keeps volumes - data persists)
docker-compose down

# Stop and remove containers + volumes (clean slate - deletes all data)
docker-compose down -v
```

**Warning:** `docker-compose down -v` will delete all database data and Redis cache. Use with caution!

### Restart a Specific Service

```bash
# Restart a service
docker-compose restart order-service

# Rebuild and restart a service (after code changes)
docker-compose up -d --build order-service
```

### Access Service Shells

```bash
# PostgreSQL shell (connect to restaurant database)
docker-compose exec postgres psql -U postgres -d restaurant_db

# PostgreSQL shell (connect to orders database)
docker-compose exec postgres psql -U postgres -d orders_db

# PostgreSQL shell (connect to driver database)
docker-compose exec postgres psql -U postgres -d driver_db

# Redis CLI
docker-compose exec redis redis-cli

# RabbitMQ management commands
docker-compose exec rabbitmq rabbitmqctl list_queues
docker-compose exec rabbitmq rabbitmqctl list_exchanges
```

### Check Service Health

```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready -U postgres

# Check Redis
docker-compose exec redis redis-cli ping
# Should return: PONG

# Check RabbitMQ
docker-compose exec rabbitmq rabbitmq-diagnostics ping
```

---

## 🧪 Testing the Application

### Generate Test Data

Before testing, you may want to generate test data:

```bash
# Generate test restaurants and menus
npm run generate-restaurants

# Generate test drivers
npm run generate-drivers
```

### Run Unit and Integration Tests

```bash
# Run all tests across all services
npm test

# Run tests with coverage
npm run test:coverage

# Run tests for a specific service
cd services/restaurant-menu-service && npm test
cd services/order-service && npm test
cd services/driver-location-service && npm test
cd services/notification-service && npm test
```

### Performance Testing

The project includes performance testing scripts:

```bash
# Test menu service performance (P99 < 200ms requirement)
npm run test-menu

# Test driver location service performance
npm run test-driver-location

# Test order service performance
npm run test-order
```

For detailed testing instructions and API examples, see [RUN_AND_TEST.md](./RUN_AND_TEST.md).

---

## 🐛 Troubleshooting

### Services Won't Start

**Problem**: Containers exit immediately or fail to start.

**Solutions**:
```bash
# Check logs for errors
docker-compose logs [service-name]

# Rebuild the service without cache
docker-compose build --no-cache [service-name]
docker-compose up -d [service-name]

# Check if ports are already in use (Windows)
netstat -ano | findstr :3001
netstat -ano | findstr :5432

# Check if ports are already in use (Linux/Mac)
lsof -i :3001
lsof -i :5432
```

### Database Connection Errors

**Problem**: Services can't connect to PostgreSQL.

**Solutions**:
```bash
# Verify PostgreSQL is running and healthy
docker-compose ps postgres
docker-compose exec postgres pg_isready -U postgres

# Check databases exist
docker-compose exec postgres psql -U postgres -l

# Restart PostgreSQL
docker-compose restart postgres

# Check PostgreSQL logs
docker-compose logs postgres
```

### Port Already in Use

**Problem**: Error message about ports being already in use.

**Solutions**:

1. **Find and stop the conflicting service**:
   ```bash
   # Windows - Find process using port
   netstat -ano | findstr :3001
   
   # Kill the process (replace PID with actual process ID)
   taskkill /PID <PID> /F
   ```

   ```bash
   # Linux/Mac - Find and kill process
   lsof -ti:3001 | xargs kill -9
   ```

2. **Or modify port mappings in `docker-compose.yml`**:
   ```yaml
   ports:
     - "30011:3001"  # Use different host port
   ```

### RabbitMQ Management UI Not Accessible

**Problem**: Can't access http://localhost:15672

**Solutions**:
```bash
# Check RabbitMQ is running
docker-compose ps rabbitmq

# Check RabbitMQ logs
docker-compose logs rabbitmq

# Verify port mapping
docker-compose ps --format "table {{.Name}}\t{{.Ports}}" | grep rabbitmq

# Restart RabbitMQ
docker-compose restart rabbitmq
```

### Kafka Topics Not Created

**Problem**: Driver location events not being processed.

**Solutions**:
```bash
# Check kafka-init container logs
docker-compose logs kafka-init

# Manually create topic
docker-compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic driver-location-events \
  --partitions 6 --replication-factor 1

# List existing topics
docker-compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list
```

### Clean Start (Remove Everything)

If you want to start completely fresh:

```bash
# Stop and remove all containers, networks, and volumes
docker-compose down -v

# Remove any orphaned containers
docker container prune -f

# Remove any orphaned volumes
docker volume prune -f

# Remove any orphaned networks
docker network prune -f

# Start fresh
docker-compose up --build
```

### Services Keep Restarting

**Problem**: Services start but then immediately restart in a loop.

**Solutions**:
```bash
# Check service logs for errors
docker-compose logs [service-name]

# Check if dependencies are healthy
docker-compose ps

# Verify environment variables are set correctly
docker-compose exec [service-name] env | grep POSTGRES
docker-compose exec [service-name] env | grep REDIS
```

---

## 📁 Project Structure

```
AIAssignmentFoodDeliveryApp/
├── api-gateway/              # API Gateway service
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── services/                 # Microservices directory
│   ├── restaurant-menu-service/
│   ├── order-service/
│   ├── driver-location-service/
│   └── notification-service/
├── infra/                    # Infrastructure configuration
│   ├── postgres/            # Database initialization scripts
│   │   ├── init-all-databases.sh
│   │   ├── init-restaurant.sql
│   │   ├── init-order.sql
│   │   ├── init-driver.sql
│   │   └── init-notification.sql
│   └── rabbitmq/            # RabbitMQ definitions
│       └── definitions.json
├── scripts/                 # Utility scripts
│   ├── generate-restaurants.js
│   ├── generate-drivers.js
│   ├── performance-test-*.js
│   └── coverage-all.js
├── docker-compose.yml       # Docker Compose configuration
├── package.json             # Root package.json
├── tsconfig.base.json       # Base TypeScript configuration
├── .env                     # Environment variables (create this)
└── README.md                # This file
```

For detailed project structure, see [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md).

---

## 📚 Additional Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Detailed architecture decisions and design rationale
- **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - Complete project structure and module explanations
- **[RUN_AND_TEST.md](./RUN_AND_TEST.md)** - Detailed testing and API usage instructions
- **[PERFORMANCE_ANALYSIS.md](./PERFORMANCE_ANALYSIS.md)** - Performance testing results and analysis
- **[PERFORMANCE_OPTIMIZATIONS.md](./PERFORMANCE_OPTIMIZATIONS.md)** - Optimization strategies implemented
- **[COVERAGE.md](./COVERAGE.md)** - Test coverage metrics and goals

---

## 🔗 Service URLs Summary

| Service | Direct Port | Gateway Path | Health Check |
|---------|-------------|--------------|--------------|
| API Gateway | 8080 | `/api/*`, `/ws/*` | http://localhost:8080/api/health |
| Restaurant Menu | 3001 | `/api/restaurants` | http://localhost:3001/health |
| Order Service | 3002 | `/api/orders` | http://localhost:3002/health |
| Driver Location | 3003 | `/api/drivers` | http://localhost:3003/health |
| Notification | 3004 | `/ws/track/*` | http://localhost:3004/health |
| RabbitMQ Management | 15672 | http://localhost:15672 | - |
| PostgreSQL | 5432 | (internal) | - |
| Redis | 6379 | (internal) | - |
| Kafka | 29092 | (internal) | - |

---

## ✅ Verification Checklist

After starting the application, verify everything is working:

### Infrastructure Services
- [ ] PostgreSQL is running: `docker-compose exec postgres pg_isready -U postgres`
- [ ] Redis is running: `docker-compose exec redis redis-cli ping` (should return `PONG`)
- [ ] RabbitMQ Management UI accessible: http://localhost:15672 (login: admin/admin123)
- [ ] Kafka is running: Check `docker-compose ps kafka`

### Application Services
- [ ] All services return `200 OK` on `/health` endpoints
- [ ] API Gateway proxies requests correctly
- [ ] Swagger UI accessible for all services
- [ ] WebSocket connections establish successfully

### Test Basic Functionality
- [ ] Create a restaurant via API
- [ ] Fetch restaurant menu (should be fast due to caching)
- [ ] Place an order (requires Idempotency-Key header)
- [ ] Check order status

---

## 🤝 Contributing

1. Follow the project structure conventions
2. Write tests for new features
3. Update API documentation (OpenAPI specs)
4. Ensure all tests pass before submitting

---

## 📝 License

[Add your license information here]

---

## 🆘 Support

For issues or questions:
1. Check the [Troubleshooting](#-troubleshooting) section above
2. Review the [Additional Documentation](#-additional-documentation)
3. Check service logs: `docker-compose logs [service-name]`
4. Verify all prerequisites are installed correctly

---

**Last Updated**: December 2024
