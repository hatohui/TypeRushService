import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

interface HealthCheckResponse {
  status: 'healthy' | 'unhealthy';
  service: string;
  timestamp: string;
  checks: {
    database?: { status: string; latency?: number; error?: string };
  };
  version: string;
}

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Comprehensive health check with all dependencies
   * GET /health
   */
  @Get()
  async health(): Promise<HealthCheckResponse> {
    const checks: HealthCheckResponse['checks'] = {};
    let overallStatus: 'healthy' | 'unhealthy' = 'healthy';

    try {
      // Check PostgreSQL database connectivity
      const dbStart = Date.now();
      try {
        await this.prisma.$queryRaw`SELECT 1`;
        checks.database = {
          status: 'healthy',
          latency: Date.now() - dbStart,
        };
      } catch (error) {
        checks.database = {
          status: 'unhealthy',
          error: error instanceof Error ? error.message : 'Unknown error',
        };
        overallStatus = 'unhealthy';
      }

      const response: HealthCheckResponse = {
        status: overallStatus,
        service: 'record-service',
        timestamp: new Date().toISOString(),
        checks,
        version: process.env.APP_VERSION || '1.0.0',
      };

      return response;
    } catch (error) {
      return {
        status: 'unhealthy',
        service: 'record-service',
        timestamp: new Date().toISOString(),
        checks,
        version: process.env.APP_VERSION || '1.0.0',
      };
    }
  }

  /**
   * Simple liveness probe - no dependencies checked
   * GET /health/live
   */
  @Get('live')
  liveness() {
    return {
      status: 'alive',
      service: 'record-service',
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Readiness probe - checks if ready to serve traffic
   * GET /health/ready
   */
  @Get('ready')
  async readiness() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ready',
        service: 'record-service',
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      throw new Error('Not ready');
    }
  }
}
