import redisClient from '../config/redis.js';

const SESSION_TTL = 3600; // 1 hour in seconds

/**
 * Register a WebSocket session for an orderId
 * Maps orderId to the instanceId that holds the connection
 */
export async function registerSession(orderId: string, instanceId: string): Promise<void> {
  const key = `ws:session:${orderId}`;
  await redisClient.set(key, instanceId, 'EX', SESSION_TTL);
}

/**
 * Get the instanceId that holds the WebSocket session for an orderId
 * Returns null if no active session exists
 */
export async function getSessionInstance(orderId: string): Promise<string | null> {
  const key = `ws:session:${orderId}`;
  const instanceId = await redisClient.get(key);
  return instanceId;
}

/**
 * Remove a WebSocket session when customer disconnects
 */
export async function removeSession(orderId: string): Promise<void> {
  const key = `ws:session:${orderId}`;
  await redisClient.del(key);
}

/**
 * Refresh the TTL of a session (called on message activity)
 */
export async function refreshSession(orderId: string): Promise<void> {
  const key = `ws:session:${orderId}`;
  await redisClient.expire(key, SESSION_TTL);
}
