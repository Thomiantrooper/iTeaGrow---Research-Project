"""
WiFi IoT Device API Routes for local network sensor communication.
Supports ESP32 devices sending data via HTTP over WiFi (same network or hotspot mode).
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from database import get_database

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/wifi", tags=["WiFi IoT"])


class WiFiDeviceRegistration(BaseModel):
    device_id: str = Field(..., description="Unique device identifier")
    device_name: str = Field(..., description="Human-readable device name")
    ip_address: str = Field(..., description="Device IP address on local network")
    mac_address: Optional[str] = None
    firmware_version: Optional[str] = None
    device_type: str = "esp32_wifi"


class WiFiSensorData(BaseModel):
    device_id: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    rainfall: Optional[float] = None
    light_level: Optional[float] = None
    battery_level: Optional[int] = None
    wifi_rssi: Optional[int] = None
    timestamp: Optional[datetime] = None


class WiFiBatchData(BaseModel):
    device_id: str
    user_id: Optional[str] = None
    readings: List[WiFiSensorData]


@router.post("/devices/register")
async def register_wifi_device(request: WiFiDeviceRegistration):
    """Register a WiFi-connected IoT device."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    try:
        existing = await db.wifi_devices.find_one({"device_id": request.device_id})

        device_doc = {
            "device_id": request.device_id,
            "device_name": request.device_name,
            "ip_address": request.ip_address,
            "mac_address": request.mac_address,
            "firmware_version": request.firmware_version,
            "device_type": request.device_type,
            "connection_type": "wifi",
            "last_seen": datetime.utcnow(),
            "is_active": True,
        }

        if existing:
            await db.wifi_devices.update_one(
                {"device_id": request.device_id},
                {"$set": device_doc}
            )
            return {"success": True, "action": "updated", "device_id": request.device_id}
        else:
            device_doc["registered_at"] = datetime.utcnow()
            await db.wifi_devices.insert_one(device_doc)
            return {"success": True, "action": "registered", "device_id": request.device_id}

    except Exception as e:
        logger.error(f"WiFi device registration error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/devices")
async def list_wifi_devices(active_only: bool = Query(default=True)):
    """Get all registered WiFi devices."""
    db = get_database()
    if db is None:
        return {"devices": [], "count": 0}

    try:
        query = {"is_active": True} if active_only else {}
        devices = []
        async for doc in db.wifi_devices.find(query):
            doc["_id"] = str(doc["_id"])
            devices.append(doc)

        return {"devices": devices, "count": len(devices)}
    except Exception as e:
        logger.error(f"Error fetching WiFi devices: {e}")
        return {"devices": [], "count": 0}


@router.post("/data")
async def submit_wifi_sensor_data(request: WiFiSensorData, user_id: Optional[str] = None):
    """Receive sensor data from ESP32 via WiFi HTTP POST."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    try:
        record = {
            "device_id": request.device_id,
            "temperature": request.temperature,
            "humidity": request.humidity,
            "soil_moisture": request.soil_moisture,
            "rainfall": request.rainfall,
            "light_level": request.light_level,
            "battery_level": request.battery_level,
            "wifi_rssi": request.wifi_rssi,
            "timestamp": request.timestamp or datetime.utcnow(),
            "connection_type": "wifi",
            "collected_offline": False,
            "synced": True,
            "user_id": user_id,
        }

        await db.iot_data.insert_one(record)

        # Update device last_seen
        await db.wifi_devices.update_one(
            {"device_id": request.device_id},
            {"$set": {"last_seen": datetime.utcnow()}}
        )

        return {"success": True, "message": "WiFi sensor data stored"}

    except Exception as e:
        logger.error(f"Error storing WiFi sensor data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch")
async def batch_wifi_data(request: WiFiBatchData):
    """Receive batch sensor data from WiFi device."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    synced = 0
    failed = 0

    for reading in request.readings:
        try:
            record = {
                "device_id": reading.device_id or request.device_id,
                "temperature": reading.temperature,
                "humidity": reading.humidity,
                "soil_moisture": reading.soil_moisture,
                "rainfall": reading.rainfall,
                "light_level": reading.light_level,
                "battery_level": reading.battery_level,
                "wifi_rssi": reading.wifi_rssi,
                "timestamp": reading.timestamp or datetime.utcnow(),
                "connection_type": "wifi",
                "collected_offline": False,
                "synced": True,
                "user_id": request.user_id,
            }
            await db.iot_data.insert_one(record)
            synced += 1
        except Exception as e:
            logger.error(f"Failed to store WiFi reading: {e}")
            failed += 1

    return {
        "success": True,
        "synced": synced,
        "failed": failed,
        "total": len(request.readings)
    }


@router.get("/discover")
async def get_discovery_info():
    """Get device discovery information for the mobile app."""
    return {
        "service_type": "_iteagrow._tcp",
        "service_name": "iTeaGrow WiFi Sensor",
        "default_port": 80,
        "data_endpoint": "/sensor/data",
        "status_endpoint": "/sensor/status",
        "expected_format": {
            "temperature": "float (Celsius)",
            "humidity": "float (%)",
            "soil_moisture": "float (%)",
            "rainfall": "float (mm)",
            "light_level": "float (lux)",
        },
        "instructions": [
            "1. Ensure mobile device and ESP32 are on the same WiFi network",
            "2. ESP32 can also run in hotspot mode (SSID: iTeaGrow-XXXX)",
            "3. Use mDNS discovery or enter device IP manually",
            "4. Default data port is 80, data at /sensor/data",
        ]
    }


@router.get("/devices/{device_id}/history")
async def get_wifi_device_history(
    device_id: str,
    limit: int = Query(default=100, le=1000),
    hours: int = Query(default=24, le=168)
):
    """Get historical sensor data for a WiFi device."""
    db = get_database()
    if db is None:
        return {"device_id": device_id, "readings": [], "count": 0}

    try:
        cutoff = datetime.utcnow() - timedelta(hours=hours)

        readings = []
        async for doc in db.iot_data.find(
            {"device_id": device_id, "connection_type": "wifi", "timestamp": {"$gte": cutoff}}
        ).sort("timestamp", -1).limit(limit):
            doc["_id"] = str(doc["_id"])
            readings.append(doc)

        return {"device_id": device_id, "readings": readings, "count": len(readings)}

    except Exception as e:
        logger.error(f"Error fetching WiFi device history: {e}")
        return {"device_id": device_id, "readings": [], "count": 0}


@router.get("/health")
async def wifi_health():
    """Check WiFi IoT service health."""
    return {
        "status": "healthy",
        "service": "WiFi IoT",
        "message": "WiFi IoT service is ready to receive data"
    }
