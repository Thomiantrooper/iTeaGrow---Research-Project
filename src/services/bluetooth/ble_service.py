"""
Bluetooth Low Energy (BLE) IoT Service for Tea Plantation Sensors

This service handles:
- Parsing sensor data received via Bluetooth from ESP32/Arduino devices
- Storing offline-collected data to MongoDB when online
- Managing device registration and configuration

The actual BLE communication happens on the Flutter mobile app.
This backend service processes and stores the data.
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from pydantic import BaseModel, Field
import json

from configs.settings import settings
from src.core.database import get_database, is_connected

logger = logging.getLogger(__name__)


class BluetoothSensorData(BaseModel):
    """Data model for BLE sensor readings."""

    device_id: str = Field(..., description="Unique device identifier")
    device_name: Optional[str] = Field(None, description="Human-readable device name")
    temperature: Optional[float] = Field(None, description="Temperature in Celsius")
    humidity: Optional[float] = Field(None, description="Relative humidity %")
    soil_moisture: Optional[float] = Field(None, description="Soil moisture %")
    light_level: Optional[float] = Field(None, description="Light intensity in lux")
    battery_level: Optional[int] = Field(None, description="Battery level %")
    rssi: Optional[int] = Field(None, description="Signal strength dBm")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    collected_offline: bool = Field(default=True)
    synced: bool = Field(default=False)


class BluetoothDevice(BaseModel):
    """Registered Bluetooth IoT device."""

    device_id: str
    device_name: str
    mac_address: Optional[str] = None
    device_type: str = "sensor"  # sensor, actuator, gateway
    location: Optional[str] = None
    registered_at: datetime = Field(default_factory=datetime.utcnow)
    last_seen: Optional[datetime] = None
    is_active: bool = True


class BluetoothIoTService:
    """
    Service for managing Bluetooth IoT sensor data.

    Handles:
    - Device registration
    - Data parsing from BLE characteristics
    - Offline data storage and sync
    - Batch upload from mobile app
    """

    # Standard BLE UUIDs for environmental sensing
    ENVIRONMENTAL_SERVICE_UUID = "181A"  # Environmental Sensing Service
    TEMPERATURE_CHAR_UUID = "2A6E"
    HUMIDITY_CHAR_UUID = "2A6F"

    # Custom UUIDs for tea plantation sensors (ESP32)
    CUSTOM_SERVICE_UUID = settings.bluetooth.service_uuid
    CUSTOM_CHAR_UUID = settings.bluetooth.characteristic_uuid

    def __init__(self):
        self.settings = settings.bluetooth

    async def register_device(self, device: BluetoothDevice) -> Dict[str, Any]:
        """
        Register a new Bluetooth IoT device.

        Args:
            device: Device information

        Returns:
            Registration result
        """
        db = get_database()
        if not db:
            logger.warning("MongoDB not connected, device registration failed")
            return {"success": False, "error": "Database not available"}

        try:
            # Check if device already exists
            existing = await db.bluetooth_devices.find_one(
                {"device_id": device.device_id}
            )

            if existing:
                # Update existing device
                await db.bluetooth_devices.update_one(
                    {"device_id": device.device_id},
                    {"$set": {
                        "device_name": device.device_name,
                        "last_seen": datetime.utcnow(),
                        "is_active": True
                    }}
                )
                logger.info(f"Updated device: {device.device_id}")
                return {"success": True, "action": "updated", "device_id": device.device_id}
            else:
                # Register new device
                await db.bluetooth_devices.insert_one(device.model_dump())
                logger.info(f"Registered new device: {device.device_id}")
                return {"success": True, "action": "registered", "device_id": device.device_id}

        except Exception as e:
            logger.error(f"Device registration error: {e}")
            return {"success": False, "error": str(e)}

    async def store_sensor_data(
        self,
        data: BluetoothSensorData,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Store sensor data received via Bluetooth.

        Args:
            data: Sensor reading data
            user_id: Optional user ID for multi-user support

        Returns:
            Storage result
        """
        db = get_database()
        if not db:
            logger.warning("MongoDB not connected, using local storage fallback")
            return {"success": False, "error": "Database not available", "stored_locally": True}

        try:
            record = data.model_dump()
            record["user_id"] = user_id
            record["synced"] = True  # Mark as synced since we're storing it now

            await db.iot_data.insert_one(record)

            # Update device last_seen
            await db.bluetooth_devices.update_one(
                {"device_id": data.device_id},
                {"$set": {"last_seen": datetime.utcnow()}}
            )

            logger.info(f"Stored sensor data from device: {data.device_id}")
            return {"success": True, "stored": True}

        except Exception as e:
            logger.error(f"Error storing sensor data: {e}")
            return {"success": False, "error": str(e)}

    async def batch_sync_offline_data(
        self,
        data_list: List[BluetoothSensorData],
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Sync batch of offline-collected data to MongoDB.

        Called when mobile app comes online after collecting data offline.

        Args:
            data_list: List of sensor readings collected offline
            user_id: User ID

        Returns:
            Sync results
        """
        db = get_database()
        if not db:
            return {"success": False, "error": "Database not available"}

        synced = 0
        failed = 0

        try:
            for data in data_list:
                record = data.model_dump()
                record["user_id"] = user_id
                record["synced"] = True
                record["synced_at"] = datetime.utcnow()

                try:
                    await db.iot_data.insert_one(record)
                    synced += 1
                except Exception as e:
                    logger.error(f"Failed to sync record: {e}")
                    failed += 1

            logger.info(f"Batch sync complete: {synced} synced, {failed} failed")
            return {
                "success": True,
                "synced": synced,
                "failed": failed,
                "total": len(data_list)
            }

        except Exception as e:
            logger.error(f"Batch sync error: {e}")
            return {"success": False, "error": str(e)}

    @staticmethod
    def parse_sensor_packet(raw_data: bytes, device_id: str) -> BluetoothSensorData:
        """
        Parse raw BLE characteristic data from ESP32/Arduino sensors.

        Expected packet format (20 bytes):
        - Bytes 0-3: Temperature (float, little-endian)
        - Bytes 4-7: Humidity (float, little-endian)
        - Bytes 8-11: Soil moisture (float, little-endian)
        - Bytes 12-15: Light level (float, little-endian)
        - Byte 16: Battery level (uint8)
        - Bytes 17-18: Reserved
        - Byte 19: Checksum

        Args:
            raw_data: Raw bytes from BLE characteristic
            device_id: Device identifier

        Returns:
            Parsed sensor data
        """
        import struct

        try:
            if len(raw_data) >= 17:
                # Parse structured data
                temperature = struct.unpack('<f', raw_data[0:4])[0]
                humidity = struct.unpack('<f', raw_data[4:8])[0]
                soil_moisture = struct.unpack('<f', raw_data[8:12])[0]
                light_level = struct.unpack('<f', raw_data[12:16])[0]
                battery = raw_data[16] if len(raw_data) > 16 else None
            else:
                # Try JSON format
                json_str = raw_data.decode('utf-8')
                data = json.loads(json_str)
                temperature = data.get('temp')
                humidity = data.get('hum')
                soil_moisture = data.get('soil')
                light_level = data.get('light')
                battery = data.get('bat')

            return BluetoothSensorData(
                device_id=device_id,
                temperature=temperature,
                humidity=humidity,
                soil_moisture=soil_moisture,
                light_level=light_level,
                battery_level=battery,
                collected_offline=True
            )

        except Exception as e:
            logger.error(f"Error parsing sensor packet: {e}")
            raise ValueError(f"Invalid sensor data format: {e}")

    async def get_device_history(
        self,
        device_id: str,
        limit: int = 100,
        hours: int = 24
    ) -> List[Dict[str, Any]]:
        """
        Get historical data for a device.

        Args:
            device_id: Device to query
            limit: Maximum records to return
            hours: Hours of history to fetch

        Returns:
            List of sensor readings
        """
        db = get_database()
        if not db:
            return []

        try:
            from datetime import timedelta
            cutoff = datetime.utcnow() - timedelta(hours=hours)

            cursor = db.iot_data.find(
                {
                    "device_id": device_id,
                    "timestamp": {"$gte": cutoff}
                }
            ).sort("timestamp", -1).limit(limit)

            results = []
            async for doc in cursor:
                doc["_id"] = str(doc["_id"])
                results.append(doc)

            return results

        except Exception as e:
            logger.error(f"Error fetching device history: {e}")
            return []

    async def get_registered_devices(self, active_only: bool = True) -> List[Dict]:
        """Get all registered Bluetooth devices."""
        db = get_database()
        if not db:
            return []

        try:
            query = {"is_active": True} if active_only else {}
            cursor = db.bluetooth_devices.find(query)

            devices = []
            async for doc in cursor:
                doc["_id"] = str(doc["_id"])
                devices.append(doc)

            return devices

        except Exception as e:
            logger.error(f"Error fetching devices: {e}")
            return []
