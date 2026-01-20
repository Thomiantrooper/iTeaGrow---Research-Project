"""
Sensor data processing and validation for IoT devices.
"""

from datetime import datetime, timezone, timedelta
from typing import Optional, Tuple
import uuid

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import SensorError, SensorDataValidationError
from src.api.schemas import (
    IoTDataPayload,
    IoTDataResponse,
    SensorReading,
    EnvironmentalConditions,
)

logger = get_logger(__name__)


class SensorProcessor:
    """
    Processes and validates IoT sensor data from tea plantation devices.
    """

    SENSOR_TYPES = {
        "temperature": {"unit": "celsius", "min": -10, "max": 50},
        "humidity": {"unit": "percent", "min": 0, "max": 100},
        "soil_moisture": {"unit": "percent", "min": 0, "max": 100},
        "light_intensity": {"unit": "lux", "min": 0, "max": 120000},
        "battery": {"unit": "percent", "min": 0, "max": 100},
        "signal": {"unit": "dBm", "min": -120, "max": 0},
    }

    def __init__(self):
        """Initialize the sensor processor."""
        self.iot_settings = settings.iot
        self._device_registry: dict[str, dict] = {}
        self._sensor_health: dict[str, dict[str, str]] = {}

    def process_payload(self, payload: IoTDataPayload) -> IoTDataResponse:
        """
        Process incoming IoT sensor data payload.

        Args:
            payload: IoT data payload from device

        Returns:
            IoTDataResponse with validation results
        """
        ingestion_id = str(uuid.uuid4())

        self._register_device(payload.device_id, payload.plantation_id)

        validation_results = self._validate_payload(payload)

        alerts = self._check_for_alerts(payload, validation_results)

        self._update_sensor_health(payload.device_id, validation_results)

        logger.info(
            f"Processed IoT payload from device {payload.device_id}",
            extra={
                "extra_data": {
                    "ingestion_id": ingestion_id,
                    "device_id": payload.device_id,
                    "valid_readings": sum(validation_results.values()),
                    "alerts": len(alerts),
                }
            },
        )

        return IoTDataResponse(
            ingestion_id=ingestion_id,
            device_id=payload.device_id,
            timestamp=payload.timestamp,
            status="processed" if all(validation_results.values()) else "partial",
            validation_results=validation_results,
            alerts=alerts,
        )

    def _register_device(self, device_id: str, plantation_id: str) -> None:
        """Register or update device in the registry."""
        now = datetime.now(timezone.utc)

        if device_id not in self._device_registry:
            self._device_registry[device_id] = {
                "plantation_id": plantation_id,
                "first_seen": now,
                "last_seen": now,
                "total_readings": 0,
            }
            logger.info(f"New device registered: {device_id}")
        else:
            self._device_registry[device_id]["last_seen"] = now

        self._device_registry[device_id]["total_readings"] += 1

    def _validate_payload(self, payload: IoTDataPayload) -> dict[str, bool]:
        """
        Validate all sensor readings in the payload.

        Args:
            payload: IoT data payload

        Returns:
            Dictionary mapping sensor type to validation status
        """
        results = {}

        if payload.temperature is not None:
            results["temperature"] = self._validate_range(
                payload.temperature,
                self.iot_settings.temp_min,
                self.iot_settings.temp_max,
            )

        if payload.humidity is not None:
            results["humidity"] = self._validate_range(
                payload.humidity,
                self.iot_settings.humidity_min,
                self.iot_settings.humidity_max,
            )

        if payload.soil_moisture is not None:
            results["soil_moisture"] = self._validate_range(
                payload.soil_moisture,
                self.iot_settings.soil_moisture_min,
                self.iot_settings.soil_moisture_max,
            )

        if payload.light_intensity is not None:
            results["light_intensity"] = self._validate_range(
                payload.light_intensity,
                self.iot_settings.light_min,
                self.iot_settings.light_max,
            )

        if payload.battery_level is not None:
            results["battery"] = self._validate_range(payload.battery_level, 0, 100)

        if payload.signal_strength is not None:
            results["signal"] = self._validate_range(payload.signal_strength, -120, 0)

        for reading in payload.raw_readings:
            if reading.sensor_type in self.SENSOR_TYPES:
                spec = self.SENSOR_TYPES[reading.sensor_type]
                results[f"raw_{reading.sensor_id}"] = self._validate_range(
                    reading.value, spec["min"], spec["max"]
                )

        return results

    def _validate_range(
        self,
        value: float,
        min_val: float,
        max_val: float,
    ) -> bool:
        """Check if a value is within the acceptable range."""
        return min_val <= value <= max_val

    def _check_for_alerts(
        self,
        payload: IoTDataPayload,
        validation_results: dict[str, bool],
    ) -> list[str]:
        """
        Check for conditions that require alerts.

        Args:
            payload: IoT data payload
            validation_results: Validation results

        Returns:
            List of alert messages
        """
        alerts = []

        for sensor, is_valid in validation_results.items():
            if not is_valid:
                alerts.append(f"Invalid reading from sensor: {sensor}")

        if payload.temperature is not None:
            if payload.temperature > 32:
                alerts.append(
                    f"High temperature warning: {payload.temperature}°C - "
                    "risk of heat stress to tea plants"
                )
            elif payload.temperature < 13:
                alerts.append(
                    f"Low temperature warning: {payload.temperature}°C - "
                    "risk of cold damage"
                )

        if payload.humidity is not None:
            if payload.humidity > 85:
                alerts.append(
                    f"High humidity alert: {payload.humidity}% - "
                    "increased risk of blister blight"
                )
            elif payload.humidity < 40:
                alerts.append(
                    f"Low humidity warning: {payload.humidity}% - "
                    "risk of leaf desiccation"
                )

        if payload.soil_moisture is not None:
            if payload.soil_moisture < 30:
                alerts.append(
                    f"Low soil moisture warning: {payload.soil_moisture}% - "
                    "irrigation may be needed"
                )
            elif payload.soil_moisture > 80:
                alerts.append(
                    f"High soil moisture alert: {payload.soil_moisture}% - "
                    "risk of root rot"
                )

        if payload.battery_level is not None and payload.battery_level < 20:
            alerts.append(
                f"Low battery warning for device {payload.device_id}: "
                f"{payload.battery_level}%"
            )

        if payload.signal_strength is not None and payload.signal_strength < -90:
            alerts.append(
                f"Weak signal warning for device {payload.device_id}: "
                f"{payload.signal_strength} dBm"
            )

        return alerts

    def _update_sensor_health(
        self,
        device_id: str,
        validation_results: dict[str, bool],
    ) -> None:
        """Update sensor health status based on validation results."""
        if device_id not in self._sensor_health:
            self._sensor_health[device_id] = {}

        for sensor, is_valid in validation_results.items():
            self._sensor_health[device_id][sensor] = "healthy" if is_valid else "degraded"

    def get_sensor_health(self, device_id: str) -> dict[str, str]:
        """Get sensor health status for a device."""
        return self._sensor_health.get(device_id, {})

    def get_device_info(self, device_id: str) -> Optional[dict]:
        """Get device registration information."""
        return self._device_registry.get(device_id)

    def calculate_disease_risk_factors(
        self,
        payload: IoTDataPayload,
    ) -> dict[str, float]:
        """
        Calculate disease risk factors based on environmental conditions.

        Args:
            payload: IoT data payload

        Returns:
            Dictionary of disease risk factors (0.0 to 1.0)
        """
        risk_factors = {
            "red_rust": 0.0,
            "blister_blight": 0.0,
            "overall": 0.0,
        }

        if payload.temperature is not None and payload.humidity is not None:
            temp = payload.temperature
            humidity = payload.humidity

            if 20 <= temp <= 28 and humidity > 70:
                risk_factors["red_rust"] = min(1.0, (humidity - 70) / 30 * 0.8)

            if 15 <= temp <= 25 and humidity > 80:
                blight_risk = (humidity - 80) / 20
                if payload.light_intensity and payload.light_intensity < 20000:
                    blight_risk += 0.2
                risk_factors["blister_blight"] = min(1.0, blight_risk)

        if payload.soil_moisture is not None:
            if payload.soil_moisture > 70:
                moisture_factor = (payload.soil_moisture - 70) / 30 * 0.3
                risk_factors["red_rust"] = min(1.0, risk_factors["red_rust"] + moisture_factor)
                risk_factors["blister_blight"] = min(
                    1.0, risk_factors["blister_blight"] + moisture_factor
                )

        risk_factors["overall"] = max(
            risk_factors["red_rust"],
            risk_factors["blister_blight"],
        )

        return risk_factors

    def get_environmental_conditions(
        self,
        plantation_id: str,
        readings: list[IoTDataPayload],
    ) -> EnvironmentalConditions:
        """
        Aggregate environmental conditions from multiple readings.

        Args:
            plantation_id: Plantation identifier
            readings: List of IoT data payloads

        Returns:
            EnvironmentalConditions summary
        """
        temps = [r.temperature for r in readings if r.temperature is not None]
        humidities = [r.humidity for r in readings if r.humidity is not None]
        moistures = [r.soil_moisture for r in readings if r.soil_moisture is not None]
        lights = [r.light_intensity for r in readings if r.light_intensity is not None]

        risk_factors = {}
        if readings:
            latest = readings[-1]
            risk_factors = self.calculate_disease_risk_factors(latest)

        device_ids = set(r.device_id for r in readings)
        sensor_health = {}
        for device_id in device_ids:
            health = self.get_sensor_health(device_id)
            sensor_health.update({f"{device_id}_{k}": v for k, v in health.items()})

        return EnvironmentalConditions(
            plantation_id=plantation_id,
            timestamp=datetime.now(timezone.utc),
            temperature_avg=sum(temps) / len(temps) if temps else None,
            temperature_min=min(temps) if temps else None,
            temperature_max=max(temps) if temps else None,
            humidity_avg=sum(humidities) / len(humidities) if humidities else None,
            soil_moisture_avg=sum(moistures) / len(moistures) if moistures else None,
            light_intensity_avg=sum(lights) / len(lights) if lights else None,
            disease_risk_factors=risk_factors,
            sensor_health=sensor_health,
        )
