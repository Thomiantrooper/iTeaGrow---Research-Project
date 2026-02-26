from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from database import connect_to_mongo, close_mongo_connection
from routers import users, disease, iot, inference, chatbot, bluetooth, analytics, reports, wifi_devices
from config import settings
import logging

log = logging.getLogger("main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await connect_to_mongo()

    # Start MQTT bridge in background (connects to HiveMQ Cloud → writes to MongoDB)
    try:
        from mqtt_bridge import get_bridge
        _bridge = get_bridge()
        _bridge.start_background()
        log.info("MQTT Bridge started successfully")
    except Exception as exc:
        log.warning("MQTT Bridge could not start (non-fatal): %s", exc)
        _bridge = None

    yield

    # Shutdown
    if _bridge:
        _bridge.stop()
    await close_mongo_connection()

app = FastAPI(
    title="iTeaGrow API",
    description="Backend API for iTeaGrow Tea Leaf Management System",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router)
app.include_router(disease.router)
app.include_router(iot.router)
app.include_router(inference.router)
app.include_router(chatbot.router)  # AI Tea Expert chatbot
app.include_router(bluetooth.router)  # Bluetooth IoT for offline sensors
app.include_router(analytics.router)  # Admin analytics and statistics
app.include_router(reports.router)    # Report generation data
app.include_router(wifi_devices.router)  # WiFi IoT device communication

@app.get("/")
async def root():
    return {
        "message": "Welcome to iTeaGrow API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
