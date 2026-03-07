#!/usr/bin/env node

/**
 * GPS Location Simulator for Driver Location Service
 * 
 * Simulates GPS location updates from multiple drivers via WebSocket.
 * 
 * Requirements:
 *   - Node.js 18+ (for native fetch API and WebSocket support)
 *   - Services must be running (docker-compose up)
 *   - Driver Location Service must be running on port 3003
 *   - Drivers must exist in database (at least as many as --drivers count)
 * 
 * Usage:
 *   node scripts/performance-test-driver-location.js [options]
 * 
 * Examples:
 *   # Local testing: 50 drivers, 10 events/sec total (default)
 *   node scripts/performance-test-driver-location.js
 * 
 *   # Production scale simulation: 1000 drivers, 200 events/sec
 *   node scripts/performance-test-driver-location.js --drivers 1000 --events-per-sec 200
 * 
 *   # Test via API Gateway
 *   node scripts/performance-test-driver-location.js --gateway
 * 
 *   # Extended test (5 minutes)
 *   node scripts/performance-test-driver-location.js --duration 300
 * 
 * Options:
 *   --base-url <url>        Base URL for HTTP API (default: http://localhost:3003)
 *   --ws-url <url>          WebSocket URL (default: ws://localhost:3003)
 *   --gateway               Use API Gateway (ws://localhost:8080/ws/drivers/connect)
 *   --drivers <n>           Number of concurrent drivers (default: 50)
 *   --events-per-sec <n>     Target events per second (default: 10)
 *   --update-interval <ms>  GPS update interval per driver in ms (default: 5000)
 *   --duration <s>          Test duration in seconds (default: 60)
 *   --generate-drivers      Generate driver records if needed (requires DB access)
 *   --help                  Show this help message
 */

// Try to use ws library (required for Node.js compatibility)
let WebSocket;
try {
  WebSocket = require('ws');
} catch (err) {
  console.error('\n❌ Error: WebSocket library (ws) not found.');
  console.error('   Please install: npm install ws');
  console.error('   Or: npm install -g ws');
  process.exit(1);
}

const BASE_URL_DEFAULT = 'http://localhost:3003';
const WS_URL_DEFAULT = 'ws://localhost:3003/drivers/connect';
const GATEWAY_WS_URL = 'ws://localhost:8080/ws/drivers/connect';

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  baseUrl: BASE_URL_DEFAULT,
  wsUrl: WS_URL_DEFAULT,
  gateway: false,
  drivers: 50, // Local testing default
  eventsPerSec: 10, // Local testing default (10 events/sec total)
  updateInterval: 5000, // 5 seconds per driver
  duration: 60, // seconds
  generateDrivers: false,
};

// Track which options were explicitly set
const explicitOptions = {
  eventsPerSec: false,
  updateInterval: false,
};

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--help' || arg === '-h') {
    const helpText = require('fs').readFileSync(__filename, 'utf8').match(/\/\*\*[\s\S]*?\*\//);
    if (helpText) {
      console.log(helpText[0]);
    }
    process.exit(0);
  } else if (arg === '--gateway') {
    options.gateway = true;
    options.baseUrl = 'http://localhost:8080';
    options.wsUrl = GATEWAY_WS_URL;
  } else if (arg === '--base-url' && args[i + 1]) {
    options.baseUrl = args[++i];
  } else if (arg === '--ws-url' && args[i + 1]) {
    options.wsUrl = args[++i];
  } else if (arg === '--drivers' && args[i + 1]) {
    options.drivers = parseInt(args[++i], 10);
  } else if (arg === '--events-per-sec' && args[i + 1]) {
    options.eventsPerSec = parseInt(args[++i], 10);
    explicitOptions.eventsPerSec = true;
  } else if (arg === '--update-interval' && args[i + 1]) {
    options.updateInterval = parseInt(args[++i], 10);
    explicitOptions.updateInterval = true;
  } else if (arg === '--duration' && args[i + 1]) {
    options.duration = parseInt(args[++i], 10);
  } else if (arg === '--generate-drivers') {
    options.generateDrivers = true;
  }
}

// Auto-calculate missing values after all arguments are parsed
if (explicitOptions.eventsPerSec && !explicitOptions.updateInterval) {
  // Calculate update interval from events per second
  if (options.drivers > 0 && options.eventsPerSec > 0) {
    options.updateInterval = Math.round((options.drivers / options.eventsPerSec) * 1000);
  }
} else if (explicitOptions.updateInterval && !explicitOptions.eventsPerSec) {
  // Calculate events per second from update interval
  if (options.drivers > 0 && options.updateInterval > 0) {
    options.eventsPerSec = Math.round((options.drivers * 1000) / options.updateInterval);
  }
}

// Performance metrics
const metrics = {
  connections: {
    total: 0,
    active: 0,
    failed: 0,
    closed: 0,
  },
  messages: {
    sent: 0,
    errors: 0,
    responses: 0,
  },
  latencies: [],
  startTime: null,
  endTime: null,
};

// Driver state tracking
const drivers = new Map(); // driverId -> { ws, lat, lng, interval, connected }

/**
 * Generate a UUID v4 (simple implementation for testing)
 */
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Generate realistic GPS coordinates around a city center
 * Uses a simple random walk pattern to simulate driver movement
 */
class GPSGenerator {
  constructor(centerLat = 40.7128, centerLng = -74.0060) {
    // Default: New York City coordinates
    this.centerLat = centerLat;
    this.centerLng = centerLng;
    this.radius = 0.05; // ~5.5km radius
  }

  /**
   * Generate initial position for a driver
   */
  getInitialPosition() {
    const angle = Math.random() * 2 * Math.PI;
    const distance = Math.random() * this.radius;
    return {
      lat: this.centerLat + distance * Math.cos(angle),
      lng: this.centerLng + distance * Math.sin(angle),
    };
  }

  /**
   * Generate next position based on current position (simulates movement)
   */
  getNextPosition(currentLat, currentLng, speedKmh = 30) {
    // Convert speed to degrees per update interval
    // Assuming 5 second updates: speedKmh * (5/3600) hours = distance in km
    const distanceKm = (speedKmh * options.updateInterval) / 3600;
    const distanceDeg = distanceKm / 111; // ~111 km per degree latitude
    
    // Random direction
    const angle = Math.random() * 2 * Math.PI;
    
    // Add some randomness to speed (0.5x to 1.5x)
    const actualDistance = distanceDeg * (0.5 + Math.random());
    
    let newLat = currentLat + actualDistance * Math.cos(angle);
    let newLng = currentLng + actualDistance * Math.sin(angle);
    
    // Keep within reasonable bounds (stay near city center)
    const maxDistance = this.radius * 1.5;
    const distFromCenter = Math.sqrt(
      Math.pow(newLat - this.centerLat, 2) + Math.pow(newLng - this.centerLng, 2)
    );
    
    if (distFromCenter > maxDistance) {
      // Move back toward center
      const angleToCenter = Math.atan2(
        this.centerLat - newLat,
        this.centerLng - newLng
      );
      newLat = this.centerLat + maxDistance * 0.8 * Math.cos(angleToCenter);
      newLng = this.centerLng + maxDistance * 0.8 * Math.sin(angleToCenter);
    }
    
    // Clamp to valid GPS ranges
    newLat = Math.max(-90, Math.min(90, newLat));
    newLng = Math.max(-180, Math.min(180, newLng));
    
    return { lat: newLat, lng: newLng };
  }
}

/**
 * Fetch existing drivers from the database via API
 */
async function fetchDrivers(baseUrl) {
  // Note: This assumes there's an endpoint to list drivers
  // If not available, we'll generate driver IDs
  try {
    // Try /drivers endpoint first (matches the route in drivers.ts)
    const url = `${baseUrl}/drivers`;
    const response = await fetch(url, {
      signal: AbortSignal.timeout(5000),
    });
    
    if (response.ok) {
      const data = await response.json();
      const driverList = data.data || data || [];
      // Filter to only active drivers (required for WebSocket connection)
      return driverList
        .filter(d => d.is_active === true)
        .map(d => d.id)
        .filter(Boolean);
    }
  } catch (error) {
    // API endpoint might not exist, that's okay
    console.warn(`   ⚠ Could not fetch drivers from API: ${error.message}`);
  }
  
  return [];
}

/**
 * Generate driver IDs (either fetch from DB or generate)
 */
async function getDriverIds(count, baseUrl) {
  const existingDrivers = await fetchDrivers(baseUrl);
  
  if (existingDrivers.length >= count) {
    console.log(`   ✓ Using ${count} existing drivers from database`);
    return existingDrivers.slice(0, count);
  }
  
  if (existingDrivers.length > 0) {
    console.log(`   ⚠ Only ${existingDrivers.length} drivers found, generating ${count - existingDrivers.length} more`);
  } else {
    console.log(`   ⚠ No drivers found in database, generating ${count} driver IDs`);
    console.log(`   Note: These drivers must exist in the database with is_active=true`);
  }
  
  // Generate remaining driver IDs
  const generated = [];
  for (let i = 0; i < count - existingDrivers.length; i++) {
    generated.push(generateUUID());
  }
  
  return [...existingDrivers, ...generated];
}

/**
 * Connect a single driver via WebSocket and start sending GPS updates
 */
function connectDriver(driverId, gpsGenerator) {
  return new Promise((resolve) => {
    // Ensure the WebSocket URL includes the path and query parameter
    const wsUrl = options.wsUrl.includes('?') 
      ? `${options.wsUrl}&driverId=${driverId}`
      : `${options.wsUrl}?driverId=${driverId}`;
    const ws = new WebSocket(wsUrl);
    
    let position = gpsGenerator.getInitialPosition();
    let intervalId = null;
    let connected = false;
    let resolved = false;
    
    // Connection timeout (10 seconds)
    const connectionTimeout = setTimeout(() => {
      if (!connected && !resolved) {
        resolved = true;
        metrics.connections.failed++;
        ws.terminate();
        resolve({ success: false, driverId, error: 'Connection timeout' });
      }
    }, 10000);
    
    ws.on('open', () => {
      if (resolved) return;
      resolved = true;
      clearTimeout(connectionTimeout);
      connected = true;
      metrics.connections.active++;
      metrics.connections.total++;
      
      drivers.set(driverId, {
        ws,
        lat: position.lat,
        lng: position.lng,
        interval: null,
        connected: true,
      });
      
      // Start sending GPS updates
      intervalId = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN && connected) {
          position = gpsGenerator.getNextPosition(position.lat, position.lng);
          
          const message = {
            lat: position.lat,
            lng: position.lng,
            timestamp: Date.now(),
          };
          
          const startTime = performance.now();
          ws.send(JSON.stringify(message));
          metrics.messages.sent++;
          
          // Track latency (time until next message can be sent)
          const latency = performance.now() - startTime;
          if (latency < 100) { // Only track reasonable latencies
            metrics.latencies.push(latency);
          }
          
          // Update driver state
          const driver = drivers.get(driverId);
          if (driver) {
            driver.lat = position.lat;
            driver.lng = position.lng;
          }
        }
      }, options.updateInterval);
      
      drivers.get(driverId).interval = intervalId;
      resolve({ success: true, driverId });
    });
    
    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        metrics.messages.responses++;
        
        if (message.error) {
          metrics.messages.errors++;
          console.error(`   ❌ Error from driver ${driverId}: ${message.error}`);
        }
      } catch (err) {
        // Non-JSON response, ignore
      }
    });
    
    ws.on('error', (error) => {
      if (resolved) return;
      resolved = true;
      clearTimeout(connectionTimeout);
      
      metrics.connections.failed++;
      metrics.connections.active--;
      connected = false;
      
      if (intervalId) {
        clearInterval(intervalId);
      }
      
      drivers.delete(driverId);
      resolve({ success: false, driverId, error: error.message });
    });
    
    ws.on('close', (code, reason) => {
      if (!connected && !resolved) {
        // Connection was closed before opening (likely authentication failure)
        resolved = true;
        clearTimeout(connectionTimeout);
        const reasonStr = reason.toString();
        let errorMsg = `Connection closed (code: ${code})`;
        if (reasonStr && reasonStr !== '') {
          errorMsg += `: ${reasonStr}`;
        }
        metrics.connections.failed++;
        resolve({ success: false, driverId, error: errorMsg });
        return;
      }
      
      metrics.connections.closed++;
      metrics.connections.active--;
      connected = false;
      
      if (intervalId) {
        clearInterval(intervalId);
      }
      
      drivers.delete(driverId);
    });
    
    ws.on('pong', () => {
      // Handle heartbeat pong
    });
  });
}

/**
 * Format time in milliseconds
 */
function formatTime(ms) {
  if (ms < 1) return `${(ms * 1000).toFixed(2)}μs`;
  if (ms < 1000) return `${ms.toFixed(2)}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

/**
 * Calculate percentile from sorted array
 */
function percentile(sortedArray, p) {
  if (sortedArray.length === 0) return 0;
  const index = Math.ceil((p / 100) * sortedArray.length) - 1;
  return sortedArray[Math.max(0, index)];
}

/**
 * Print test results
 */
function printResults() {
  const duration = (metrics.endTime - metrics.startTime) / 1000;
  const actualEventsPerSec = duration > 0 ? metrics.messages.sent / duration : 0;
  const targetEventsPerSec = options.eventsPerSec;
  
  console.log('\n\n' + '='.repeat(80));
  console.log('📊 GPS LOCATION SIMULATOR TEST RESULTS');
  console.log('='.repeat(80));
  
  console.log(`\n📈 Test Configuration:`);
  console.log(`   WebSocket URL:    ${options.wsUrl}`);
  console.log(`   Mode:             ${options.gateway ? 'Via API Gateway' : 'Direct Service'}`);
  console.log(`   Drivers:          ${options.drivers}`);
  console.log(`   Update Interval:  ${options.updateInterval}ms per driver`);
  console.log(`   Target Rate:      ${targetEventsPerSec} events/sec`);
  console.log(`   Duration:         ${options.duration}s`);
  console.log(`   Actual Duration:  ${duration.toFixed(2)}s`);
  
  console.log(`\n🔌 Connection Metrics:`);
  console.log(`   Total Connections: ${metrics.connections.total}`);
  console.log(`   Active:            ${metrics.connections.active}`);
  console.log(`   Failed:            ${metrics.connections.failed}`);
  console.log(`   Closed:            ${metrics.connections.closed}`);
  
  console.log(`\n📨 Message Metrics:`);
  console.log(`   Messages Sent:     ${metrics.messages.sent}`);
  console.log(`   Responses:         ${metrics.messages.responses}`);
  console.log(`   Errors:            ${metrics.messages.errors}`);
  console.log(`   Actual Rate:       ${actualEventsPerSec.toFixed(2)} events/sec`);
  
  if (metrics.latencies.length > 0) {
    const sorted = [...metrics.latencies].sort((a, b) => a - b);
    const p50 = percentile(sorted, 50);
    const p95 = percentile(sorted, 95);
    const p99 = percentile(sorted, 99);
    const min = sorted[0];
    const max = sorted[sorted.length - 1];
    const avg = sorted.reduce((a, b) => a + b, 0) / sorted.length;
    
    console.log(`\n⏱️  Message Latency Statistics:`);
    console.log(`   Min:             ${formatTime(min)}`);
    console.log(`   P50 (Median):    ${formatTime(p50)}`);
    console.log(`   P95:             ${formatTime(p95)}`);
    console.log(`   P99:             ${formatTime(p99)}`);
    console.log(`   Max:             ${formatTime(max)}`);
    console.log(`   Average:         ${formatTime(avg)}`);
  }
  
  // Requirement check
  console.log(`\n🎯 Requirement Check:`);
  const rateMet = actualEventsPerSec >= targetEventsPerSec * 0.9; // Allow 10% tolerance
  const connectionSuccessRate = metrics.connections.total > 0
    ? ((metrics.connections.total - metrics.connections.failed) / metrics.connections.total * 100).toFixed(2)
    : '0.00';
  
  if (rateMet) {
    console.log(`   ✅ PASS: Actual rate (${actualEventsPerSec.toFixed(2)} events/sec) meets target (${targetEventsPerSec} events/sec)`);
  } else {
    console.log(`   ❌ FAIL: Actual rate (${actualEventsPerSec.toFixed(2)} events/sec) below target (${targetEventsPerSec} events/sec)`);
  }
  
  if (parseFloat(connectionSuccessRate) >= 95) {
    console.log(`   ✅ PASS: Connection success rate (${connectionSuccessRate}%) meets requirement (≥95%)`);
  } else {
    console.log(`   ❌ FAIL: Connection success rate (${connectionSuccessRate}%) below requirement (≥95%)`);
  }
  
  console.log('\n' + '='.repeat(80) + '\n');
  
  // Exit with error code if requirements not met
  if (!rateMet || parseFloat(connectionSuccessRate) < 95) {
    process.exit(1);
  }
}

/**
 * Check Node.js version compatibility
 */
function checkNodeVersion() {
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0], 10);
  
  if (majorVersion < 18) {
    console.error(`\n❌ Error: Node.js 18+ required. Current version: ${nodeVersion}`);
    console.error('   Please upgrade Node.js to version 18 or higher.');
    process.exit(1);
  }
  
  // Check if fetch is available
  if (typeof fetch === 'undefined') {
    console.error('\n❌ Error: fetch API not available. Please use Node.js 18+');
    process.exit(1);
  }
  
  // WebSocket check is done at module load time
}

/**
 * Main test execution
 */
async function main() {
  checkNodeVersion();
  
  console.log('🚀 GPS Location Simulator for Driver Location Service');
  console.log('='.repeat(80));
  console.log(`\nSimulating: ${options.drivers} drivers sending GPS updates`);
  console.log(`Target: ${options.eventsPerSec} events/second`);
  console.log(`\nConfiguration:`);
  console.log(`   WebSocket URL:    ${options.wsUrl}`);
  console.log(`   Mode:             ${options.gateway ? 'Via API Gateway' : 'Direct Service'}`);
  console.log(`   Drivers:          ${options.drivers}`);
  console.log(`   Update Interval:  ${options.updateInterval}ms per driver`);
  console.log(`   Duration:         ${options.duration}s`);
  
  // Calculate expected events per second
  const expectedEventsPerSec = (options.drivers * 1000) / options.updateInterval;
  console.log(`   Expected Rate:    ${expectedEventsPerSec.toFixed(2)} events/sec`);
  
  if (expectedEventsPerSec > options.eventsPerSec) {
    console.log(`\n⚠️  Warning: Expected rate (${expectedEventsPerSec.toFixed(2)} events/sec) exceeds target (${options.eventsPerSec} events/sec)`);
    console.log(`   Consider increasing --update-interval or reducing --drivers`);
  }
  
  try {
    // Step 1: Get driver IDs
    console.log(`\n📋 Getting driver IDs...`);
    const driverIds = await getDriverIds(options.drivers, options.baseUrl);
    
    if (driverIds.length < options.drivers) {
      console.error(`\n❌ Error: Could not get ${options.drivers} driver IDs. Got ${driverIds.length}.`);
      console.error(`   Please ensure drivers exist in the database with is_active=true`);
      console.error(`   Or use --generate-drivers to create them (requires DB access)`);
      process.exit(1);
    }
    
    // Step 2: Initialize GPS generator
    const gpsGenerator = new GPSGenerator();
    
    // Step 3: Connect all drivers
    console.log(`\n🔌 Connecting ${driverIds.length} drivers...`);
    const connectionPromises = driverIds.map(driverId => connectDriver(driverId, gpsGenerator));
    const results = await Promise.allSettled(connectionPromises);
    
    const successful = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
    const failed = results.length - successful;
    
    console.log(`   ✓ Connected: ${successful}`);
    if (failed > 0) {
      console.log(`   ❌ Failed: ${failed}`);
    }
    
    if (successful === 0) {
      console.error(`\n❌ Error: No drivers could connect. Check that:`);
      console.error(`   1. Driver Location Service is running on port 3003`);
      console.error(`   2. Drivers exist in database with is_active=true`);
      console.error(`   3. WebSocket URL is correct: ${options.wsUrl}`);
      console.error(`\n💡 Tip: Generate test drivers first:`);
      console.error(`   node scripts/generate-drivers.js --count ${options.drivers}`);
      process.exit(1);
    }
    
    // Step 4: Run test for specified duration
    console.log(`\n🏃 Running test for ${options.duration} seconds...`);
    metrics.startTime = performance.now();
    
    // Progress indicator
    const progressInterval = setInterval(() => {
      const elapsed = ((performance.now() - metrics.startTime) / 1000).toFixed(0);
      const remaining = Math.max(0, options.duration - elapsed).toFixed(0);
      const currentRate = elapsed > 0 ? (metrics.messages.sent / elapsed).toFixed(2) : '0.00';
      process.stdout.write(
        `\r📊 Elapsed: ${elapsed}s / ${options.duration}s | ` +
        `Remaining: ${remaining}s | ` +
        `Rate: ${currentRate} events/sec | ` +
        `Active: ${metrics.connections.active}   `
      );
    }, 1000);
    
    // Wait for duration
    await new Promise(resolve => setTimeout(resolve, options.duration * 1000));
    
    clearInterval(progressInterval);
    console.log('\n');
    
    // Step 5: Close all connections
    console.log(`\n🔌 Closing connections...`);
    for (const [driverId, driver] of drivers.entries()) {
      if (driver.interval) {
        clearInterval(driver.interval);
      }
      if (driver.ws && driver.ws.readyState === WebSocket.OPEN) {
        driver.ws.close();
      }
    }
    
    // Wait a bit for cleanup
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    metrics.endTime = performance.now();
    
    // Step 6: Print results
    printResults();
    
  } catch (error) {
    console.error(`\n❌ Fatal Error: ${error.message}`);
    if (error.stack) {
      console.error(error.stack);
    }
    
    // Cleanup
    for (const [driverId, driver] of drivers.entries()) {
      if (driver.interval) {
        clearInterval(driver.interval);
      }
      if (driver.ws && driver.ws.readyState === WebSocket.OPEN) {
        driver.ws.close();
      }
    }
    
    process.exit(1);
  }
}

// Run the test
main();
