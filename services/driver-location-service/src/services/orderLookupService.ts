import redisClient from '../config/redis.js';

const ORDER_SERVICE_URL = process.env['ORDER_SERVICE_URL'] || 'http://localhost:3002';
const CACHE_TTL_SECONDS = 30;
const CACHE_KEY_PREFIX = 'driver-order-lookup:';

/**
 * Lookup active orderId for a driver by calling the order-service API.
 * Results are cached in Redis (TTL: 30s) to reduce inter-service calls.
 * Returns null if the driver has no active PICKED_UP order or on error.
 *
 * Redis is used for caching (not in-memory Map) to work correctly across
 * multiple service instances.
 */
export async function getActiveOrderId(driverId: string): Promise<string | null> {
  const cacheKey = `${CACHE_KEY_PREFIX}${driverId}`;

  // 1. Check Redis cache first
  try {
    const cached = await redisClient.get(cacheKey);
    if (cached !== null) {
      // 'null' string encodes a cached negative (no active order)
      return cached === 'null' ? null : cached;
    }
  } catch (err) {
    console.warn(
      `[OrderLookup] Redis cache read failed for driver ${driverId}:`,
      (err as Error).message,
    );
  }

  // 2. Call order-service API
  try {
    const response = await fetch(
      `${ORDER_SERVICE_URL}/orders/driver/${driverId}/active`,
      { signal: AbortSignal.timeout(3_000) }, // 3-second timeout
    );

    let orderId: string | null = null;

    if (response.ok) {
      const body = (await response.json()) as { data?: { orderId?: string } };
      orderId = body?.data?.orderId ?? null;
    } else if (response.status === 404) {
      // No active order — cache the negative result
      orderId = null;
    } else {
      // Unexpected error from order-service — skip cache, return null
      console.warn(
        `[OrderLookup] Order service returned HTTP ${response.status} for driver ${driverId}`,
      );
      return null;
    }

    // 3. Cache result in Redis (TTL handled by Redis, no manual cleanup needed)
    try {
      await redisClient.setex(cacheKey, CACHE_TTL_SECONDS, orderId ?? 'null');
    } catch (err) {
      console.warn(
        `[OrderLookup] Redis cache write failed for driver ${driverId}:`,
        (err as Error).message,
      );
    }

    return orderId;
  } catch (err) {
    const error = err as Error;
    console.error(
      `[OrderLookup] Error looking up order for driver ${driverId}:`,
      error.message,
    );
    return null;
  }
}

/**
 * Invalidate the Redis cache entry for a driver.
 * Call this when the driver's order status changes so the next GPS ping
 * fetches a fresh orderId from the order-service.
 */
export async function invalidateOrderCache(driverId: string): Promise<void> {
  const cacheKey = `${CACHE_KEY_PREFIX}${driverId}`;
  try {
    await redisClient.del(cacheKey);
  } catch (err) {
    console.warn(
      `[OrderLookup] Failed to invalidate cache for driver ${driverId}:`,
      (err as Error).message,
    );
  }
}
