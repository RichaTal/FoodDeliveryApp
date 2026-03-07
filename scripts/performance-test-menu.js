#!/usr/bin/env node

/**
 * Performance Test Script for Restaurant Menu API
 * 
 * Tests P99 response time requirement: < 200ms for GET /restaurants/:id/menu
 * 
 * Requirements:
 *   - Node.js 18+ (for native fetch API)
 *   - Services must be running (docker-compose up)
 *   - Restaurants must exist in database (run generate-restaurants.js first)
 * 
 * Usage:
 *   node scripts/performance-test-menu.js [options]
 * 
 * Examples:
 *   # Test via API Gateway (default, 2 min sustained)
 *   node scripts/performance-test-menu.js
 * 
 *   # Test direct service for 2 minutes with 200 concurrent
 *   node scripts/performance-test-menu.js --direct --concurrent 200
 * 
 *   # Extended 3-minute test
 *   node scripts/performance-test-menu.js --direct --concurrent 200 --duration 180
 * 
 *   # Quick smoke test (30 seconds)
 *   node scripts/performance-test-menu.js --concurrent 50 --duration 30
 * 
 * Options:
 *   --base-url <url>        Base URL (default: http://localhost:8080)
 *   --direct                Test direct service on port 3001 instead of gateway
 *   --concurrent <n>        Number of concurrent requests (default: 50)
 *   --duration <s>          Test duration in seconds (default: 120)
 *   --warmup <n>            Warmup requests before test (default: 10)
 *   --timeout <ms>          Request timeout in ms (default: 5000)
 *   --help                  Show this help message
 */

const BASE_URL_DEFAULT = 'http://localhost:8080';
const DIRECT_URL_DEFAULT = 'http://localhost:3001';

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  baseUrl: BASE_URL_DEFAULT,
  direct: false,
  concurrent: 50,
  duration: 120, // seconds
  warmup: 10,
  timeout: 5000,
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
  cacheHits: 0,
  cacheMisses: 0,
  statusCodes: {},
  startTime: null,
  endTime: null,
};

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
 * Fetch restaurant IDs from the API
 */
async function fetchRestaurantIds(baseUrl) {
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
    const restaurantIds = data.data?.map(r => r.id) || [];
    
    if (restaurantIds.length === 0) {
      throw new Error('No restaurants found in the database. Please run the generate-restaurants script first.');
    }
    
    return restaurantIds;
  } catch (error) {
    if (error.name === 'TimeoutError') {
      throw new Error(`Request timeout after ${options.timeout}ms`);
    }
    throw error;
  }
}

/**
 * Make a single menu request
 */
async function fetchMenu(restaurantId, baseUrl) {
  const url = options.direct
    ? `${baseUrl}/restaurants/${restaurantId}/menu`
    : `${baseUrl}/api/restaurants/${restaurantId}/menu`;
  
  const startTime = performance.now();
  
  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(options.timeout),
    });
    
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    const cacheHeader = response.headers.get('X-Cache');
    if (cacheHeader === 'HIT') {
      metrics.cacheHits++;
    } else if (cacheHeader === 'MISS') {
      metrics.cacheMisses++;
    }
    
    const statusCode = response.status;
    metrics.statusCodes[statusCode] = (metrics.statusCodes[statusCode] || 0) + 1;
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`HTTP ${statusCode}: ${errorText}`);
    }
    
    await response.json(); // Consume body to ensure full response
    
    return {
      success: true,
      responseTime,
      statusCode,
      cacheHit: cacheHeader === 'HIT',
    };
  } catch (error) {
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    metrics.errors.push({
      error: error.message,
      responseTime,
      restaurantId,
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
async function warmup(restaurantIds, baseUrl) {
  console.log(`\n🔥 Warming up with ${options.warmup} requests...`);
  
  for (let i = 0; i < options.warmup; i++) {
    const restaurantId = restaurantIds[i % restaurantIds.length];
    await fetchMenu(restaurantId, baseUrl);
  }
  
  // Reset metrics after warmup
  metrics.responseTimes = [];
  metrics.errors = [];
  metrics.cacheHits = 0;
  metrics.cacheMisses = 0;
  metrics.statusCodes = {};
}

/**
 * Run concurrent requests for a fixed duration (time-based, not count-based).
 * Maintains `options.concurrent` in-flight requests at all times until the
 * duration expires, then waits for the last in-flight batch to finish.
 */
async function runConcurrentRequests(restaurantIds, baseUrl) {
  const durationMs = options.duration * 1000;
  const testEnd = Date.now() + durationMs;
  const testStart = Date.now();
  let completed = 0;
  let active = 0;
  let requestIndex = 0;

  return new Promise((resolve) => {
    function scheduleNext() {
      // All active requests drained after deadline → done
      if (Date.now() >= testEnd && active === 0) {
        resolve();
        return;
      }

      // Spin up as many workers as allowed while time remains
      while (active < options.concurrent && Date.now() < testEnd) {
        active++;
        const restaurantId = restaurantIds[requestIndex % restaurantIds.length];
        requestIndex++;

        fetchMenu(restaurantId, baseUrl).then((result) => {
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
          process.stdout.write(
            `\r📊 ${completed} requests | ` +
            `Elapsed: ${elapsedSec}s / ${options.duration}s | ` +
            `Remaining: ${remainSec}s | Active: ${active}   `
          );

          scheduleNext();
        });
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
  const successRate = ((metrics.responseTimes.length / totalRequests) * 100).toFixed(2);
  
  console.log('\n\n' + '='.repeat(80));
  console.log('📊 PERFORMANCE TEST RESULTS');
  console.log('='.repeat(80));
  
  console.log(`\n📈 Test Configuration:`);
  console.log(`   Base URL:        ${options.baseUrl}`);
  console.log(`   Mode:            ${options.direct ? 'Direct Service' : 'Via API Gateway'}`);
  console.log(`   Concurrent:      ${options.concurrent}`);
  console.log(`   Target Duration: ${options.duration}s`);
  console.log(`   Actual Duration: ${duration.toFixed(2)}s`);
  console.log(`   Total Requests:  ${totalRequests}`);
  console.log(`   Throughput:      ${(totalRequests / duration).toFixed(2)} req/s`);
  
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
    console.log(`   P99:             ${formatTime(p99)} ${p99 < 200 ? '✅' : '❌'} (target: < 200ms)`);
    console.log(`   P99.9:           ${formatTime(p999)}`);
    console.log(`   Max:             ${formatTime(max)}`);
    console.log(`   Average:         ${formatTime(avg)}`);
    
    // P99 requirement check
    console.log(`\n🎯 P99 Requirement Check:`);
    if (p99 < 200) {
      console.log(`   ✅ PASS: P99 latency (${formatTime(p99)}) is under 200ms`);
    } else {
      console.log(`   ❌ FAIL: P99 latency (${formatTime(p99)}) exceeds 200ms target`);
    }
  }
  
  const totalCacheOps = metrics.cacheHits + metrics.cacheMisses;
  if (totalCacheOps > 0) {
    const cacheHitRate = ((metrics.cacheHits / totalCacheOps) * 100).toFixed(2);
    console.log(`\n💾 Cache Statistics:`);
    console.log(`   Cache Hits:      ${metrics.cacheHits} (${cacheHitRate}%)`);
    console.log(`   Cache Misses:    ${metrics.cacheMisses} (${(100 - parseFloat(cacheHitRate)).toFixed(2)}%)`);
  }
  
  if (Object.keys(metrics.statusCodes).length > 0) {
    console.log(`\n📡 HTTP Status Codes:`);
    Object.entries(metrics.statusCodes)
      .sort(([a], [b]) => parseInt(a) - parseInt(b))
      .forEach(([code, count]) => {
        console.log(`   ${code}:           ${count}`);
      });
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
  
  console.log('🚀 Restaurant Menu Performance Test');
  console.log('='.repeat(80));
  console.log(`\nTesting: GET /restaurants/:id/menu`);
  console.log(`Target: P99 response time < 200ms`);
  console.log(`\nConfiguration:`);
  console.log(`   Base URL:     ${options.baseUrl}`);
  console.log(`   Mode:         ${options.direct ? 'Direct Service' : 'Via API Gateway'}`);
  console.log(`   Concurrent:   ${options.concurrent}`);
  console.log(`   Duration:     ${options.duration}s`);
  console.log(`   Timeout:      ${options.timeout}ms`);
  
  if (!options.direct) {
    console.log(`\n⚠️  Note: Testing via API Gateway. Rate limit is 500 req/min.`);
    console.log(`   For high-load tests, use --direct to bypass gateway rate limiting.`);
  }
  
  try {
    // Step 1: Fetch restaurant IDs
    console.log(`\n📋 Fetching restaurant IDs...`);
    const restaurantIds = await fetchRestaurantIds(options.baseUrl);
    console.log(`   Found ${restaurantIds.length} restaurants`);
    
    if (restaurantIds.length === 0) {
      console.error('\n❌ Error: No restaurants found. Please run the generate-restaurants script first.');
      process.exit(1);
    }
    
    // Step 2: Warmup
    await warmup(restaurantIds, options.baseUrl);
    
    // Step 3: Run performance test
    console.log(`\n🏃 Running ${options.duration}s sustained load test (${options.concurrent} concurrent)...`);
    metrics.startTime = performance.now();
    await runConcurrentRequests(restaurantIds, options.baseUrl);
    metrics.endTime = performance.now();
    
    // Step 4: Print results
    printResults();
    
    // Exit with error code if P99 requirement not met
    if (metrics.responseTimes.length > 0) {
      const sorted = [...metrics.responseTimes].sort((a, b) => a - b);
      const p99 = percentile(sorted, 99);
      if (p99 >= 200) {
        process.exit(1);
      }
    }
    
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
