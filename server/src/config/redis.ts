import Redis from 'ioredis';
import { env } from './env';

let redisClient: Redis | null = null;

function getRedisClient(): Redis | null {
  if (redisClient) return redisClient;

  const url = env.redisUrl;
  if (!url || url === 'redis://localhost:6379') {
    return null;
  }

  try {
    redisClient = new Redis(url, {
      maxRetriesPerRequest: 1,
      retryStrategy(times) {
        if (times > 3) return null;
        return Math.min(times * 200, 1000);
      },
      lazyConnect: true,
    });

    redisClient.on('error', () => {
      redisClient = null;
    });

    return redisClient;
  } catch {
    return null;
  }
}

async function pingRedis(): Promise<boolean> {
  const client = getRedisClient();
  if (!client) return false;
  try {
    await client.ping();
    return true;
  } catch {
    return false;
  }
}

export { getRedisClient, pingRedis };
