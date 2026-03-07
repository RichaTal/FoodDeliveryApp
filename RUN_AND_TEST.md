# Food Delivery App - Run & Test Guide

## Prerequisites

1. **Docker & Docker Compose** installed
2. **Create `.env` file** in the root directory with these variables:

```env
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_DB=food_delivery
POSTGRES_PORT=5432

# Redis
REDIS_PORT=6379

# RabbitMQ
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

---

## 🚀 Running the Application

### Start All Services (Recommended)

```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode (background)
docker-compose up --build -d

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f api-gateway
docker-compose logs -f order-service
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

### Check Service Status

```bash
# List running containers
docker-compose ps

# Check health of all services
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

---

## 🧪 Testing the Application

### 1. Health Check Endpoints

Test each service individually:

```bash
# API Gateway Health
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

### 2. Restaurant & Menu Service Tests

```bash
# List all restaurants
curl http://localhost:8080/api/restaurants

# Get restaurant menu (replace {restaurant-id} with actual UUID)
curl http://localhost:8080/api/restaurants/{restaurant-id}/menu

# Create a restaurant
curl -X POST http://localhost:8080/api/restaurants \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Pizza Palace",
    "address": "123 Main St",
    "lat": 40.7128,
    "lng": -74.0060
  }'

# Update menu item (replace {restaurant-id} and {item-id} with actual UUIDs)
curl -X PUT http://localhost:8080/api/restaurants/{restaurant-id}/menu-items/{item-id} \
  -H "Content-Type: application/json" \
  -d '{
    "price": 15.99,
    "is_available": true
  }'
```

### 3. Order Service Tests

```bash
# Place an order (REQUIRES Idempotency-Key header)
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{
    "restaurantId": "{restaurant-id}",
    "items": [
      {
        "menuItemId": "{menu-item-id}",
        "quantity": 2
      }
    ]
  }'

# Get order status (replace {order-id} with actual UUID)
curl http://localhost:8080/api/orders/{order-id}

# Update order status
curl -X PATCH http://localhost:8080/api/orders/{order-id}/status \
  -H "Content-Type: application/json" \
  -d '{
    "status": "CONFIRMED"
  }'
```

### 4. Driver Location Service Tests

```bash
# Get driver location (replace {driver-id} with actual UUID)
curl http://localhost:8080/api/drivers/{driver-id}/location

# Find nearby drivers
curl "http://localhost:8080/api/drivers/nearby?lat=40.7128&lng=-74.0060&radius=5000"
```

### 5. WebSocket Tests

#### Driver Connection (WebSocket)

```bash
# Using wscat (install: npm install -g wscat)
wscat -c "ws://localhost:8080/ws/drivers/connect?driverId={driver-id}"

# Send location update
{"lat": 40.7128, "lng": -74.0060}
```

#### Customer Tracking (WebSocket)

```bash
# Track order (replace {order-id} with actual UUID)
wscat -c "ws://localhost:8080/ws/track/{order-id}"
```

### 6. Rate Limiting Test

```bash
# Test rate limiting (should return 429 after 10 requests in 1 minute)
for i in {1..12}; do
  curl -X POST http://localhost:8080/api/orders \
    -H "Content-Type: application/json" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d '{"restaurantId": "test", "items": []}'
  echo "Request $i"
done
```

---

## 🔍 Verification Checklist

### Infrastructure Services

- [ ] **PostgreSQL**: `docker-compose exec postgres psql -U postgres -d food_delivery -c "\dt"`
- [ ] **Redis**: `docker-compose exec redis redis-cli ping` (should return `PONG`)
- [ ] **RabbitMQ Management**: Open http://localhost:15673 (login: admin/admin123)

### Application Services

- [ ] All services return `200 OK` on `/health` endpoints
- [ ] API Gateway proxies requests correctly
- [ ] WebSocket connections establish successfully
- [ ] Rate limiting works (429 after 10 requests)

---

## 🐛 Troubleshooting

### Services Not Starting

```bash
# Check logs
docker-compose logs [service-name]

# Rebuild specific service
docker-compose build [service-name]
docker-compose up -d [service-name]
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose exec postgres pg_isready -U postgres

# Check database exists
docker-compose exec postgres psql -U postgres -l
```

### RabbitMQ Issues

```bash
# Check RabbitMQ status
docker-compose exec rabbitmq rabbitmq-diagnostics ping

# View queues
docker-compose exec rabbitmq rabbitmqctl list_queues
```

### Port Conflicts

If ports are already in use, modify the port mappings in `docker-compose.yml` or stop conflicting services.

---

## 📝 Example Test Script

Save as `test-api.sh`:

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"

echo "=== Health Check ==="
curl -s "$BASE_URL/api/health" | jq .

echo -e "\n=== List Restaurants ==="
RESTAURANTS=$(curl -s "$BASE_URL/api/restaurants")
echo "$RESTAURANTS" | jq .
RESTAURANT_ID=$(echo "$RESTAURANTS" | jq -r '.data[0].id')

if [ "$RESTAURANT_ID" != "null" ]; then
  echo -e "\n=== Get Menu ==="
  curl -s "$BASE_URL/api/restaurants/$RESTAURANT_ID/menu" | jq .
fi

echo -e "\n=== Place Order ==="
IDEMPOTENCY_KEY=$(uuidgen)
curl -s -X POST "$BASE_URL/api/orders" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $IDEMPOTENCY_KEY" \
  -d "{\"restaurantId\": \"$RESTAURANT_ID\", \"items\": [{\"menuItemId\": \"test\", \"quantity\": 1}]}" | jq .
```

Make it executable: `chmod +x test-api.sh` and run: `./test-api.sh`

---

## 🔗 Service URLs Summary

| Service | Direct Port | Gateway Path |
|---------|-------------|--------------|
| API Gateway | 8080 | `/api/*`, `/ws/*` |
| Restaurant Menu | 3001 | `/api/restaurants` |
| Order Service | 3002 | `/api/orders` |
| Driver Location | 3003 | `/api/drivers` |
| Notification | 3004 | `/ws/track/*` |
| RabbitMQ Management | 15673 | http://localhost:15673 |
| PostgreSQL | 5432 | (internal) |
| Redis | 6379 | (internal) |

---

## ⚡ Performance Testing

### Menu & Restaurant Browse Performance Test

Test the P99 response time requirement (< 200ms) for fetching restaurant menus.

**Requirements:**
- Node.js 18+ (for native fetch API)
- Services running (`docker-compose up`)
- Restaurants in database (run `node scripts/generate-restaurants.js` first)

**Basic Usage:**

```bash
# Test via API Gateway (default) - Limited to 500 req/min
node scripts/performance-test-menu.js

# Test direct service (bypass gateway) - RECOMMENDED for high-load tests
node scripts/performance-test-menu.js --direct

# High load test (use --direct to avoid rate limiting)
node scripts/performance-test-menu.js --direct --concurrent 100 --requests 5000

# Quick test
node scripts/performance-test-menu.js --concurrent 10 --requests 100
```

**⚠️ Rate Limiting Note:**

- API Gateway has a rate limit of **500 requests per minute per IP**
- For high-load performance tests (1000+ requests), use `--direct` flag to bypass the gateway
- Testing direct service measures actual service performance without gateway overhead
- To disable rate limiting for testing, set `DISABLE_RATE_LIMIT=true` in your `.env` file

**Options:**
- `--base-url <url>` - Base URL (default: http://localhost:8080)
- `--direct` - Test direct service on port 3001 instead of gateway
- `--concurrent <n>` - Number of concurrent requests (default: 50)
- `--requests <n>` - Total number of requests (default: 1000)
- `--warmup <n>` - Warmup requests before test (default: 10)
- `--timeout <ms>` - Request timeout in ms (default: 5000)
- `--help` - Show help message

**Example Output:**

```
🚀 Restaurant Menu Performance Test
================================================================================

Testing: GET /restaurants/:id/menu
Target: P99 response time < 200ms

Configuration:
   Base URL:     http://localhost:8080
   Mode:         Via API Gateway
   Concurrent:   50
   Requests:     1000
   Timeout:      5000ms

📋 Fetching restaurant IDs...
   Found 50 restaurants

🔥 Warming up with 10 requests...

🏃 Running performance test...
📊 Progress: 1000/1000 requests (100.0%)

================================================================================
📊 PERFORMANCE TEST RESULTS
================================================================================

📈 Test Configuration:
   Base URL:        http://localhost:8080
   Mode:            Via API Gateway
   Concurrent:      50
   Total Requests:  1000
   Duration:        12.45s
   Throughput:      80.32 req/s

✅ Success Metrics:
   Successful:      1000 (100.00%)
   Failed:          0 (0.00%)

⏱️  Response Time Statistics:
   Min:             45.23ms
   P50 (Median):    78.45ms
   P95:             125.67ms
   P99:             185.23ms ✅ (target: < 200ms)
   P99.9:           198.45ms
   Max:             210.12ms
   Average:         79.12ms

🎯 P99 Requirement Check:
   ✅ PASS: P99 latency (185.23ms) is under 200ms

💾 Cache Statistics:
   Cache Hits:      850 (85.00%)
   Cache Misses:    150 (15.00%)

📡 HTTP Status Codes:
   200:           1000
================================================================================
```

**Exit Codes:**
- `0` - Test passed (P99 < 200ms)
- `1` - Test failed (P99 >= 200ms) or error occurred