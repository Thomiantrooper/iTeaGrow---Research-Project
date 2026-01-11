"""
Middleware components for the FastAPI application.
"""

import time
import uuid
from typing import Callable

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, JSONResponse

from configs.settings import settings
from src.core.logging import get_logger, RequestLogger
from src.core.security import rate_limiter

logger = get_logger(__name__)
request_logger = RequestLogger(logger)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware for logging HTTP requests and responses."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id

        start_time = time.perf_counter()

        client_ip = request.client.host if request.client else "unknown"
        request_logger.log_request(
            method=request.method,
            path=request.url.path,
            client_ip=client_ip,
            request_id=request_id,
        )

        try:
            response = await call_next(request)
        except Exception as e:
            logger.error(
                f"Request {request_id} failed with error: {str(e)}",
                exc_info=True,
            )
            response = JSONResponse(
                status_code=500,
                content={
                    "error": True,
                    "error_code": "INTERNAL_ERROR",
                    "message": "An internal error occurred",
                    "request_id": request_id,
                },
            )

        duration_ms = (time.perf_counter() - start_time) * 1000

        request_logger.log_response(
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=duration_ms,
            request_id=request_id,
        )

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time"] = f"{duration_ms:.2f}ms"

        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Middleware for rate limiting API requests."""

    EXEMPT_PATHS = {"/health", "/metrics", "/docs", "/redoc", "/openapi.json"}

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        if request.url.path in self.EXEMPT_PATHS:
            return await call_next(request)

        api_key = request.headers.get(settings.security.api_key_header)
        if api_key:
            rate_key = f"api_key:{api_key[:16]}"
        else:
            client_ip = request.client.host if request.client else "unknown"
            rate_key = f"ip:{client_ip}"

        if not rate_limiter.is_allowed(rate_key):
            remaining = rate_limiter.get_remaining(rate_key)
            return JSONResponse(
                status_code=429,
                content={
                    "error": True,
                    "error_code": "RATE_LIMIT_EXCEEDED",
                    "message": "Too many requests. Please slow down.",
                    "retry_after": settings.security.rate_limit_window,
                },
                headers={
                    "Retry-After": str(settings.security.rate_limit_window),
                    "X-RateLimit-Remaining": str(remaining),
                },
            )

        response = await call_next(request)

        remaining = rate_limiter.get_remaining(rate_key)
        response.headers["X-RateLimit-Limit"] = str(settings.security.rate_limit_requests)
        response.headers["X-RateLimit-Remaining"] = str(remaining)

        return response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Middleware for adding security headers."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)

        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"

        return response
