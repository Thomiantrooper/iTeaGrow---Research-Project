"""
Main FastAPI application for Tea Leaf Disease Detection Platform.
"""

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.openapi.utils import get_openapi

from configs.settings import settings
from src.core.logging import setup_logging, get_logger
from src.core.exceptions import BaseAppException
from src.core.database import connect_to_mongodb, close_mongodb_connection
from src.api.middleware import (
    RequestLoggingMiddleware,
    RateLimitMiddleware,
    SecurityHeadersMiddleware,
)
from src.api.routes import inference, iot, recommendations, sync, health, feedback, chatbot, bluetooth

setup_logging(log_level=settings.log_level, json_format=not settings.debug)
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Application lifespan manager for startup and shutdown events."""
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")

    # Connect to MongoDB
    try:
        await connect_to_mongodb()
        logger.info("MongoDB connected successfully")
    except Exception as e:
        logger.warning(f"Failed to connect to MongoDB: {e}")
        logger.warning("Application will run without database persistence")

    # Load disease detection model
    try:
        from src.services.inference import TeaLeafDetector
        detector = TeaLeafDetector()
        app.state.detector = detector
        logger.info("Disease detection model loaded successfully")
    except Exception as e:
        logger.warning(f"Failed to preload model: {e}")

    # Initialize local storage
    try:
        from src.services.sync import LocalStorageManager
        storage = LocalStorageManager()
        app.state.storage = storage
        logger.info("Local storage initialized")
    except Exception as e:
        logger.warning(f"Failed to initialize local storage: {e}")

    logger.info("Application startup complete")

    yield

    # Shutdown
    logger.info("Application shutdown initiated")

    # Close MongoDB connection
    try:
        await close_mongodb_connection()
    except Exception as e:
        logger.warning(f"Error closing MongoDB: {e}")

    logger.info("Application shutdown complete")


def create_application() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="""
## Smart Tea Leaf Disease Detection and Monitoring Platform

A production-ready backend system for detecting and managing tea leaf diseases
in Sri Lankan plantations using AI-powered image analysis.

### Features
- **Disease Detection**: YOLOv8n-based multi-leaf object detection
- **AI Chatbot**: Tea plantation expert powered by Ollama LLM 🤖
- **Explainability**: Grad-CAM visual explanations for predictions
- **IoT Integration**: Environmental sensor data processing
- **Recommendations**: Rule-based disease management advice
- **Offline-First**: Local storage with automatic cloud sync

### Disease Classes
- Healthy leaves
- Red Rust (Cephaleuros virescens)
- Blister Blight (Exobasidium vexans)

### API Groups
- `/api/v1/inference`: Disease detection endpoints
- `/api/v1/chatbot`: AI tea expert chatbot (NEW!)
- `/api/v1/iot`: Sensor data ingestion
- `/api/v1/recommendations`: Treatment recommendations
- `/api/v1/sync`: Data synchronization
- `/api/v1/feedback`: User feedback for retraining
        """,
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        openapi_url="/openapi.json" if settings.debug else None,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.security.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(RateLimitMiddleware)
    app.add_middleware(RequestLoggingMiddleware)

    app.include_router(health.router)
    app.include_router(inference.router)
    app.include_router(iot.router)
    app.include_router(recommendations.router)
    app.include_router(sync.router)
    app.include_router(feedback.router)
    app.include_router(chatbot.router)  # Tea plantation expert chatbot
    app.include_router(bluetooth.router)  # Bluetooth IoT for offline sensor data

    @app.exception_handler(BaseAppException)
    async def app_exception_handler(request: Request, exc: BaseAppException):
        """Handle custom application exceptions."""
        return JSONResponse(
            status_code=exc.status_code,
            content=exc.to_dict(),
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        """Handle unexpected exceptions."""
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "error": True,
                "error_code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred",
            },
        )

    @app.get("/", tags=["Root"])
    async def root():
        """Root endpoint with API information."""
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "status": "operational",
            "docs": "/docs" if settings.debug else "disabled",
            "health": "/health",
        }

    return app


app = create_application()


def custom_openapi():
    """Generate custom OpenAPI schema."""
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=settings.app_name,
        version=settings.app_version,
        description=app.description,
        routes=app.routes,
    )

    openapi_schema["info"]["x-logo"] = {
        "url": "https://example.com/logo.png"
    }

    openapi_schema["tags"] = [
        {
            "name": "Health",
            "description": "Health check and monitoring endpoints",
        },
        {
            "name": "Inference",
            "description": "Disease detection and model inference",
        },
        {
            "name": "IoT",
            "description": "Environmental sensor data processing",
        },
        {
            "name": "Recommendations",
            "description": "Disease management recommendations",
        },
        {
            "name": "Sync",
            "description": "Data synchronization and storage",
        },
        {
            "name": "Feedback",
            "description": "User feedback for model improvement",
        },
    ]

    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "src.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        workers=1 if settings.debug else settings.workers,
        log_level=settings.log_level.lower(),
    )
