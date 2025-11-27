import { Request, Response } from "express";
import { getRedisClient } from "../config/redis.js";

interface HealthCheck {
  status: "healthy" | "unhealthy";
  service: string;
  timestamp: string;
  checks: {
    redis?: { status: string; latency?: number; error?: string };
    textService?: { status: string; latency?: number; error?: string };
    recordService?: { status: string; latency?: number; error?: string };
  };
  uptime: number;
  version: string;
}

/**
 * Comprehensive health check with all dependencies
 * Used by: Frontend dashboard, monitoring systems
 */
export const health = async (req: Request, res: Response) => {
  const startTime = Date.now();
  const checks: HealthCheck["checks"] = {};
  let overallStatus: "healthy" | "unhealthy" = "healthy";

  try {
    // Check Redis connectivity (if configured)
    const redisClient = getRedisClient();
    if (redisClient) {
      const redisStart = Date.now();
      try {
        await redisClient.ping();
        checks.redis = {
          status: "healthy",
          latency: Date.now() - redisStart,
        };
      } catch (error) {
        checks.redis = {
          status: "unhealthy",
          error: error instanceof Error ? error.message : "Unknown error",
        };
        overallStatus = "unhealthy";
      }
    }

    // Check Text Service Lambda connectivity (if configured)
    if (process.env.TEXT_SERVICE_ENDPOINT) {
      const textServiceStart = Date.now();
      try {
        const response = await fetch(`${process.env.TEXT_SERVICE_ENDPOINT}/health`, {
          signal: AbortSignal.timeout(3000),
        });
        checks.textService = {
          status: response.ok ? "healthy" : "unhealthy",
          latency: Date.now() - textServiceStart,
        };
        if (!response.ok) overallStatus = "unhealthy";
      } catch (error) {
        checks.textService = {
          status: "unhealthy",
          error: error instanceof Error ? error.message : "Unknown error",
        };
        overallStatus = "unhealthy";
      }
    }

    // Check Record Service Lambda connectivity (if configured)
    if (process.env.RECORD_SERVICE_ENDPOINT) {
      const recordServiceStart = Date.now();
      try {
        const response = await fetch(`${process.env.RECORD_SERVICE_ENDPOINT}/health`, {
          signal: AbortSignal.timeout(3000),
        });
        checks.recordService = {
          status: response.ok ? "healthy" : "unhealthy",
          latency: Date.now() - recordServiceStart,
        };
        if (!response.ok) overallStatus = "unhealthy";
      } catch (error) {
        checks.recordService = {
          status: "unhealthy",
          error: error instanceof Error ? error.message : "Unknown error",
        };
        overallStatus = "unhealthy";
      }
    }

    const healthResponse: HealthCheck = {
      status: overallStatus,
      service: "game-service",
      timestamp: new Date().toISOString(),
      checks,
      uptime: process.uptime(),
      version: process.env.APP_VERSION || "1.0.0",
    };

    const statusCode = overallStatus === "healthy" ? 200 : 503;
    res.status(statusCode).json(healthResponse);
  } catch (error) {
    res.status(503).json({
      status: "unhealthy",
      service: "game-service",
      timestamp: new Date().toISOString(),
      checks,
      uptime: process.uptime(),
      version: process.env.APP_VERSION || "1.0.0",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Simple liveness probe - no dependencies checked
 * Used by: ALB target group health checks
 */
export const liveness = (req: Request, res: Response) => {
  res.status(200).json({
    status: "alive",
    service: "game-service",
    timestamp: new Date().toISOString(),
  });
};

/**
 * Readiness probe - checks if ready to serve traffic
 * Used by: Kubernetes-style orchestration (future)
 */
export const readiness = async (req: Request, res: Response) => {
  try {
    // Check critical dependencies only (Redis if configured)
    const redisClient = getRedisClient();
    if (redisClient) {
      await redisClient.ping();
    }
    res.status(200).json({
      status: "ready",
      service: "game-service",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: "not-ready",
      service: "game-service",
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
