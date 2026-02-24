from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from app.api import routes
from app.mqtt.client import mqtt_client
from app.database import mongodb
from app.config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Tea IoT Backend",
    description="IoT Backend for Tea Plantation Soil Monitoring",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(routes.router)

@app.on_event("startup")
async def startup_event():
    """Startup tasks"""
    logger.info("🚀 Starting Tea IoT Backend...")
    
    # Start MQTT client
    try:
        mqtt_client.start()
    except Exception as e:
        logger.error(f"Failed to start MQTT client: {e}")
    
    logger.info("✅ Application startup complete")

@app.on_event("shutdown")
async def shutdown_event():
    """Shutdown tasks"""
    logger.info("🛑 Shutting down Tea IoT Backend...")
    
    # Stop MQTT client
    mqtt_client.stop()
    
    # Close database connection
    mongodb.close()
    
    logger.info("👋 Application shutdown complete")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Tea IoT Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }