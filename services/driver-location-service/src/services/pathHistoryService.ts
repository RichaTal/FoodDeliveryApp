import redisClient from '../config/redis.js';
import type { GpsPing } from '../types/index.js';

const PATH_KEY_PREFIX = 'drivers:path:';
const PATH_TTL_SECONDS = 2 * 60 * 60; // 2 hours - keep recent path in Redis
const PATH_CLEANUP_AGE_MS = 2 * 60 * 60 * 1000; // 2 hours

export interface PathPoint {
  lat: number;
  lng: number;
  timestamp: number;
}

/**
 * Store driver location in Redis sorted set for path history
 * Uses orderId if available, otherwise falls back to driverId
 */
export async function storePathPoint(
  ping: GpsPing,
  orderId?: string | null,
): Promise<void> {
  // Use orderId if available, otherwise use driverId
  const pathKey = `${PATH_KEY_PREFIX}${orderId || ping.driverId}`;
  
  // Store point in sorted set with timestamp as score
  const point: PathPoint = {
    lat: ping.lat,
    lng: ping.lng,
    timestamp: ping.timestamp,
  };
  
  // Use timestamp as score for chronological ordering
  await redisClient.zadd(pathKey, ping.timestamp, JSON.stringify(point));
  
  // Set TTL on the key (refresh on each write)
  await redisClient.expire(pathKey, PATH_TTL_SECONDS);
  
  // Cleanup old points (keep only last 2 hours)
  const cutoffTimestamp = Date.now() - PATH_CLEANUP_AGE_MS;
  await redisClient.zremrangebyscore(pathKey, 0, cutoffTimestamp);
}

/**
 * Get path history from Redis for a given orderId or driverId
 * Returns points within the specified time range
 */
export async function getPathHistory(
  orderIdOrDriverId: string,
  startTime?: number,
  endTime?: number,
): Promise<PathPoint[]> {
  const pathKey = `${PATH_KEY_PREFIX}${orderIdOrDriverId}`;
  
  const minScore = startTime || 0;
  const maxScore = endTime || '+inf';
  
  // Get all points in time range
  const results = await redisClient.zrangebyscore(
    pathKey,
    minScore,
    maxScore,
    'WITHSCORES',
  );
  
  if (!results || results.length === 0) {
    return [];
  }
  
  // Parse results: [point1_json, score1, point2_json, score2, ...]
  const points: PathPoint[] = [];
  for (let i = 0; i < results.length; i += 2) {
    try {
      const point = JSON.parse(results[i] as string) as PathPoint;
      points.push(point);
    } catch (err) {
      // Skip invalid JSON entries
      console.warn(`[PathHistory] Failed to parse path point: ${results[i]}`);
    }
  }
  
  return points;
}

/**
 * Delete path history for a given orderId or driverId
 * Called when order is completed or driver goes offline
 */
export async function deletePathHistory(orderIdOrDriverId: string): Promise<void> {
  const pathKey = `${PATH_KEY_PREFIX}${orderIdOrDriverId}`;
  await redisClient.del(pathKey);
}

/**
 * Get all active path keys (for monitoring/debugging)
 */
export async function getActivePathKeys(): Promise<string[]> {
  const pattern = `${PATH_KEY_PREFIX}*`;
  const keys = await redisClient.keys(pattern);
  return keys.map((key) => key.replace(PATH_KEY_PREFIX, ''));
}
