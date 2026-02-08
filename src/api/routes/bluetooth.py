"""
Bluetooth IoT API Routes

Handles:
- Device registration
- Sensor data ingestion (from mobile app)
- Offline data sync
- Device management
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import logging

from src.services.bluetooth import BluetoothIoTService
from src.services.bluetooth.ble_service import BluetoothSensorData, BluetoothDevice
from configs.settings import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/bluetooth", tags=["Bluetooth IoT"])

# Service instance
_ble_service: Optional[BluetoothIoTService] = None


def get_ble_service() -> BluetoothIoTService:
    """Get or create BLE service instance."""
    global _ble_service
    if _ble_service is None:
        _ble_service = BluetoothIoTService()
    return _ble_service


# Request/Response Models
class DeviceRegistrationRequest(BaseModel):
    device_id: str = Field(..., description="Unique device identifier (MAC or custom ID)")
    device_name: str = Field(..., description="Human-readable name")
    mac_address: Optional[str] = Field(None, description="BLE MAC address")
    device_type: str = Field(default="sensor", description="Device type")
    location: Optional[str] = Field(None, description="Physical location description")


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
    """Batch sync request for offline-collected data."""
    user_id: Optional[str] = None
    readings: List[SensorDataRequest]


class BluetoothConfigResponse(BaseModel):
    """Bluetooth configuration for mobile app."""
    enabled: bool
    service_uuid: str
    characteristic_uuid: str
    scan_timeout: int
    connection_timeout: int
    auto_reconnect: bool


# Routes
@router.get("/config", response_model=BluetoothConfigResponse)
async def get_bluetooth_config():
    """
    Get Bluetooth configuration for mobile app.

    Returns service UUIDs and connection settings.
    """
    return BluetoothConfigResponse(
        enabled=settings.bluetooth.enabled,
        service_uuid=settings.bluetooth.service_uuid,
        characteristic_uuid=settings.bluetooth.characteristic_uuid,
        scan_timeout=settings.bluetooth.scan_timeout,
        connection_timeout=settings.bluetooth.connection_timeout,
        auto_reconnect=settings.bluetooth.auto_reconnect
    )


@router.post("/devices/register")
async def register_device(request: DeviceRegistrationRequest):
    """
    Register a new Bluetooth IoT device.

    Called when mobile app pairs with a new sensor device.
    """
    service = get_ble_service()

    device = BluetoothDevice(
        device_id=request.device_id,
        device_name=request.device_name,
        mac_address=request.mac_address,
        device_type=request.device_type,
        location=request.location
    )

    result = await service.register_device(device)

    if not result["success"]:
        raise HTTPException(status_code=500, detail=result.get("error", "Registration failed"))

    return result


@router.get("/devices")
async def list_devices(active_only: bool = Query(default=True)):
    """Get all registered Bluetooth devices."""
    service = get_ble_service()
    devices = await service.get_registered_devices(active_only=active_only)
    return {"devices": devices, "count": len(devices)}


@router.post("/data")
async def submit_sensor_data(request: SensorDataRequest, user_id: Optional[str] = None):
    """
    Submit sensor data received via Bluetooth.

    Called by mobile app when it receives data from BLE device.
    """
    service = get_ble_service()

    data = BluetoothSensorData(
        device_id=request.device_id,
        temperature=request.temperature,
        humidity=request.humidity,
        soil_moisture=request.soil_moisture,
        light_level=request.light_level,
        battery_level=request.battery_level,
        rssi=request.rssi,
        timestamp=request.timestamp or datetime.utcnow(),
        collected_offline=request.collected_offline
    )

    result = await service.store_sensor_data(data, user_id)

    if not result["success"]:
        raise HTTPException(status_code=500, detail=result.get("error", "Storage failed"))

    return {"success": True, "message": "Sensor data stored successfully"}


@router.post("/sync")
async def batch_sync_data(request: BatchSyncRequest):
    """
    Sync batch of offline-collected sensor data.

    Called when mobile app comes online after collecting data offline via Bluetooth.
    This allows the app to work completely offline and sync when network is available.
    """
    service = get_ble_service()

    data_list = [
        BluetoothSensorData(
            device_id=r.device_id,
            temperature=r.temperature,
            humidity=r.humidity,
            soil_moisture=r.soil_moisture,
            light_level=r.light_level,
            battery_level=r.battery_level,
            rssi=r.rssi,
            timestamp=r.timestamp or datetime.utcnow(),
            collected_offline=r.collected_offline
        )
        for r in request.readings
    ]

    result = await service.batch_sync_offline_data(data_list, request.user_id)

    if not result["success"]:
        raise HTTPException(status_code=500, detail=result.get("error", "Sync failed"))

    return result


@router.get("/devices/{device_id}/history")
async def get_device_history(
    device_id: str,
    limit: int = Query(default=100, le=1000),
    hours: int = Query(default=24, le=168)  # Max 1 week
):
    """
    Get historical sensor data for a device.

    Args:
        device_id: Device to query
        limit: Max records (default 100)
        hours: Hours of history (default 24, max 168)
    """
    service = get_ble_service()
    history = await service.get_device_history(device_id, limit=limit, hours=hours)

    return {
        "device_id": device_id,
        "readings": history,
        "count": len(history)
    }


@router.get("/health")
async def bluetooth_health():
    """Check Bluetooth service health."""
    return {
        "status": "healthy",
        "bluetooth_enabled": settings.bluetooth.enabled,
        "service_uuid": settings.bluetooth.service_uuid,
        "message": "Bluetooth IoT service is ready"
    }
