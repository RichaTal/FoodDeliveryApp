import { Redis } from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

let retryCount = 0;
const MAX_RETRIES = 3;

const redisClient = new Redis({
  host: process.env['REDIS_HOST'] || 'localhost',
  port: parseInt(process.env['REDIS_PORT'] || '6379', 10),
  lazyConnect: true,
  // Performance optimizations
  enableOfflineQueue: false, // Don't queue commands when disconnected
  maxRetriesPerRequest: 3, // Limit retries for faster failure
  connectTimeout: 2000, // 2s connection timeout
  commandTimeout: 1000, // 1s command timeout for faster failures
  retryStrategy(times: number): number | null {
    retryCount = times;
    if (times > MAX_RETRIES) {
      // Stop retrying - no logging to avoid performance overhead
      return null;
    }
    const delay = Math.min(times * 200, 2_000); // exponential back-off, max 2s
    return delay;
  },
});

redisClient.on('connect', () => {
  retryCount = 0;
  // No logging to avoid performance overhead
});

redisClient.on('error', (err: Error) => {
  // Silently handle errors - no logging to avoid performance overhead
  void err; // Suppress unused variable warning
});

redisClient.on('close', () => {
  // No logging to avoid performance overhead
});

export { retryCount };
export default redisClient;
