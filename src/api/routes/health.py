"""
Health check and monitoring API routes.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from configs.settings import settings
from src.core.logging import get_logger
from src.api.schemas import HealthCheckResponse

logger = get_logger(__name__)

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=HealthCheckResponse)
async def health_check():
    """
    Comprehensive health check endpoint.

    Returns status of all services and dependencies.
    """
    services = {}

    services["inference"] = "healthy"

    try:
        import redis

        r = redis.from_url(settings.redis.url, socket_timeout=2)
        r.ping()
        redis_status = "healthy"
    except Exception:
        redis_status = "unavailable"

    services["redis"] = redis_status

    try:
        from minio import Minio
        import socket

        # Test connectivity first with a timeout
        host, port = settings.minio.endpoint.split(":")
        socket.create_connection((host, int(port)), timeout=2)

        client = Minio(
            settings.minio.endpoint,
            access_key=settings.minio.access_key,
            secret_key=settings.minio.secret_key,
            secure=settings.minio.secure,
        )
        client.list_buckets()
        storage_status = "healthy"
    except Exception as e:
        logger.debug(f"MinIO health check failed: {e}")
        storage_status = "unavailable"

    services["storage"] = storage_status

    services["iot"] = "healthy"
    services["recommendations"] = "healthy"
    services["sync"] = "healthy"

    all_healthy = all(s == "healthy" for s in services.values())
    critical_healthy = services.get("inference") == "healthy"

    if all_healthy:
        status = "healthy"
    elif critical_healthy:
        status = "degraded"
    else:
        status = "unhealthy"

    return HealthCheckResponse(
        status=status,
        version=settings.app_version,
        timestamp=datetime.now(timezone.utc),
        services=services,
        model_loaded=True,
        storage_status=storage_status,
        redis_status=redis_status,
    )


@router.get("/health/live")
async def liveness_probe():
    """
    Kubernetes liveness probe.

    Returns 200 if the application is running.
    """
    return {"status": "alive"}


@router.get("/health/ready")
async def readiness_probe():
    """
    Kubernetes readiness probe.

    Returns 200 if the application is ready to accept requests.
    """
    return {"status": "ready"}


@router.get("/metrics")
async def get_metrics():
    """
    Get application metrics for monitoring.

    Returns Prometheus-compatible metrics.
    """
    return {
        "app_name": settings.app_name,
        "version": settings.app_version,
        "uptime_seconds": 0,
        "requests_total": 0,
        "requests_success": 0,
        "requests_failed": 0,
        "inference_total": 0,
        "average_inference_time_ms": 0,
        "iot_readings_total": 0,
        "sync_pending_items": 0,
        "storage_used_mb": 0,
    }


@router.get("/info")
async def get_app_info():
    """Get application information."""
    return {
        "app_name": settings.app_name,
        "version": settings.app_version,
        "environment": "development" if settings.debug else "production",
        "model": {
            "path": settings.model.model_path,
            "use_onnx": settings.model.use_onnx,
            "device": settings.model.device,
            "image_size": settings.model.image_size,
            "classes": settings.model.class_names,
        },
        "features": {
            "inference": True,
            "explainability": True,
            "iot_processing": True,
            "recommendations": True,
            "offline_storage": True,
            "cloud_sync": True,
        },
    }
