from fastapi import APIRouter, status, HTTPException
from pydantic import BaseModel
from typing import Dict, Optional, Any
import time
import boto3
from datetime import datetime
import os

router = APIRouter(prefix="/health", tags=["health"])


class HealthCheck(BaseModel):
    status: str
    service: str
    timestamp: str
    checks: Dict[str, Dict[str, Any]]
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
            dynamodb = boto3.client(
                "dynamodb", region_name=os.getenv("AWS_REGION", "ap-southeast-1")
            )
            table_name = os.getenv("DYNAMODB_TABLE_NAME", "typerush-dev-texts")
            dynamodb.describe_table(TableName=table_name)
            checks["dynamodb"] = {
                "status": "healthy",
                "latency": round((time.time() - dynamodb_start) * 1000, 2),
            }
        except Exception as e:
            checks["dynamodb"] = {"status": "unhealthy", "error": str(e)}
            overall_status = "unhealthy"

        # Check Bedrock connectivity
        bedrock_start = time.time()
        try:
            bedrock = boto3.client(
                "bedrock-runtime", region_name=os.getenv("AWS_REGION", "ap-southeast-1")
            )
            # Just verify client creation (no actual invocation to avoid costs)
            checks["bedrock"] = {
                "status": "healthy",
                "latency": round((time.time() - bedrock_start) * 1000, 2),
            }
        except Exception as e:
            checks["bedrock"] = {"status": "unhealthy", "error": str(e)}
            overall_status = "unhealthy"

        health_response = HealthCheck(
            status=overall_status,
            service="text-service",
            timestamp=datetime.utcnow().isoformat(),
            checks=checks,
            version=os.getenv("APP_VERSION", "1.0.0"),
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
                "checks": checks,
                "version": os.getenv("APP_VERSION", "1.0.0"),
                "error": str(e),
            },
        )


@router.get("/live", status_code=status.HTTP_200_OK)
async def liveness_check():
    """
    Simple liveness probe - no dependencies checked
    """
    return {
        "status": "alive",
        "service": "text-service",
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/ready", status_code=status.HTTP_200_OK)
async def readiness_check():
    """
    Readiness probe - checks critical dependencies
    """
    try:
        # Quick DynamoDB check
        dynamodb = boto3.client(
            "dynamodb", region_name=os.getenv("AWS_REGION", "ap-southeast-1")
        )
        table_name = os.getenv("DYNAMODB_TABLE_NAME", "typerush-dev-texts")
        dynamodb.describe_table(TableName=table_name)

        return {
            "status": "ready",
            "service": "text-service",
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "not-ready",
                "service": "text-service",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e),
            },
        )
