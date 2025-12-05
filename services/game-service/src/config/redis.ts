import { Redis } from "ioredis";

let redisClient: Redis | null = null;

/**
 * Get or create Redis client instance
 * Only creates client if REDIS_ENDPOINT is configured
 */
export function getRedisClient(): Redis | null {
  if (!process.env.REDIS_ENDPOINT) {
    return null;
  }

  if (!redisClient) {
    const [host, port] = process.env.REDIS_ENDPOINT.split(":");

    redisClient = new Redis({
      host,
      port: parseInt(port || "6379", 10),
      password: process.env.REDIS_AUTH_TOKEN,
      retryStrategy: (times: number) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      maxRetriesPerRequest: 3,
      enableReadyCheck: true,
      lazyConnect: false,
    });

    redisClient.on("error", (err: Error) => {
      console.error("Redis connection error:", err);
    });

    redisClient.on("connect", () => {
      console.log("Redis connected successfully");
    });
  }

  return redisClient;
}

/**
 * Close Redis connection gracefully
 */
export async function closeRedisClient(): Promise<void> {
  if (redisClient) {
    await redisClient.quit();
    redisClient = null;
  }
}
