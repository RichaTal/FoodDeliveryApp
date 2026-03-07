import { Redis } from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

let retryCount = 0;
const MAX_RETRIES = 3;

const redisClient = new Redis({
  host: process.env['REDIS_HOST'] || 'localhost',
  port: parseInt(process.env['REDIS_PORT'] || '6379', 10),
  lazyConnect: true,
  retryStrategy(times: number): number | null {
    retryCount = times;
    if (times > MAX_RETRIES) {
      console.error(`[Redis] Max retries (${MAX_RETRIES}) reached. Giving up.`);
      return null; // stop retrying
    }
    const delay = Math.min(times * 200, 2_000); // exponential back-off, max 2s
    console.warn(`[Redis] Connection attempt ${times}. Retrying in ${delay}ms...`);
    return delay;
  },
});

redisClient.on('connect', () => {
  retryCount = 0;
  console.info('[Redis] Connected');
});

redisClient.on('error', (err: Error) => {
  console.error(`[Redis] Error: ${err.message}`);
});

redisClient.on('close', () => {
  console.warn('[Redis] Connection closed');
});

export { retryCount };
export default redisClient;
