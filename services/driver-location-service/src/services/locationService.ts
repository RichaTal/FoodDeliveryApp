import redisClient from '../config/redis.js';
import type { GpsPing, DriverLocation, NearbyDriversQuery } from '../types/index.js';
import { storePathPoint } from './pathHistoryService.js';
import { bufferLocationPoint } from './batchWriterService.js';

const GEO_KEY = 'drivers:active';
const TTL_KEY = 'drivers:ttl';
const TTL_MS = 30_000; // 30 seconds

/**
 * Update driver position in Redis GEO and maintain TTL tracking
 * Also stores path history in Redis and buffers for PostgreSQL batch write
 */
export async function updateDriverPosition(
  ping: GpsPing,
  orderId?: string | null,
): Promise<void> {
  // Redis GEO argument order is longitude first, then latitude
  await redisClient.geoadd(GEO_KEY, ping.lng, ping.lat, ping.driverId);
  
  // Maintain TTL tracking: add to sorted set with score = expiry timestamp
  const expiryScore = Date.now() + TTL_MS;
  await redisClient.zadd(TTL_KEY, expiryScore, ping.driverId);
  
  // Store path history in Redis (fire-and-forget)
  storePathPoint(ping, orderId).catch((err) => {
    console.error(`[LocationService] Error storing path point:`, err);
  });
  
  // Buffer for PostgreSQL batch write (fire-and-forget)
  // bufferLocationPoint(ping, orderId);
  
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
    lat: typeof lat === 'string' ? parseFloat(lat) : lat,
    lng: typeof lng === 'string' ? parseFloat(lng) : lng,
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
