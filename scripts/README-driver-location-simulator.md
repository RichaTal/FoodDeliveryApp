# GPS Location Simulator for Driver Location Service

This directory contains scripts to simulate GPS location updates from multiple drivers for testing the Driver Location Service.

## Overview

The simulator tests the real-time logistics and analytics requirement:
- **Production Scale**: 10,000 concurrent drivers, each sending updates every 5 seconds (2,000 events/second peak load)
- **Local Testing**: Up to 50 drivers generating 10 events/second total

## Scripts

### 1. `performance-test-driver-location.js`

Main simulator script that connects multiple drivers via WebSocket and sends GPS location updates.

**Prerequisites:**
- Node.js 18+
- `ws` library installed: `npm install ws` (or `npm install -g ws`)
- Driver Location Service running (port 3003)
- Drivers must exist in database with `is_active=true`

**Basic Usage:**

```bash
# Local testing: 50 drivers, 10 events/sec total (default)
node scripts/performance-test-driver-location.js

# Production scale simulation: 1000 drivers, 200 events/sec
node scripts/performance-test-driver-location.js --drivers 1000 --events-per-sec 200

# Test via API Gateway
node scripts/performance-test-driver-location.js --gateway

# Extended test (5 minutes)
node scripts/performance-test-driver-location.js --duration 300
```

**Options:**
- `--base-url <url>` - Base URL for HTTP API (default: http://localhost:3003)
- `--ws-url <url>` - WebSocket URL (default: ws://localhost:3003)
- `--gateway` - Use API Gateway (ws://localhost:8080/ws/drivers/connect)
- `--drivers <n>` - Number of concurrent drivers (default: 50)
- `--events-per-sec <n>` - Target events per second (default: 10)
- `--update-interval <ms>` - GPS update interval per driver in ms (default: 5000)
- `--duration <s>` - Test duration in seconds (default: 60)
- `--help` - Show help message

**Note:** If you specify `--events-per-sec`, the script will automatically calculate the correct `--update-interval`. Similarly, if you specify `--update-interval`, it will calculate the expected `--events-per-sec`.

### 2. `generate-drivers.js`

Helper script to generate test driver records in the database.

**Prerequisites:**
- Node.js 18+
- `pg` library installed: `npm install pg`
- PostgreSQL database accessible

**Usage:**

```bash
# Generate 50 drivers (default)
node scripts/generate-drivers.js

# Generate 1000 drivers
node scripts/generate-drivers.js --count 1000

# Use custom database connection
node scripts/generate-drivers.js --db-url "postgresql://user:pass@localhost:5432/fooddelivery"
```

**Options:**
- `--count <n>` - Number of drivers to generate (default: 50)
- `--db-url <url>` - PostgreSQL connection URL (default: from env vars)
- `--help` - Show help message

**Environment Variables:**
The script uses standard PostgreSQL environment variables:
- `POSTGRES_HOST` (default: localhost)
- `POSTGRES_PORT` (default: 5432)
- `POSTGRES_DB` (default: fooddelivery)
- `POSTGRES_USER` (default: postgres)
- `POSTGRES_PASSWORD` (default: postgres)

## Quick Start

1. **Start services:**
   ```bash
   docker-compose up
   ```

2. **Generate test drivers (if needed):**
   ```bash
   node scripts/generate-drivers.js --count 50
   ```

3. **Run simulator:**
   ```bash
   node scripts/performance-test-driver-location.js
   ```

## How It Works

### GPS Coordinate Generation

The simulator generates realistic GPS coordinates using a random walk pattern:
- Each driver starts at a random position within ~5.5km of a city center (default: New York City)
- Each update moves the driver in a random direction at a realistic speed (~30 km/h)
- Drivers stay within a reasonable area around the city center
- Coordinates are clamped to valid GPS ranges (-90 to 90 for latitude, -180 to 180 for longitude)

### WebSocket Connection

- Each driver connects via WebSocket to `/drivers/connect?driverId=<uuid>`
- The service validates the driver exists and is active
- GPS updates are sent as JSON: `{ lat, lng, timestamp }`
- Updates are sent at the specified interval (default: every 5 seconds)

### Rate Calculation

For local testing with 50 drivers and 10 events/sec total:
- Update interval: (50 drivers / 10 events/sec) × 1000ms = 5000ms per driver
- Each driver sends 1 update every 5 seconds
- Total: 50 drivers × (1 update / 5 seconds) = 10 events/sec ✓

For production scale with 10,000 drivers and 2,000 events/sec:
- Update interval: (10,000 drivers / 2,000 events/sec) × 1000ms = 5000ms per driver
- Each driver sends 1 update every 5 seconds
- Total: 10,000 drivers × (1 update / 5 seconds) = 2,000 events/sec ✓

## Metrics

The simulator tracks:
- **Connection metrics**: Total, active, failed, closed connections
- **Message metrics**: Sent, responses, errors, actual rate
- **Latency statistics**: Min, P50, P95, P99, Max, Average

## Troubleshooting

**Error: "WebSocket library (ws) not found"**
```bash
npm install ws
# or
npm install -g ws
```

**Error: "No drivers could connect"**
- Ensure drivers exist in database with `is_active=true`
- Run `generate-drivers.js` to create test drivers
- Check that Driver Location Service is running on port 3003

**Error: "Could not get N driver IDs"**
- Generate more drivers: `node scripts/generate-drivers.js --count <n>`
- Check database connection and driver table exists

**Low event rate**
- Check that all drivers are connected successfully
- Verify WebSocket connections are stable (check for connection errors)
- Ensure Driver Location Service can handle the load

## Example Output

```
🚀 GPS Location Simulator for Driver Location Service
================================================================================

Simulating: 50 drivers sending GPS updates
Target: 10 events/second

Configuration:
   WebSocket URL:    ws://localhost:3003/drivers/connect
   Mode:             Direct Service
   Drivers:          50
   Update Interval:  5000ms per driver
   Duration:         60s
   Expected Rate:    10.00 events/sec

📋 Getting driver IDs...
   ✓ Using 50 existing drivers from database

🔌 Connecting 50 drivers...
   ✓ Connected: 50

🏃 Running test for 60 seconds...
📊 Elapsed: 60s / 60s | Remaining: 0s | Rate: 10.02 events/sec | Active: 50

🔌 Closing connections...

================================================================================
📊 GPS LOCATION SIMULATOR TEST RESULTS
================================================================================

📈 Test Configuration:
   WebSocket URL:    ws://localhost:3003/drivers/connect
   Mode:             Direct Service
   Drivers:          50
   Update Interval:  5000ms per driver
   Target Rate:      10 events/sec
   Duration:         60s
   Actual Duration:  60.12s

🔌 Connection Metrics:
   Total Connections: 50
   Active:            0
   Failed:            0
   Closed:            50

📨 Message Metrics:
   Messages Sent:     600
   Responses:         0
   Errors:            0
   Actual Rate:       9.98 events/sec

🎯 Requirement Check:
   ✅ PASS: Actual rate (9.98 events/sec) meets target (10 events/sec)
   ✅ PASS: Connection success rate (100.00%) meets requirement (≥95%)

================================================================================
```
