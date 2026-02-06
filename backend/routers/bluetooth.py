"""
Bluetooth IoT API Routes for offline sensor data collection
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from database import get_database

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/bluetooth", tags=["Bluetooth IoT"])

# Bluetooth configuration
BLUETOOTH_CONFIG = {
    "enabled": True,
    "service_uuid": "4fafc201-1fb5-459e-8fcc-c5c9c331914b",
    "characteristic_uuid": "beb5483e-36e1-4688-b7f5-ea07361b26a8",
    "scan_timeout": 10,
    "connection_timeout": 30,
    "auto_reconnect": True,
}


# Request/Response Models
class DeviceRegistrationRequest(BaseModel):
    device_id: str = Field(..., description="Unique device identifier")
    device_name: str = Field(..., description="Human-readable name")
    mac_address: Optional[str] = None
    device_type: str = "sensor"
    location: Optional[str] = None


class SensorDataRequest(BaseModel):
    device_id: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    light_level: Optional[float] = None
    battery_level: Optional[int] = None
    rssi: Optional[int] = None
    timestamp: Optional[datetime] = None
    collected_offline: bool = True


class BatchSyncRequest(BaseModel):
    user_id: Optional[str] = None
    readings: List[SensorDataRequest]


@router.get("/config")
async def get_bluetooth_config():
    """Get Bluetooth configuration for mobile app."""
    return BLUETOOTH_CONFIG


@router.post("/devices/register")
async def register_device(request: DeviceRegistrationRequest):
    """Register a new Bluetooth IoT device."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    try:
        existing = await db.bluetooth_devices.find_one({"device_id": request.device_id})

        if existing:
            await db.bluetooth_devices.update_one(
                {"device_id": request.device_id},
                {"$set": {
                    "device_name": request.device_name,
                    "last_seen": datetime.utcnow(),
                    "is_active": True
                }}
            )
            return {"success": True, "action": "updated", "device_id": request.device_id}
        else:
            await db.bluetooth_devices.insert_one({
                "device_id": request.device_id,
                "device_name": request.device_name,
                "mac_address": request.mac_address,
                "device_type": request.device_type,
                "location": request.location,
                "registered_at": datetime.utcnow(),
                "last_seen": datetime.utcnow(),
                "is_active": True
            })
            return {"success": True, "action": "registered", "device_id": request.device_id}

    except Exception as e:
        logger.error(f"Device registration error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/devices")
async def list_devices(active_only: bool = Query(default=True)):
    """Get all registered Bluetooth devices."""
    db = get_database()
    if db is None:
        return {"devices": [], "count": 0}

    try:
        query = {"is_active": True} if active_only else {}
        devices = []
        async for doc in db.bluetooth_devices.find(query):
            doc["_id"] = str(doc["_id"])
            devices.append(doc)

        return {"devices": devices, "count": len(devices)}

    except Exception as e:
        logger.error(f"Error fetching devices: {e}")
        return {"devices": [], "count": 0}


@router.post("/data")
async def submit_sensor_data(request: SensorDataRequest, user_id: Optional[str] = None):
    """Submit sensor data received via Bluetooth."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    try:
        record = {
            "device_id": request.device_id,
            "temperature": request.temperature,
            "humidity": request.humidity,
            "soil_moisture": request.soil_moisture,
            "light_level": request.light_level,
            "battery_level": request.battery_level,
            "rssi": request.rssi,
            "timestamp": request.timestamp or datetime.utcnow(),
            "collected_offline": request.collected_offline,
            "synced": True,
            "user_id": user_id,
        }

        await db.iot_data.insert_one(record)

        # Update device last_seen
        await db.bluetooth_devices.update_one(
            {"device_id": request.device_id},
            {"$set": {"last_seen": datetime.utcnow()}}
        )

        return {"success": True, "message": "Sensor data stored successfully"}

    except Exception as e:
        logger.error(f"Error storing sensor data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sync")
async def batch_sync_data(request: BatchSyncRequest):
    """Sync batch of offline-collected sensor data."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    synced = 0
    failed = 0

    try:
        for reading in request.readings:
            try:
                record = {
                    "device_id": reading.device_id,
                    "temperature": reading.temperature,
                    "humidity": reading.humidity,
                    "soil_moisture": reading.soil_moisture,
                    "light_level": reading.light_level,
                    "battery_level": reading.battery_level,
                    "rssi": reading.rssi,
                    "timestamp": reading.timestamp or datetime.utcnow(),
                    "collected_offline": reading.collected_offline,
                    "synced": True,
                    "synced_at": datetime.utcnow(),
                    "user_id": request.user_id,
                }
                await db.iot_data.insert_one(record)
                synced += 1
            except Exception as e:
                logger.error(f"Failed to sync record: {e}")
                failed += 1

        return {
            "success": True,
            "synced": synced,
            "failed": failed,
            "total": len(request.readings)
        }

    except Exception as e:
        logger.error(f"Batch sync error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/devices/{device_id}/history")
async def get_device_history(
    device_id: str,
    limit: int = Query(default=100, le=1000),
    hours: int = Query(default=24, le=168)
):
    """Get historical sensor data for a device."""
    db = get_database()
    if db is None:
        return {"device_id": device_id, "readings": [], "count": 0}

    try:
        cutoff = datetime.utcnow() - timedelta(hours=hours)

        readings = []
        async for doc in db.iot_data.find(
            {"device_id": device_id, "timestamp": {"$gte": cutoff}}
        ).sort("timestamp", -1).limit(limit):
            doc["_id"] = str(doc["_id"])
            readings.append(doc)

        return {
            "device_id": device_id,
            "readings": readings,
            "count": len(readings)
        }

    except Exception as e:
        logger.error(f"Error fetching device history: {e}")
        return {"device_id": device_id, "readings": [], "count": 0}


@router.get("/health")
async def bluetooth_health():
    """Check Bluetooth service health."""
    return {
        "status": "healthy",
        "bluetooth_enabled": BLUETOOTH_CONFIG["enabled"],
        "service_uuid": BLUETOOTH_CONFIG["service_uuid"],
        "message": "Bluetooth IoT service is ready"
    }
