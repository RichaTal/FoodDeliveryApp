#!/usr/bin/env node

/**
 * Performance Test Script for Order Processing API
 * 
 * Tests requirement: Handle peak load of 500 orders per minute
 * 
 * Requirements:
 *   - Node.js 18+ (for native fetch API)
 *   - Services must be running (docker-compose up)
 *   - Restaurants and menu items must exist in database (run generate-restaurants.js first)
 * 
 * Usage:
 *   node scripts/performance-test-orders.js [options]
 * 
 * Examples:
 *   # Test via API Gateway (default, 1 min sustained at 500 orders/min)
 *   node scripts/performance-test-orders.js
 * 
 *   # Test direct service for 1 minute with 500 orders/min
 *   node scripts/performance-test-orders.js --direct --target-rate 500
 * 
 *   # Extended 5-minute test
 *   node scripts/performance-test-orders.js --direct --target-rate 500 --duration 300
 * 
 *   # Quick smoke test (30 seconds, 100 orders/min)
 *   node scripts/performance-test-orders.js --concurrent 10 --duration 30 --target-rate 100
 * 
 * Options:
 *   --base-url <url>        Base URL (default: http://localhost:8080)
 *   --direct                Test direct service on port 3002 instead of gateway
 *   --concurrent <n>        Number of concurrent requests (default: 20)
 *   --duration <s>          Test duration in seconds (default: 60)
 *   --target-rate <n>       Target orders per minute (default: 500)
 *   --warmup <n>            Warmup requests before test (default: 5)
 *   --timeout <ms>          Request timeout in ms (default: 10000)
 *   --help                  Show this help message
 */

const BASE_URL_DEFAULT = 'http://localhost:8080';
const DIRECT_URL_DEFAULT = 'http://localhost:3002';

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  baseUrl: BASE_URL_DEFAULT,
  direct: false,
  concurrent: 20,
  duration: 60, // seconds
  targetRate: 500, // orders per minute
  warmup: 5,
  timeout: 10000,
};

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--help' || arg === '-h') {
    const helpText = require('fs').readFileSync(__filename, 'utf8').match(/\/\*\*[\s\S]*?\*\//);
    if (helpText) {
      console.log(helpText[0]);
    }
    process.exit(0);
  } else if (arg === '--direct') {
    options.direct = true;
    options.baseUrl = DIRECT_URL_DEFAULT;
  } else if (arg === '--base-url' && args[i + 1]) {
    options.baseUrl = args[++i];
  } else if (arg === '--concurrent' && args[i + 1]) {
    options.concurrent = parseInt(args[++i], 10);
  } else if (arg === '--duration' && args[i + 1]) {
    options.duration = parseInt(args[++i], 10);
  } else if (arg === '--target-rate' && args[i + 1]) {
    options.targetRate = parseInt(args[++i], 10);
  } else if (arg === '--warmup' && args[i + 1]) {
    options.warmup = parseInt(args[++i], 10);
  } else if (arg === '--timeout' && args[i + 1]) {
    options.timeout = parseInt(args[++i], 10);
  }
}

// Performance metrics
const metrics = {
  responseTimes: [],
  errors: [],
  statusCodes: {},
  orderIds: [],
  startTime: null,
  endTime: null,
};

// Test data cache
let testData = {
  restaurants: [],
  menus: new Map(), // restaurantId -> menu items array
};

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
 * Calculate percentile from sorted array
 */
function percentile(sortedArray, p) {
  if (sortedArray.length === 0) return 0;
  const index = Math.ceil((p / 100) * sortedArray.length) - 1;
  return sortedArray[Math.max(0, index)];
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
 * Fetch restaurants from the API
 */
async function fetchRestaurants(baseUrl) {
  const url = options.direct 
    ? `${baseUrl}/restaurants`
    : `${baseUrl}/api/restaurants`;
  
  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(options.timeout),
    });
    
    if (!response.ok) {
      throw new Error(`Failed to fetch restaurants: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    const restaurants = (data.data || []).filter(r => r.is_open !== false);
    
    if (restaurants.length === 0) {
      throw new Error('No open restaurants found in the database. Please run the generate-restaurants script first.');
    }
    
    return restaurants;
  } catch (error) {
    if (error.name === 'TimeoutError') {
      throw new Error(`Request timeout after ${options.timeout}ms`);
    }
    throw error;
  }
}

/**
 * Fetch menu for a restaurant
 */
async function fetchMenu(restaurantId, baseUrl) {
  const url = options.direct
    ? `${baseUrl}/restaurants/${restaurantId}/menu`
    : `${baseUrl}/api/restaurants/${restaurantId}/menu`;
  
  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(options.timeout),
    });
    
    if (!response.ok) {
      throw new Error(`Failed to fetch menu: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    const menu = data.data || {};
    
    // Extract menu items from categories
    const items = [];
    if (menu.categories && Array.isArray(menu.categories)) {
      for (const category of menu.categories) {
        if (category.items && Array.isArray(category.items)) {
          for (const item of category.items) {
            if (item.is_available !== false) {
              items.push({
                id: item.id,
                name: item.name,
                price: item.price,
              });
            }
          }
        }
      }
    }
    
    return items;
  } catch (error) {
    if (error.name === 'TimeoutError') {
      throw new Error(`Request timeout after ${options.timeout}ms`);
    }
    throw error;
  }
}

/**
 * Load test data (restaurants and their menus)
 */
async function loadTestData(baseUrl) {
  console.log(`\n📋 Loading test data...`);
  
  // Fetch restaurants
  const restaurants = await fetchRestaurants(baseUrl);
  console.log(`   Found ${restaurants.length} open restaurants`);
  
  // Fetch menus for first 10 restaurants (or all if less than 10)
  const restaurantsToLoad = restaurants.slice(0, Math.min(10, restaurants.length));
  console.log(`   Loading menus for ${restaurantsToLoad.length} restaurants...`);
  
  const menus = new Map();
  for (const restaurant of restaurantsToLoad) {
    try {
      const menuItems = await fetchMenu(restaurant.id, baseUrl);
      if (menuItems.length > 0) {
        menus.set(restaurant.id, menuItems);
        console.log(`   ✓ ${restaurant.name}: ${menuItems.length} items`);
      }
    } catch (error) {
      console.warn(`   ⚠ Failed to load menu for ${restaurant.name}: ${error.message}`);
    }
  }
  
  if (menus.size === 0) {
    throw new Error('No restaurants with available menu items found. Please ensure restaurants have menu items.');
  }
  
  testData.restaurants = Array.from(menus.keys());
  testData.menus = menus;
  
  console.log(`   ✓ Loaded test data for ${testData.restaurants.length} restaurants`);
  
  return {
    restaurants: testData.restaurants,
    menus: testData.menus,
  };
}

/**
 * Get a random restaurant and menu items for order creation
 */
function getRandomOrderData() {
  const restaurantId = testData.restaurants[Math.floor(Math.random() * testData.restaurants.length)];
  const menuItems = testData.menus.get(restaurantId);
  
  if (!menuItems || menuItems.length === 0) {
    throw new Error(`No menu items found for restaurant ${restaurantId}`);
  }
  
  // Select 1-3 random items
  const numItems = Math.min(1 + Math.floor(Math.random() * 3), menuItems.length);
  const selectedItems = [];
  const usedIndices = new Set();
  
  for (let i = 0; i < numItems; i++) {
    let index;
    do {
      index = Math.floor(Math.random() * menuItems.length);
    } while (usedIndices.has(index));
    
    usedIndices.add(index);
    const item = menuItems[index];
    selectedItems.push({
      menuItemId: item.id,
      quantity: 1 + Math.floor(Math.random() * 3), // 1-3 quantity
    });
  }
  
  return {
    restaurantId,
    items: selectedItems,
  };
}

/**
 * Place a single order
 */
async function placeOrder(baseUrl) {
  const orderData = getRandomOrderData();
  const idempotencyKey = generateUUID();
  
  const url = options.direct
    ? `${baseUrl}/orders`
    : `${baseUrl}/api/orders`;
  
  const startTime = performance.now();
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Idempotency-Key': idempotencyKey,
      },
      body: JSON.stringify({
        restaurantId: orderData.restaurantId,
        items: orderData.items,
      }),
      signal: AbortSignal.timeout(options.timeout),
    });
    
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    const statusCode = response.status;
    metrics.statusCodes[statusCode] = (metrics.statusCodes[statusCode] || 0) + 1;
    
    let responseData;
    try {
      responseData = await response.json();
    } catch (e) {
      responseData = { error: 'Failed to parse response' };
    }
    
    if (response.status === 202) {
      // Success - order accepted
      const orderId = responseData.data?.orderId;
      if (orderId) {
        metrics.orderIds.push(orderId);
      }
      
      return {
        success: true,
        responseTime,
        statusCode,
        orderId,
      };
    } else {
      // Error response
      const errorMessage = responseData.error || `HTTP ${statusCode}`;
      throw new Error(errorMessage);
    }
  } catch (error) {
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    metrics.errors.push({
      error: error.message,
      responseTime,
      restaurantId: orderData.restaurantId,
    });
    
    return {
      success: false,
      responseTime,
      error: error.message,
    };
  }
}

/**
 * Run warmup requests
 */
async function warmup(baseUrl) {
  console.log(`\n🔥 Warming up with ${options.warmup} requests...`);
  
  for (let i = 0; i < options.warmup; i++) {
    await placeOrder(baseUrl);
  }
  
  // Reset metrics after warmup
  metrics.responseTimes = [];
  metrics.errors = [];
  metrics.statusCodes = {};
  metrics.orderIds = [];
}

/**
 * Calculate delay between requests to achieve target rate
 */
function calculateDelay(targetRatePerMinute, concurrent) {
  const targetRatePerSecond = targetRatePerMinute / 60;
  const delayBetweenRequests = 1000 / targetRatePerSecond; // ms between requests
  const delayPerConcurrent = delayBetweenRequests * concurrent; // total delay for concurrent batch
  return Math.max(0, delayPerConcurrent);
}

/**
 * Run concurrent requests for a fixed duration with rate limiting
 */
async function runConcurrentRequests(baseUrl) {
  const durationMs = options.duration * 1000;
  const testEnd = Date.now() + durationMs;
  const testStart = Date.now();
  let completed = 0;
  let active = 0;
  let requestIndex = 0;
  
  // Calculate delay to maintain target rate
  const delayMs = calculateDelay(options.targetRate, options.concurrent);
  let lastBatchTime = Date.now();
  
  return new Promise((resolve) => {
    function scheduleNext() {
      // All active requests drained after deadline → done
      if (Date.now() >= testEnd && active === 0) {
        resolve();
        return;
      }
      
      // Rate limiting: wait if needed to maintain target rate
      const now = Date.now();
      if (now < testEnd && delayMs > 0 && (now - lastBatchTime) < delayMs) {
        setTimeout(scheduleNext, delayMs - (now - lastBatchTime));
        return;
      }
      
      // Spin up as many workers as allowed while time remains
      while (active < options.concurrent && Date.now() < testEnd) {
        active++;
        requestIndex++;
        lastBatchTime = Date.now();
        
        placeOrder(baseUrl).then((result) => {
          if (result.success) {
            metrics.responseTimes.push(result.responseTime);
          }
          completed++;
          active--;
          
          // Live progress line
          const elapsedSec = Math.min(
            options.duration,
            ((Date.now() - testStart) / 1000)
          ).toFixed(0);
          const remainSec = Math.max(0, ((testEnd - Date.now()) / 1000)).toFixed(0);
          const ordersPerMin = completed > 0 ? ((completed / ((Date.now() - testStart) / 1000)) * 60).toFixed(0) : '0';
          process.stdout.write(
            `\r📊 ${completed} orders | ` +
            `Rate: ${ordersPerMin} orders/min | ` +
            `Elapsed: ${elapsedSec}s / ${options.duration}s | ` +
            `Remaining: ${remainSec}s | Active: ${active}   `
          );
          
          scheduleNext();
        });
      }
      
      // If we can't schedule more but time remains, wait a bit
      if (Date.now() < testEnd && active > 0) {
        setTimeout(scheduleNext, 10);
      }
    }
    
    scheduleNext();
  });
}

/**
 * Print test results
 */
function printResults() {
  const duration = (metrics.endTime - metrics.startTime) / 1000;
  const totalRequests = metrics.responseTimes.length + metrics.errors.length;
  const successRate = totalRequests > 0 ? ((metrics.responseTimes.length / totalRequests) * 100).toFixed(2) : '0.00';
  const actualRate = duration > 0 ? (totalRequests / duration) * 60 : 0; // orders per minute
  
  console.log('\n\n' + '='.repeat(80));
  console.log('📊 ORDER PROCESSING PERFORMANCE TEST RESULTS');
  console.log('='.repeat(80));
  
  console.log(`\n📈 Test Configuration:`);
  console.log(`   Base URL:        ${options.baseUrl}`);
  console.log(`   Mode:            ${options.direct ? 'Direct Service' : 'Via API Gateway'}`);
  console.log(`   Concurrent:      ${options.concurrent}`);
  console.log(`   Target Duration: ${options.duration}s`);
  console.log(`   Target Rate:     ${options.targetRate} orders/min`);
  console.log(`   Actual Duration: ${duration.toFixed(2)}s`);
  console.log(`   Total Orders:    ${totalRequests}`);
  console.log(`   Actual Rate:     ${actualRate.toFixed(2)} orders/min`);
  
  console.log(`\n✅ Success Metrics:`);
  console.log(`   Successful:      ${metrics.responseTimes.length} (${successRate}%)`);
  console.log(`   Failed:          ${metrics.errors.length} (${(100 - parseFloat(successRate)).toFixed(2)}%)`);
  
  if (metrics.responseTimes.length > 0) {
    const sorted = [...metrics.responseTimes].sort((a, b) => a - b);
    const p50 = percentile(sorted, 50);
    const p95 = percentile(sorted, 95);
    const p99 = percentile(sorted, 99);
    const p999 = percentile(sorted, 99.9);
    const min = sorted[0];
    const max = sorted[sorted.length - 1];
    const avg = sorted.reduce((a, b) => a + b, 0) / sorted.length;
    
    console.log(`\n⏱️  Response Time Statistics:`);
    console.log(`   Min:             ${formatTime(min)}`);
    console.log(`   P50 (Median):    ${formatTime(p50)}`);
    console.log(`   P95:             ${formatTime(p95)}`);
    console.log(`   P99:             ${formatTime(p99)}`);
    console.log(`   P99.9:           ${formatTime(p999)}`);
    console.log(`   Max:             ${formatTime(max)}`);
    console.log(`   Average:         ${formatTime(avg)}`);
  }
  
  if (Object.keys(metrics.statusCodes).length > 0) {
    console.log(`\n📡 HTTP Status Codes:`);
    Object.entries(metrics.statusCodes)
      .sort(([a], [b]) => parseInt(a) - parseInt(b))
      .forEach(([code, count]) => {
        console.log(`   ${code}:           ${count}`);
      });
  }
  
  // Requirement check: 500 orders per minute
  console.log(`\n🎯 Requirement Check:`);
  const rateMet = actualRate >= options.targetRate * 0.95; // Allow 5% tolerance
  const successRateMet = parseFloat(successRate) >= 99.5;
  
  if (rateMet) {
    console.log(`   ✅ PASS: Actual rate (${actualRate.toFixed(2)} orders/min) meets target (${options.targetRate} orders/min)`);
  } else {
    console.log(`   ❌ FAIL: Actual rate (${actualRate.toFixed(2)} orders/min) below target (${options.targetRate} orders/min)`);
  }
  
  if (successRateMet) {
    console.log(`   ✅ PASS: Success rate (${successRate}%) meets requirement (≥99.5%)`);
  } else {
    console.log(`   ❌ FAIL: Success rate (${successRate}%) below requirement (≥99.5%)`);
  }
  
  if (metrics.orderIds.length > 0) {
    console.log(`\n📦 Orders Created:`);
    console.log(`   Unique Orders:   ${new Set(metrics.orderIds).size}`);
    console.log(`   Total Orders:   ${metrics.orderIds.length}`);
  }
  
  if (metrics.errors.length > 0) {
    console.log(`\n❌ Errors (showing first 10):`);
    metrics.errors.slice(0, 10).forEach((err, idx) => {
      console.log(`   ${idx + 1}. ${err.error}`);
    });
    if (metrics.errors.length > 10) {
      console.log(`   ... and ${metrics.errors.length - 10} more errors`);
    }
  }
  
  console.log('\n' + '='.repeat(80) + '\n');
  
  // Exit with error code if requirements not met
  if (!rateMet || !successRateMet) {
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
}

/**
 * Main test execution
 */
async function main() {
  checkNodeVersion();
  
  console.log('🚀 Order Processing Performance Test');
  console.log('='.repeat(80));
  console.log(`\nTesting: POST /orders`);
  console.log(`Target: ${options.targetRate} orders per minute`);
  console.log(`\nConfiguration:`);
  console.log(`   Base URL:     ${options.baseUrl}`);
  console.log(`   Mode:         ${options.direct ? 'Direct Service' : 'Via API Gateway'}`);
  console.log(`   Concurrent:   ${options.concurrent}`);
  console.log(`   Duration:     ${options.duration}s`);
  console.log(`   Target Rate:  ${options.targetRate} orders/min`);
  console.log(`   Timeout:      ${options.timeout}ms`);
  
  if (!options.direct) {
    console.log(`\n⚠️  Note: Testing via API Gateway. Rate limit is 500 req/min.`);
    console.log(`   For high-load tests, use --direct to bypass gateway rate limiting.`);
  }
  
  try {
    // Step 1: Load test data
    await loadTestData(options.baseUrl);
    
    // Step 2: Warmup
    await warmup(options.baseUrl);
    
    // Step 3: Run performance test
    console.log(`\n🏃 Running ${options.duration}s sustained load test (target: ${options.targetRate} orders/min)...`);
    metrics.startTime = performance.now();
    await runConcurrentRequests(options.baseUrl);
    metrics.endTime = performance.now();
    
    // Step 4: Print results
    printResults();
    
  } catch (error) {
    console.error(`\n❌ Fatal Error: ${error.message}`);
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run the test
main();