# Health Checks and Connectivity Testing Guide

## Overview

This guide provides a comprehensive approach to implementing health check endpoints across all TypeRush services and creating a frontend connectivity dashboard to validate the entire infrastructure.

## Architecture Health Check Flow

```
Frontend Dashboard
    ↓
CloudFront → API Gateway
    ↓
    ├─→ /health/game     → VPC Link → Internal ALB → Game Service (ECS)
    ├─→ /health/record   → Direct Lambda → Record Service
    ├─→ /health/text     → Direct Lambda → Text Service
    └─→ /health/status   → Aggregated Health Status
```

---

## 1. Backend Service Health Endpoints

### 1.1 Game Service (Node.js + Express)

**Location**: `services/game-service/src/api/health.ts`

```typescript
import { Request, Response } from "express";
import { redisClient } from "../config/redis";
import { logger } from "../common/logger";

interface HealthCheck {
  status: "healthy" | "unhealthy";
  service: string;
  timestamp: string;
  checks: {
    redis?: { status: string; latency?: number };
    textService?: { status: string; latency?: number };
    recordService?: { status: string; latency?: number };
  };
  uptime: number;
  version: string;
}

export const healthCheck = async (req: Request, res: Response) => {
  const startTime = Date.now();
  const checks: HealthCheck["checks"] = {};
  let overallStatus: "healthy" | "unhealthy" = "healthy";

  try {
    // Check Redis connectivity
    const redisStart = Date.now();
    try {
      await redisClient.ping();
      checks.redis = {
        status: "healthy",
        latency: Date.now() - redisStart,
      };
    } catch (error) {
      checks.redis = { status: "unhealthy" };
      overallStatus = "unhealthy";
      logger.error("Redis health check failed:", error);
    }

    // Check Text Service Lambda connectivity
    const textServiceStart = Date.now();
    try {
      const response = await fetch(
        `${process.env.TEXT_SERVICE_ENDPOINT}/health`,
        { method: "GET", signal: AbortSignal.timeout(5000) }
      );
      checks.textService = {
        status: response.ok ? "healthy" : "unhealthy",
        latency: Date.now() - textServiceStart,
      };
      if (!response.ok) overallStatus = "unhealthy";
    } catch (error) {
      checks.textService = { status: "unhealthy" };
      overallStatus = "unhealthy";
      logger.error("Text Service health check failed:", error);
    }

    // Check Record Service Lambda connectivity
    const recordServiceStart = Date.now();
    try {
      const response = await fetch(
        `${process.env.RECORD_SERVICE_ENDPOINT}/health`,
        { method: "GET", signal: AbortSignal.timeout(5000) }
      );
      checks.recordService = {
        status: response.ok ? "healthy" : "unhealthy",
        latency: Date.now() - recordServiceStart,
      };
      if (!response.ok) overallStatus = "unhealthy";
    } catch (error) {
      checks.recordService = { status: "unhealthy" };
      overallStatus = "unhealthy";
      logger.error("Record Service health check failed:", error);
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
    logger.error("Health check error:", error);
    res.status(503).json({
      status: "unhealthy",
      service: "game-service",
      timestamp: new Date().toISOString(),
      error: "Internal health check error",
      uptime: process.uptime(),
      version: process.env.APP_VERSION || "1.0.0",
    });
  }
};

// Simple liveness probe (no dependencies)
export const livenessCheck = (req: Request, res: Response) => {
  res.status(200).json({
    status: "alive",
    service: "game-service",
    timestamp: new Date().toISOString(),
  });
};

// Readiness probe (checks if ready to serve traffic)
export const readinessCheck = async (req: Request, res: Response) => {
  try {
    // Check critical dependencies only
    await redisClient.ping();
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
    });
  }
};
```

**Router Configuration**: `services/game-service/src/router/health.router.ts`

```typescript
import { Router } from "express";
import { healthCheck, livenessCheck, readinessCheck } from "../api/health";

const router = Router();

router.get("/health", healthCheck); // Detailed health with all dependencies
router.get("/health/live", livenessCheck); // ALB target group health check
router.get("/health/ready", readinessCheck); // Kubernetes-style readiness

export default router;
```

**Environment Variables Required**:

```bash
REDIS_ENDPOINT=typerush-dev-game-cache.abc123.0001.apse1.cache.amazonaws.com:6379
REDIS_AUTH_TOKEN=<from-secrets-manager>
TEXT_SERVICE_ENDPOINT=https://api.typerush.com/api/text
RECORD_SERVICE_ENDPOINT=https://api.typerush.com/api/record
```

---

### 1.2 Record Service (NestJS + Prisma)

**Location**: `services/record-service/src/modules/health/health.controller.ts`

```typescript
import { Controller, Get } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Logger } from "@nestjs/common";

interface HealthCheckResponse {
  status: "healthy" | "unhealthy";
  service: string;
  timestamp: string;
  checks: {
    database?: { status: string; latency?: number };
  };
  version: string;
}

@Controller("health")
export class HealthController {
  private readonly logger = new Logger(HealthController.name);

  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async health(): Promise<HealthCheckResponse> {
    const checks: HealthCheckResponse["checks"] = {};
    let overallStatus: "healthy" | "unhealthy" = "healthy";

    try {
      // Check PostgreSQL database connectivity
      const dbStart = Date.now();
      try {
        await this.prisma.$queryRaw`SELECT 1`;
        checks.database = {
          status: "healthy",
          latency: Date.now() - dbStart,
        };
      } catch (error) {
        checks.database = { status: "unhealthy" };
        overallStatus = "unhealthy";
        this.logger.error("Database health check failed:", error);
      }

      const response: HealthCheckResponse = {
        status: overallStatus,
        service: "record-service",
        timestamp: new Date().toISOString(),
        checks,
        version: process.env.APP_VERSION || "1.0.0",
      };

      return response;
    } catch (error) {
      this.logger.error("Health check error:", error);
      return {
        status: "unhealthy",
        service: "record-service",
        timestamp: new Date().toISOString(),
        checks: {},
        version: process.env.APP_VERSION || "1.0.0",
      };
    }
  }

  @Get("live")
  liveness() {
    return {
      status: "alive",
      service: "record-service",
      timestamp: new Date().toISOString(),
    };
  }

  @Get("ready")
  async readiness() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: "ready",
        service: "record-service",
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      throw new Error("Not ready");
    }
  }
}
```

**Module Registration**: `services/record-service/src/modules/health/health.module.ts`

```typescript
import { Module } from "@nestjs/common";
import { HealthController } from "./health.controller";
import { PrismaModule } from "../../prisma/prisma.module";

@Module({
  imports: [PrismaModule],
  controllers: [HealthController],
})
export class HealthModule {}
```

**Environment Variables Required**:

```bash
DATABASE_URL=postgresql://postgres:<password>@typerush-dev-record-db.abc123.ap-southeast-1.rds.amazonaws.com:5432/typerush_records
```

---

### 1.3 Text Service (Python + FastAPI)

**Location**: `services/text-service/controllers/health.py`

```python
from fastapi import APIRouter, status, HTTPException
from pydantic import BaseModel
from typing import Dict, Optional
import time
import boto3
from datetime import datetime
import os

router = APIRouter(prefix="/health", tags=["health"])

class HealthCheck(BaseModel):
    status: str
    service: str
    timestamp: str
    checks: Dict[str, Dict[str, any]]
    version: str

@router.get("/", response_model=HealthCheck, status_code=status.HTTP_200_OK)
async def health_check():
    """
    Comprehensive health check with all dependencies
    """
    checks = {}
    overall_status = "healthy"

    try:
        # Check DynamoDB connectivity
        dynamodb_start = time.time()
        try:
            dynamodb = boto3.client('dynamodb', region_name=os.getenv('AWS_REGION', 'ap-southeast-1'))
            table_name = os.getenv('DYNAMODB_TEXTS_TABLE', 'typerush-dev-texts')
            response = dynamodb.describe_table(TableName=table_name)
            checks["dynamodb"] = {
                "status": "healthy",
                "latency": round((time.time() - dynamodb_start) * 1000, 2),
                "table_status": response['Table']['TableStatus']
            }
        except Exception as e:
            checks["dynamodb"] = {"status": "unhealthy", "error": str(e)}
            overall_status = "unhealthy"

        # Check Bedrock connectivity
        bedrock_start = time.time()
        try:
            bedrock = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_REGION', 'ap-southeast-1'))
            # Light check - just verify client initialization
            checks["bedrock"] = {
                "status": "healthy",
                "latency": round((time.time() - bedrock_start) * 1000, 2)
            }
        except Exception as e:
            checks["bedrock"] = {"status": "unhealthy", "error": str(e)}
            overall_status = "unhealthy"

        health_response = HealthCheck(
            status=overall_status,
            service="text-service",
            timestamp=datetime.utcnow().isoformat(),
            checks=checks,
            version=os.getenv('APP_VERSION', '1.0.0')
        )

        if overall_status == "unhealthy":
            raise HTTPException(status_code=503, detail=health_response.dict())

        return health_response

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "service": "text-service",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e),
                "version": os.getenv('APP_VERSION', '1.0.0')
            }
        )

@router.get("/live", status_code=status.HTTP_200_OK)
async def liveness_check():
    """
    Simple liveness probe - no dependencies checked
    """
    return {
        "status": "alive",
        "service": "text-service",
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/ready", status_code=status.HTTP_200_OK)
async def readiness_check():
    """
    Readiness probe - checks critical dependencies
    """
    try:
        # Quick DynamoDB check
        dynamodb = boto3.client('dynamodb', region_name=os.getenv('AWS_REGION', 'ap-southeast-1'))
        table_name = os.getenv('DYNAMODB_TEXTS_TABLE', 'typerush-dev-texts')
        dynamodb.describe_table(TableName=table_name)

        return {
            "status": "ready",
            "service": "text-service",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "not-ready",
                "service": "text-service",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e)
            }
        )
```

**Main Application Registration**: `services/text-service/main.py`

```python
from fastapi import FastAPI
from controllers.health import router as health_router

app = FastAPI(title="TypeRush Text Service")

# Register health check routes
app.include_router(health_router)

# Other routes...
```

**Environment Variables Required**:

```bash
AWS_REGION=ap-southeast-1
DYNAMODB_TEXTS_TABLE=typerush-dev-texts
BEDROCK_MODEL_ID=anthropic.claude-v2
```

---

## 2. API Gateway Health Aggregation Endpoint

**Purpose**: Aggregate health status from all backend services for frontend dashboard

**Implementation**: Add a new Lambda function `health-aggregator`

**Location**: `services/health-aggregator/index.js`

```javascript
const https = require("https");

// Helper function to make HTTP requests
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    https
      .get(url, { timeout: 5000 }, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            resolve({
              status: res.statusCode === 200 ? "healthy" : "unhealthy",
              statusCode: res.statusCode,
              latency: Date.now() - startTime,
              data: JSON.parse(data),
            });
          } catch (e) {
            resolve({
              status: "unhealthy",
              statusCode: res.statusCode,
              latency: Date.now() - startTime,
              error: "Invalid JSON response",
            });
          }
        });
      })
      .on("error", (err) => {
        resolve({
          status: "unhealthy",
          latency: Date.now() - startTime,
          error: err.message,
        });
      })
      .on("timeout", () => {
        resolve({
          status: "unhealthy",
          latency: Date.now() - startTime,
          error: "Request timeout",
        });
      });
  });
};

exports.handler = async (event) => {
  const baseUrl = process.env.API_BASE_URL; // https://api.typerush.com

  const checks = await Promise.allSettled([
    makeRequest(`${baseUrl}/api/game/health`),
    makeRequest(`${baseUrl}/api/record/health`),
    makeRequest(`${baseUrl}/api/text/health`),
  ]);

  const [gameHealth, recordHealth, textHealth] = checks.map((result) =>
    result.status === "fulfilled"
      ? result.value
      : { status: "unhealthy", error: "Promise rejected" }
  );

  const overallHealthy = [gameHealth, recordHealth, textHealth].every(
    (h) => h.status === "healthy"
  );

  const response = {
    status: overallHealthy ? "healthy" : "degraded",
    timestamp: new Date().toISOString(),
    services: {
      game: gameHealth,
      record: recordHealth,
      text: textHealth,
    },
    infrastructure: {
      cloudfront: "healthy", // Always healthy if request reached here
      apiGateway: "healthy", // Always healthy if Lambda was invoked
    },
  };

  return {
    statusCode: overallHealthy ? 200 : 503,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(response),
  };
};
```

**API Gateway Route**: `GET /health/status`

---

## 3. Frontend Connectivity Dashboard

**Location**: `frontend/src/pages/HealthDashboard.tsx`

```typescript
import React, { useEffect, useState } from "react";
import { Card, Badge, Spinner, Alert } from "react-bootstrap";

interface ServiceHealth {
  status: "healthy" | "unhealthy" | "degraded" | "checking";
  latency?: number;
  error?: string;
  checks?: Record<string, any>;
}

interface HealthStatus {
  status: string;
  timestamp: string;
  services: {
    game: ServiceHealth;
    record: ServiceHealth;
    text: ServiceHealth;
  };
  infrastructure: {
    cloudfront: string;
    apiGateway: string;
  };
}

const HealthDashboard: React.FC = () => {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastCheck, setLastCheck] = useState<Date | null>(null);

  const fetchHealthStatus = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch("/api/health/status", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data: HealthStatus = await response.json();
      setHealth(data);
      setLastCheck(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealthStatus();

    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchHealthStatus, 30000);

    return () => clearInterval(interval);
  }, []);

  const getStatusBadge = (status: string) => {
    const variants = {
      healthy: "success",
      unhealthy: "danger",
      degraded: "warning",
      checking: "secondary",
      alive: "info",
    };
    return (
      <Badge bg={variants[status] || "secondary"}>{status.toUpperCase()}</Badge>
    );
  };

  const getLatencyColor = (latency: number | undefined) => {
    if (!latency) return "text-muted";
    if (latency < 100) return "text-success";
    if (latency < 300) return "text-warning";
    return "text-danger";
  };

  if (loading && !health) {
    return (
      <div
        className="d-flex justify-content-center align-items-center"
        style={{ minHeight: "400px" }}
      >
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </div>
    );
  }

  return (
    <div className="container py-5">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1>System Health Dashboard</h1>
        <div>
          <button
            className="btn btn-primary me-2"
            onClick={fetchHealthStatus}
            disabled={loading}
          >
            {loading ? <Spinner size="sm" animation="border" /> : "Refresh"}
          </button>
          {lastCheck && (
            <small className="text-muted">
              Last checked: {lastCheck.toLocaleTimeString()}
            </small>
          )}
        </div>
      </div>

      {error && (
        <Alert variant="danger">
          <strong>Error:</strong> {error}
        </Alert>
      )}

      {health && (
        <>
          {/* Overall Status */}
          <Card className="mb-4">
            <Card.Body>
              <div className="d-flex justify-content-between align-items-center">
                <div>
                  <h3>Overall System Status</h3>
                  <p className="text-muted mb-0">
                    Last updated: {new Date(health.timestamp).toLocaleString()}
                  </p>
                </div>
                <div className="text-end">{getStatusBadge(health.status)}</div>
              </div>
            </Card.Body>
          </Card>

          {/* Infrastructure Services */}
          <h4 className="mb-3">Infrastructure</h4>
          <div className="row mb-4">
            <div className="col-md-6">
              <Card>
                <Card.Body>
                  <div className="d-flex justify-content-between align-items-center">
                    <div>
                      <h5 className="mb-1">CloudFront CDN</h5>
                      <small className="text-muted">Content Delivery</small>
                    </div>
                    {getStatusBadge(health.infrastructure.cloudfront)}
                  </div>
                </Card.Body>
              </Card>
            </div>
            <div className="col-md-6">
              <Card>
                <Card.Body>
                  <div className="d-flex justify-content-between align-items-center">
                    <div>
                      <h5 className="mb-1">API Gateway</h5>
                      <small className="text-muted">API Management</small>
                    </div>
                    {getStatusBadge(health.infrastructure.apiGateway)}
                  </div>
                </Card.Body>
              </Card>
            </div>
          </div>

          {/* Backend Services */}
          <h4 className="mb-3">Backend Services</h4>
          <div className="row">
            {/* Game Service */}
            <div className="col-md-4 mb-3">
              <Card
                className={
                  health.services.game.status === "unhealthy"
                    ? "border-danger"
                    : ""
                }
              >
                <Card.Body>
                  <div className="d-flex justify-content-between align-items-start mb-3">
                    <div>
                      <h5 className="mb-1">Game Service</h5>
                      <small className="text-muted">ECS Fargate</small>
                    </div>
                    {getStatusBadge(health.services.game.status)}
                  </div>

                  {health.services.game.latency && (
                    <p
                      className={`mb-2 ${getLatencyColor(
                        health.services.game.latency
                      )}`}
                    >
                      <strong>Latency:</strong> {health.services.game.latency}ms
                    </p>
                  )}

                  {health.services.game.checks && (
                    <div className="mt-3">
                      <h6 className="mb-2">Dependencies:</h6>
                      <ul className="list-unstyled mb-0">
                        {health.services.game.checks.redis && (
                          <li className="mb-1">
                            <span className="badge bg-secondary me-2">
                              Redis
                            </span>
                            {getStatusBadge(
                              health.services.game.checks.redis.status
                            )}
                            {health.services.game.checks.redis.latency && (
                              <small className="ms-2 text-muted">
                                {health.services.game.checks.redis.latency}ms
                              </small>
                            )}
                          </li>
                        )}
                        {health.services.game.checks.textService && (
                          <li className="mb-1">
                            <span className="badge bg-secondary me-2">
                              Text Service
                            </span>
                            {getStatusBadge(
                              health.services.game.checks.textService.status
                            )}
                          </li>
                        )}
                        {health.services.game.checks.recordService && (
                          <li className="mb-1">
                            <span className="badge bg-secondary me-2">
                              Record Service
                            </span>
                            {getStatusBadge(
                              health.services.game.checks.recordService.status
                            )}
                          </li>
                        )}
                      </ul>
                    </div>
                  )}

                  {health.services.game.error && (
                    <Alert variant="danger" className="mt-3 mb-0">
                      <small>{health.services.game.error}</small>
                    </Alert>
                  )}
                </Card.Body>
              </Card>
            </div>

            {/* Record Service */}
            <div className="col-md-4 mb-3">
              <Card
                className={
                  health.services.record.status === "unhealthy"
                    ? "border-danger"
                    : ""
                }
              >
                <Card.Body>
                  <div className="d-flex justify-content-between align-items-start mb-3">
                    <div>
                      <h5 className="mb-1">Record Service</h5>
                      <small className="text-muted">Lambda + RDS</small>
                    </div>
                    {getStatusBadge(health.services.record.status)}
                  </div>

                  {health.services.record.latency && (
                    <p
                      className={`mb-2 ${getLatencyColor(
                        health.services.record.latency
                      )}`}
                    >
                      <strong>Latency:</strong> {health.services.record.latency}
                      ms
                    </p>
                  )}

                  {health.services.record.checks && (
                    <div className="mt-3">
                      <h6 className="mb-2">Dependencies:</h6>
                      <ul className="list-unstyled mb-0">
                        {health.services.record.checks.database && (
                          <li className="mb-1">
                            <span className="badge bg-secondary me-2">
                              PostgreSQL
                            </span>
                            {getStatusBadge(
                              health.services.record.checks.database.status
                            )}
                            {health.services.record.checks.database.latency && (
                              <small className="ms-2 text-muted">
                                {health.services.record.checks.database.latency}
                                ms
                              </small>
                            )}
                          </li>
                        )}
                      </ul>
                    </div>
                  )}

                  {health.services.record.error && (
                    <Alert variant="danger" className="mt-3 mb-0">
                      <small>{health.services.record.error}</small>
                    </Alert>
                  )}
                </Card.Body>
              </Card>
            </div>

            {/* Text Service */}
            <div className="col-md-4 mb-3">
              <Card
                className={
                  health.services.text.status === "unhealthy"
                    ? "border-danger"
                    : ""
                }
              >
                <Card.Body>
                  <div className="d-flex justify-content-between align-items-start mb-3">
                    <div>
                      <h5 className="mb-1">Text Service</h5>
                      <small className="text-muted">Lambda + DynamoDB</small>
                    </div>
                    {getStatusBadge(health.services.text.status)}
                  </div>

                  {health.services.text.latency && (
                    <p
                      className={`mb-2 ${getLatencyColor(
                        health.services.text.latency
                      )}`}
                    >
                      <strong>Latency:</strong> {health.services.text.latency}ms
                    </p>
                  )}

                  {health.services.text.checks && (
                    <div className="mt-3">
                      <h6 className="mb-2">Dependencies:</h6>
                      <ul className="list-unstyled mb-0">
                        {health.services.text.checks.dynamodb && (
                          <li className="mb-1">
                            <span className="badge bg-secondary me-2">
                              DynamoDB
                            </span>
                            {getStatusBadge(
                              health.services.text.checks.dynamodb.status
                            )}
                            {health.services.text.checks.dynamodb.latency && (
                              <small className="ms-2 text-muted">
                                {health.services.text.checks.dynamodb.latency}ms
                              </small>
                            )}
                          </li>
                        )}
                        {health.services.text.checks.bedrock && (
                          <li className="mb-1">
                            <span className="badge bg-secondary me-2">
                              Bedrock AI
                            </span>
                            {getStatusBadge(
                              health.services.text.checks.bedrock.status
                            )}
                          </li>
                        )}
                      </ul>
                    </div>
                  )}

                  {health.services.text.error && (
                    <Alert variant="danger" className="mt-3 mb-0">
                      <small>{health.services.text.error}</small>
                    </Alert>
                  )}
                </Card.Body>
              </Card>
            </div>
          </div>

          {/* Connection Map */}
          <Card className="mt-4">
            <Card.Header>
              <h5 className="mb-0">Service Connectivity Map</h5>
            </Card.Header>
            <Card.Body>
              <div
                className="text-center p-4"
                style={{ fontFamily: "monospace" }}
              >
                <pre className="text-start">
                  {`
┌─────────────────┐
│   Frontend      │ ${health.status === "healthy" ? "✓" : "✗"}
└────────┬────────┘
         │
    CloudFront ${health.infrastructure.cloudfront === "healthy" ? "✓" : "✗"}
         │
    API Gateway ${health.infrastructure.apiGateway === "healthy" ? "✓" : "✗"}
         │
         ├─────────────┬─────────────┬─────────────┐
         │             │             │             │
   ┌─────▼──────┐ ┌───▼────┐  ┌────▼─────┐  ┌────▼─────┐
   │ Game Svc   │ │ Record │  │   Text   │  │  Health  │
   │   (ECS)    │ │(Lambda)│  │ (Lambda) │  │Aggregator│
   │     ${health.services.game.status === "healthy" ? "✓" : "✗"}      │ │   ${
                    health.services.record.status === "healthy" ? "✓" : "✗"
                  }    │  │    ${
                    health.services.text.status === "healthy" ? "✓" : "✗"
                  }     │  │    ✓     │
   └─────┬──────┘ └───┬────┘  └────┬─────┘  └──────────┘
         │            │             │
    ┌────▼───┐   ┌───▼──────┐ ┌────▼────────┐
    │ Redis  │   │PostgreSQL│ │  DynamoDB   │
    │   ${
      health.services.game.checks?.redis?.status === "healthy" ? "✓" : "✗"
    }    │   │    ${
                    health.services.record.checks?.database?.status ===
                    "healthy"
                      ? "✓"
                      : "✗"
                  }     │ │      ${
                    health.services.text.checks?.dynamodb?.status === "healthy"
                      ? "✓"
                      : "✗"
                  }      │
    └────────┘   └──────────┘ └─────┬───────┘
                                     │
                               ┌─────▼──────┐
                               │  Bedrock   │
                               │      ${
                                 health.services.text.checks?.bedrock
                                   ?.status === "healthy"
                                   ? "✓"
                                   : "✗"
                               }     │
                               └────────────┘
`}
                </pre>
              </div>
            </Card.Body>
          </Card>
        </>
      )}
    </div>
  );
};

export default HealthDashboard;
```

---

## 4. ALB Target Group Health Check Configuration

**Terraform Configuration**: Update in `modules/11-alb/main.tf`

```hcl
resource "aws_lb_target_group" "game_service" {
  name        = "${var.project_name}-${var.environment}-game-tg"
  port        = var.game_service_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health/live"  # Use liveness endpoint
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-game-tg"
    }
  )
}
```

---

## 5. Testing Checklist

### 5.1 Individual Service Tests

```bash
# Test Game Service
curl https://api.typerush.com/api/game/health
curl https://api.typerush.com/api/game/health/live
curl https://api.typerush.com/api/game/health/ready

# Test Record Service
curl https://api.typerush.com/api/record/health
curl https://api.typerush.com/api/record/health/live
curl https://api.typerush.com/api/record/health/ready

# Test Text Service
curl https://api.typerush.com/api/text/health
curl https://api.typerush.com/api/text/health/live
curl https://api.typerush.com/api/text/health/ready

# Test Health Aggregator
curl https://api.typerush.com/api/health/status
```

### 5.2 Dependency Tests

**Test Redis Connectivity (Game Service)**:

```bash
# SSH into ECS task or use ECS Exec
aws ecs execute-command --cluster typerush-cluster \
  --task <task-id> \
  --container game-service \
  --interactive \
  --command "redis-cli -h $REDIS_ENDPOINT -a $REDIS_AUTH_TOKEN ping"
```

**Test RDS Connectivity (Record Service)**:

```bash
# Test from Lambda (via CloudWatch Logs or Lambda console test)
# Or test locally with connection string
psql postgresql://postgres:<password>@typerush-dev-record-db.abc123.ap-southeast-1.rds.amazonaws.com:5432/typerush_records -c "SELECT 1"
```

**Test DynamoDB Connectivity (Text Service)**:

```bash
# Test from Lambda or local
aws dynamodb describe-table --table-name typerush-dev-texts
```

### 5.3 End-to-End Tests

1. **Access Frontend Dashboard**: Navigate to `https://typerush.com/health`
2. **Verify All Services Green**: All services should show "HEALTHY"
3. **Check Latency Values**: All should be < 300ms
4. **Test Auto-Refresh**: Wait 30 seconds to see auto-refresh
5. **Test Manual Refresh**: Click "Refresh" button
6. **Simulate Failure**: Stop one service and verify dashboard shows degraded state

---

## 6. Monitoring and Alerting

### 6.1 CloudWatch Alarms for Health Checks

**Terraform Configuration**: Add to `modules/21-cloudwatch/main.tf`

```hcl
# Game Service Unhealthy Alarm
resource "aws_cloudwatch_metric_alarm" "game_service_unhealthy" {
  alarm_name          = "${var.project_name}-${var.environment}-game-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Game Service target group has unhealthy targets"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.game_service.arn_suffix
    LoadBalancer = aws_lb.internal.arn_suffix
  }
}

# Record Service Lambda Errors
resource "aws_cloudwatch_metric_alarm" "record_service_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-record-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Record Service Lambda has too many errors"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = "typerush-record-api"
  }
}
```

---

## 7. Environment Variables Summary

### Game Service (ECS)

```bash
NODE_ENV=production
PORT=3000
REDIS_ENDPOINT=<from-terraform-output>
REDIS_AUTH_TOKEN=<from-secrets-manager>
TEXT_SERVICE_ENDPOINT=https://api.typerush.com/api/text
RECORD_SERVICE_ENDPOINT=https://api.typerush.com/api/record
APP_VERSION=1.0.0
```

### Record Service (Lambda)

```bash
NODE_ENV=production
DATABASE_URL=<from-secrets-manager>
APP_VERSION=1.0.0
```

### Text Service (Lambda)

```bash
AWS_REGION=ap-southeast-1
DYNAMODB_TEXTS_TABLE=<from-terraform-output>
BEDROCK_MODEL_ID=anthropic.claude-v2
APP_VERSION=1.0.0
```

---

## 8. Implementation Order

1. ✅ **Backend Health Endpoints** (Game, Record, Text Services)
2. ✅ **ALB Health Check Configuration**
3. ✅ **Lambda Health Aggregator Function**
4. ✅ **API Gateway Routes** (`/api/health/status`)
5. ✅ **Frontend Dashboard Component**
6. ✅ **CloudWatch Alarms**
7. ✅ **Integration Testing**
8. ✅ **Documentation Updates**

---

## 9. Troubleshooting Guide

### Common Issues

**Issue**: Health endpoint returns 503

- **Check**: ECS task logs, Lambda logs
- **Verify**: Security group rules allow traffic
- **Test**: Direct connection to dependencies (Redis, RDS, DynamoDB)

**Issue**: High latency on health checks

- **Check**: VPC endpoint connectivity
- **Verify**: NAT Gateway performance
- **Test**: Network path with traceroute

**Issue**: Dashboard shows "unhealthy" but service works

- **Check**: Health check logic is too strict
- **Verify**: Timeout values are reasonable
- **Adjust**: Increase timeout or reduce dependency checks

---

This comprehensive guide provides everything needed to implement health checks across all TypeRush services and create a frontend connectivity dashboard for monitoring system health.
