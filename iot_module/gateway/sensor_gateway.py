"""
IoT Sensor Gateway for Tea Plantation Monitoring
==================================================
Connects to ESP32 sensor nodes via BLE and processes environmental data.
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum
import threading
import queue
from collections import deque

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SensorType(Enum):
    """Types of environmental sensors."""
    TEMPERATURE = "temperature"
    HUMIDITY = "humidity"
    SOIL_MOISTURE = "soil_moisture"
    LIGHT_INTENSITY = "light_intensity"


@dataclass
class SensorReading:
    """Single sensor reading."""
    sensor_type: SensorType
    value: float
    timestamp: datetime
    device_id: str
    is_valid: bool = True

    def to_dict(self) -> Dict:
        return {
            'sensor_type': self.sensor_type.value,
            'value': self.value,
            'timestamp': self.timestamp.isoformat(),
            'device_id': self.device_id,
            'is_valid': self.is_valid
        }


@dataclass
class EnvironmentalConditions:
    """Complete environmental conditions from a sensor node."""
    temperature: float  # Celsius
    humidity: float  # Percentage
    soil_moisture: float  # Percentage
    light_intensity: float  # Lux
    timestamp: datetime
    device_id: str
    is_valid: bool = True

    def to_dict(self) -> Dict:
        return {
            'temperature': self.temperature,
            'humidity': self.humidity,
            'soil_moisture': self.soil_moisture,
            'light_intensity': self.light_intensity,
            'timestamp': self.timestamp.isoformat(),
            'device_id': self.device_id,
            'is_valid': self.is_valid
        }

    def is_red_rust_favorable(self) -> bool:
        """Check if conditions favor Red Rust development."""
        return (
            25.0 <= self.temperature <= 30.0 and
            70.0 <= self.humidity <= 90.0 and
            self.soil_moisture >= 60.0 and
            self.light_intensity <= 500.0
        )

    def is_blister_blight_favorable(self) -> bool:
        """Check if conditions favor Blister Blight development."""
        return (
            15.0 <= self.temperature <= 25.0 and
            self.humidity >= 85.0 and
            50.0 <= self.soil_moisture <= 70.0 and
            self.light_intensity <= 300.0
        )


class SensorBuffer:
    """
    Circular buffer for storing recent sensor readings.
    Supports statistical analysis and trend detection.
    """

    def __init__(self, max_size: int = 288):  # 24 hours at 5-min intervals
        self.max_size = max_size
        self.readings: deque = deque(maxlen=max_size)
        self._lock = threading.Lock()

    def add(self, conditions: EnvironmentalConditions):
        """Add a reading to the buffer."""
        with self._lock:
            self.readings.append(conditions)

    def get_latest(self) -> Optional[EnvironmentalConditions]:
        """Get the most recent reading."""
        with self._lock:
            if self.readings:
                return self.readings[-1]
            return None

    def get_average(self, hours: float = 1.0) -> Optional[Dict[str, float]]:
        """Calculate average values over specified time period."""
        with self._lock:
            if not self.readings:
                return None

            cutoff = datetime.now() - timedelta(hours=hours)
            recent = [r for r in self.readings if r.timestamp > cutoff and r.is_valid]

            if not recent:
                return None

            return {
                'temperature': sum(r.temperature for r in recent) / len(recent),
                'humidity': sum(r.humidity for r in recent) / len(recent),
                'soil_moisture': sum(r.soil_moisture for r in recent) / len(recent),
                'light_intensity': sum(r.light_intensity for r in recent) / len(recent),
                'sample_count': len(recent)
            }

    def get_trend(self, sensor_type: str, hours: float = 6.0) -> Optional[str]:
        """Detect trend for a specific sensor over time."""
        with self._lock:
            if len(self.readings) < 12:  # Need minimum samples
                return None

            cutoff = datetime.now() - timedelta(hours=hours)
            recent = [r for r in self.readings if r.timestamp > cutoff and r.is_valid]

            if len(recent) < 6:
                return None

            values = [getattr(r, sensor_type) for r in recent]
            first_half = sum(values[:len(values)//2]) / (len(values)//2)
            second_half = sum(values[len(values)//2:]) / (len(values) - len(values)//2)

            diff = second_half - first_half
            threshold = 0.05 * first_half  # 5% change threshold

            if diff > threshold:
                return "increasing"
            elif diff < -threshold:
                return "decreasing"
            else:
                return "stable"

    def get_history(self, hours: float = 24.0) -> List[Dict]:
        """Get reading history for specified period."""
        with self._lock:
            cutoff = datetime.now() - timedelta(hours=hours)
            return [r.to_dict() for r in self.readings if r.timestamp > cutoff]


class BLESensorGateway:
    """
    BLE Gateway for connecting to ESP32 sensor nodes.
    """

    SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    SENSOR_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
    CONFIG_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9"

    def __init__(self):
        self.connected_devices: Dict[str, any] = {}
        self.buffers: Dict[str, SensorBuffer] = {}
        self.callbacks: List[Callable[[EnvironmentalConditions], None]] = []
        self._running = False
        self._scan_task = None

    async def start(self):
        """Start the BLE gateway."""
        self._running = True
        logger.info("BLE Gateway starting...")

        try:
            from bleak import BleakScanner, BleakClient
            self._scanner = BleakScanner
            self._client_class = BleakClient

            # Start scanning
            self._scan_task = asyncio.create_task(self._scan_loop())
            logger.info("BLE Gateway started")
        except ImportError:
            logger.warning("bleak package not installed, using simulated mode")
            self._scan_task = asyncio.create_task(self._simulated_mode())

    async def stop(self):
        """Stop the BLE gateway."""
        self._running = False
        if self._scan_task:
            self._scan_task.cancel()
            try:
                await self._scan_task
            except asyncio.CancelledError:
                pass

        # Disconnect all devices
        for device_id, client in self.connected_devices.items():
            try:
                await client.disconnect()
            except Exception:
                pass

        logger.info("BLE Gateway stopped")

    async def _scan_loop(self):
        """Continuous scanning for sensor nodes."""
        while self._running:
            try:
                devices = await self._scanner.discover(timeout=5.0)

                for device in devices:
                    if device.name and device.name.startswith("TeaSensor-"):
                        device_id = device.name.replace("TeaSensor-", "")

                        if device_id not in self.connected_devices:
                            asyncio.create_task(
                                self._connect_device(device.address, device_id)
                            )

            except Exception as e:
                logger.error(f"Scan error: {e}")

            await asyncio.sleep(30)  # Scan every 30 seconds

    async def _connect_device(self, address: str, device_id: str):
        """Connect to a sensor device."""
        try:
            client = self._client_class(address)
            await client.connect()

            if client.is_connected:
                self.connected_devices[device_id] = client

                if device_id not in self.buffers:
                    self.buffers[device_id] = SensorBuffer()

                # Subscribe to notifications
                await client.start_notify(
                    self.SENSOR_CHAR_UUID,
                    lambda sender, data: self._handle_notification(device_id, data)
                )

                logger.info(f"Connected to sensor: {device_id}")

        except Exception as e:
            logger.error(f"Failed to connect to {device_id}: {e}")

    def _handle_notification(self, device_id: str, data: bytes):
        """Handle incoming sensor notification."""
        try:
            payload = json.loads(data.decode())

            conditions = EnvironmentalConditions(
                temperature=payload.get('t', 0),
                humidity=payload.get('h', 0),
                soil_moisture=payload.get('s', 0),
                light_intensity=payload.get('l', 0),
                timestamp=datetime.now(),
                device_id=device_id,
                is_valid=payload.get('v', True)
            )

            # Store in buffer
            if device_id in self.buffers:
                self.buffers[device_id].add(conditions)

            # Notify callbacks
            for callback in self.callbacks:
                try:
                    callback(conditions)
                except Exception as e:
                    logger.error(f"Callback error: {e}")

            logger.debug(f"Received data from {device_id}: {conditions.to_dict()}")

        except Exception as e:
            logger.error(f"Error parsing notification from {device_id}: {e}")

    async def _simulated_mode(self):
        """Simulated sensor data for testing."""
        import random

        device_id = "SIM001"
        self.buffers[device_id] = SensorBuffer()

        while self._running:
            # Generate realistic simulated data
            conditions = EnvironmentalConditions(
                temperature=22 + random.uniform(-3, 5),
                humidity=75 + random.uniform(-10, 15),
                soil_moisture=55 + random.uniform(-10, 15),
                light_intensity=200 + random.uniform(-100, 300),
                timestamp=datetime.now(),
                device_id=device_id,
                is_valid=True
            )

            self.buffers[device_id].add(conditions)

            for callback in self.callbacks:
                try:
                    callback(conditions)
                except Exception as e:
                    logger.error(f"Callback error: {e}")

            await asyncio.sleep(300)  # 5 minutes

    def add_callback(self, callback: Callable[[EnvironmentalConditions], None]):
        """Add a callback for new readings."""
        self.callbacks.append(callback)

    def remove_callback(self, callback: Callable):
        """Remove a callback."""
        if callback in self.callbacks:
            self.callbacks.remove(callback)

    def get_current_conditions(self, device_id: str = None) -> Optional[EnvironmentalConditions]:
        """Get current conditions from specified or first available device."""
        if device_id:
            buffer = self.buffers.get(device_id)
            return buffer.get_latest() if buffer else None

        # Return from first available device
        for buffer in self.buffers.values():
            latest = buffer.get_latest()
            if latest:
                return latest
        return None

    def get_all_conditions(self) -> Dict[str, EnvironmentalConditions]:
        """Get current conditions from all connected devices."""
        return {
            device_id: buffer.get_latest()
            for device_id, buffer in self.buffers.items()
            if buffer.get_latest()
        }

    async def configure_device(self, device_id: str, config: Dict) -> bool:
        """Send configuration to a device."""
        if device_id not in self.connected_devices:
            return False

        try:
            client = self.connected_devices[device_id]
            config_json = json.dumps(config).encode()

            await client.write_gatt_char(
                self.CONFIG_CHAR_UUID,
                config_json
            )

            logger.info(f"Configuration sent to {device_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to configure {device_id}: {e}")
            return False


class EnvironmentalAnalyzer:
    """
    Analyzes environmental data for disease risk assessment.
    """

    def __init__(self, gateway: BLESensorGateway):
        self.gateway = gateway
        self.risk_history: Dict[str, deque] = {}

    def assess_disease_risk(self, conditions: EnvironmentalConditions) -> Dict:
        """
        Assess disease risk based on environmental conditions.

        Returns risk levels and contributing factors.
        """
        result = {
            'timestamp': conditions.timestamp.isoformat(),
            'device_id': conditions.device_id,
            'red_rust': self._assess_red_rust_risk(conditions),
            'blister_blight': self._assess_blister_blight_risk(conditions),
            'overall_risk': 'low',
            'alerts': []
        }

        # Determine overall risk
        risks = [result['red_rust']['risk_level'], result['blister_blight']['risk_level']]
        if 'high' in risks:
            result['overall_risk'] = 'high'
        elif 'medium' in risks:
            result['overall_risk'] = 'medium'

        # Generate alerts
        if result['red_rust']['risk_level'] == 'high':
            result['alerts'].append({
                'disease': 'red_rust',
                'message': 'High risk of Red Rust detected',
                'priority': 'high'
            })

        if result['blister_blight']['risk_level'] == 'high':
            result['alerts'].append({
                'disease': 'blister_blight',
                'message': 'High risk of Blister Blight detected',
                'priority': 'high'
            })

        return result

    def _assess_red_rust_risk(self, conditions: EnvironmentalConditions) -> Dict:
        """Assess Red Rust risk."""
        factors = []
        score = 0

        # Temperature factor (25-30°C optimal)
        if 25 <= conditions.temperature <= 30:
            score += 30
            factors.append('Optimal temperature range')
        elif 22 <= conditions.temperature <= 33:
            score += 15
            factors.append('Near-optimal temperature')

        # Humidity factor (70-90% optimal)
        if 70 <= conditions.humidity <= 90:
            score += 30
            factors.append('High humidity favorable for disease')
        elif 60 <= conditions.humidity < 70:
            score += 10
            factors.append('Moderate humidity')

        # Soil moisture factor (>60%)
        if conditions.soil_moisture >= 60:
            score += 20
            factors.append('High soil moisture')
        elif conditions.soil_moisture >= 50:
            score += 10

        # Light factor (shaded conditions)
        if conditions.light_intensity <= 500:
            score += 20
            factors.append('Low light/shaded conditions')

        # Determine risk level
        if score >= 80:
            risk_level = 'high'
        elif score >= 50:
            risk_level = 'medium'
        else:
            risk_level = 'low'

        return {
            'risk_level': risk_level,
            'risk_score': score,
            'contributing_factors': factors
        }

    def _assess_blister_blight_risk(self, conditions: EnvironmentalConditions) -> Dict:
        """Assess Blister Blight risk."""
        factors = []
        score = 0

        # Temperature factor (15-25°C optimal)
        if 15 <= conditions.temperature <= 25:
            score += 30
            factors.append('Cool temperature favorable for disease')
        elif 12 <= conditions.temperature <= 28:
            score += 15
            factors.append('Near-optimal temperature')

        # Humidity factor (>85% optimal)
        if conditions.humidity >= 85:
            score += 35
            factors.append('Very high humidity favorable')
        elif conditions.humidity >= 75:
            score += 15
            factors.append('High humidity')

        # Soil moisture factor (50-70%)
        if 50 <= conditions.soil_moisture <= 70:
            score += 15
            factors.append('Moderate-high soil moisture')

        # Light factor (overcast/low light)
        if conditions.light_intensity <= 300:
            score += 20
            factors.append('Overcast/low light conditions')

        # Determine risk level
        if score >= 80:
            risk_level = 'high'
        elif score >= 50:
            risk_level = 'medium'
        else:
            risk_level = 'low'

        return {
            'risk_level': risk_level,
            'risk_score': score,
            'contributing_factors': factors
        }

    def get_risk_trend(self, device_id: str, hours: float = 24.0) -> Dict:
        """Get disease risk trend over time."""
        buffer = self.gateway.buffers.get(device_id)
        if not buffer:
            return {'error': 'Device not found'}

        history = buffer.get_history(hours)
        if not history:
            return {'error': 'No data available'}

        # Calculate risk for each historical point
        risk_timeline = []
        for reading in history:
            conditions = EnvironmentalConditions(
                temperature=reading['temperature'],
                humidity=reading['humidity'],
                soil_moisture=reading['soil_moisture'],
                light_intensity=reading['light_intensity'],
                timestamp=datetime.fromisoformat(reading['timestamp']),
                device_id=device_id
            )

            risk = self.assess_disease_risk(conditions)
            risk_timeline.append({
                'timestamp': reading['timestamp'],
                'red_rust_score': risk['red_rust']['risk_score'],
                'blister_blight_score': risk['blister_blight']['risk_score']
            })

        return {
            'device_id': device_id,
            'period_hours': hours,
            'timeline': risk_timeline,
            'average_red_rust_risk': sum(r['red_rust_score'] for r in risk_timeline) / len(risk_timeline),
            'average_blister_blight_risk': sum(r['blister_blight_score'] for r in risk_timeline) / len(risk_timeline)
        }


# Singleton gateway instance
_gateway_instance: Optional[BLESensorGateway] = None


def get_gateway() -> BLESensorGateway:
    """Get or create the gateway singleton."""
    global _gateway_instance
    if _gateway_instance is None:
        _gateway_instance = BLESensorGateway()
    return _gateway_instance


async def main():
    """Test the sensor gateway."""
    gateway = get_gateway()
    analyzer = EnvironmentalAnalyzer(gateway)

    def on_reading(conditions: EnvironmentalConditions):
        risk = analyzer.assess_disease_risk(conditions)
        print(f"\nNew reading from {conditions.device_id}:")
        print(f"  Temperature: {conditions.temperature:.1f}°C")
        print(f"  Humidity: {conditions.humidity:.1f}%")
        print(f"  Soil Moisture: {conditions.soil_moisture:.1f}%")
        print(f"  Light: {conditions.light_intensity:.0f} lux")
        print(f"  Overall Risk: {risk['overall_risk'].upper()}")
        if risk['alerts']:
            for alert in risk['alerts']:
                print(f"  ALERT: {alert['message']}")

    gateway.add_callback(on_reading)

    await gateway.start()

    try:
        # Run for 1 hour
        await asyncio.sleep(3600)
    except KeyboardInterrupt:
        pass
    finally:
        await gateway.stop()


if __name__ == "__main__":
    asyncio.run(main())
