"""
Anomaly detection for IoT sensor data.
Identifies unusual readings and potential sensor failures.
"""

from datetime import datetime, timezone, timedelta
from typing import Optional
from collections import deque
import statistics

from configs.settings import settings
from src.core.logging import get_logger

logger = get_logger(__name__)


class SensorBaseline:
    """Maintains baseline statistics for anomaly detection."""

    def __init__(self, window_size: int = 100):
        self.window_size = window_size
        self._values: deque = deque(maxlen=window_size)
        self._mean: float = 0.0
        self._std: float = 0.0
        self._is_calibrated: bool = False

    def add(self, value: float) -> None:
        """Add a new value and update statistics."""
        self._values.append(value)

        if len(self._values) >= 10:
            self._mean = statistics.mean(self._values)
            self._std = statistics.stdev(self._values) if len(self._values) > 1 else 0.0
            self._is_calibrated = len(self._values) >= self.window_size // 2

    @property
    def mean(self) -> float:
        return self._mean

    @property
    def std(self) -> float:
        return self._std

    @property
    def is_calibrated(self) -> bool:
        return self._is_calibrated

    def get_z_score(self, value: float) -> float:
        """Calculate z-score for a value."""
        if self._std == 0:
            return 0.0
        return (value - self._mean) / self._std


class AnomalyDetector:
    """
    Detects anomalies in IoT sensor data using statistical methods.
    Supports multiple detection strategies and sensor-specific thresholds.
    """

    SENSOR_THRESHOLDS = {
        "temperature": {"z_threshold": 3.0, "rate_of_change": 5.0},
        "humidity": {"z_threshold": 2.5, "rate_of_change": 20.0},
        "soil_moisture": {"z_threshold": 2.5, "rate_of_change": 15.0},
        "light_intensity": {"z_threshold": 3.0, "rate_of_change": 50000.0},
    }

    def __init__(self, baseline_window: int = 100):
        """
        Initialize the anomaly detector.

        Args:
            baseline_window: Number of readings for baseline calculation
        """
        self.baseline_window = baseline_window

        self._baselines: dict[str, dict[str, SensorBaseline]] = {}

        self._last_readings: dict[str, dict[str, tuple[datetime, float]]] = {}

        self._anomaly_counts: dict[str, dict[str, int]] = {}

    def _get_baseline(self, device_id: str, sensor_type: str) -> SensorBaseline:
        """Get or create baseline for a sensor."""
        if device_id not in self._baselines:
            self._baselines[device_id] = {}

        if sensor_type not in self._baselines[device_id]:
            self._baselines[device_id][sensor_type] = SensorBaseline(self.baseline_window)

        return self._baselines[device_id][sensor_type]

    def check_reading(
        self,
        device_id: str,
        sensor_type: str,
        value: float,
        timestamp: Optional[datetime] = None,
    ) -> dict:
        """
        Check a sensor reading for anomalies.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor
            value: Sensor reading value
            timestamp: Reading timestamp

        Returns:
            Anomaly detection result dictionary
        """
        timestamp = timestamp or datetime.now(timezone.utc)

        baseline = self._get_baseline(device_id, sensor_type)

        result = {
            "device_id": device_id,
            "sensor_type": sensor_type,
            "value": value,
            "timestamp": timestamp.isoformat(),
            "is_anomaly": False,
            "anomaly_types": [],
            "z_score": None,
            "rate_of_change": None,
            "confidence": 0.0,
        }

        thresholds = self.SENSOR_THRESHOLDS.get(sensor_type, {
            "z_threshold": 3.0,
            "rate_of_change": float("inf"),
        })

        if baseline.is_calibrated:
            z_score = baseline.get_z_score(value)
            result["z_score"] = z_score

            if abs(z_score) > thresholds["z_threshold"]:
                result["is_anomaly"] = True
                result["anomaly_types"].append("statistical_outlier")
                result["confidence"] = min(1.0, abs(z_score) / (thresholds["z_threshold"] * 2))

        roc = self._check_rate_of_change(
            device_id, sensor_type, value, timestamp, thresholds["rate_of_change"]
        )
        if roc is not None:
            result["rate_of_change"] = roc["rate"]
            if roc["is_anomaly"]:
                result["is_anomaly"] = True
                result["anomaly_types"].append("sudden_change")
                result["confidence"] = max(result["confidence"], roc["confidence"])

        if self._check_flatline(device_id, sensor_type, value):
            result["is_anomaly"] = True
            result["anomaly_types"].append("flatline")
            result["confidence"] = max(result["confidence"], 0.7)

        baseline.add(value)

        self._last_readings.setdefault(device_id, {})[sensor_type] = (timestamp, value)

        if result["is_anomaly"]:
            self._record_anomaly(device_id, sensor_type)

        return result

    def _check_rate_of_change(
        self,
        device_id: str,
        sensor_type: str,
        value: float,
        timestamp: datetime,
        threshold: float,
    ) -> Optional[dict]:
        """Check for sudden changes in sensor values."""
        last = self._last_readings.get(device_id, {}).get(sensor_type)
        if last is None:
            return None

        last_time, last_value = last
        time_diff = (timestamp - last_time).total_seconds()

        if time_diff <= 0:
            return None

        rate = abs(value - last_value) / (time_diff / 60)

        is_anomaly = rate > threshold
        confidence = min(1.0, rate / (threshold * 2)) if is_anomaly else 0.0

        return {
            "rate": rate,
            "is_anomaly": is_anomaly,
            "confidence": confidence,
        }

    def _check_flatline(
        self,
        device_id: str,
        sensor_type: str,
        value: float,
        tolerance: float = 0.001,
    ) -> bool:
        """Check if sensor is reporting identical values (potential failure)."""
        baseline = self._get_baseline(device_id, sensor_type)

        if len(baseline._values) < 10:
            return False

        recent = list(baseline._values)[-10:]
        return all(abs(v - value) < tolerance for v in recent)

    def _record_anomaly(self, device_id: str, sensor_type: str) -> None:
        """Record anomaly occurrence for tracking."""
        if device_id not in self._anomaly_counts:
            self._anomaly_counts[device_id] = {}

        if sensor_type not in self._anomaly_counts[device_id]:
            self._anomaly_counts[device_id][sensor_type] = 0

        self._anomaly_counts[device_id][sensor_type] += 1

    def get_anomaly_statistics(self, device_id: str) -> dict:
        """
        Get anomaly statistics for a device.

        Args:
            device_id: Device identifier

        Returns:
            Dictionary with anomaly statistics per sensor
        """
        stats = {"device_id": device_id, "sensors": {}}

        if device_id not in self._anomaly_counts:
            return stats

        for sensor_type, count in self._anomaly_counts[device_id].items():
            baseline = self._baselines.get(device_id, {}).get(sensor_type)
            total_readings = len(baseline._values) if baseline else 0

            stats["sensors"][sensor_type] = {
                "anomaly_count": count,
                "total_readings": total_readings,
                "anomaly_rate": count / total_readings if total_readings > 0 else 0,
                "is_calibrated": baseline.is_calibrated if baseline else False,
            }

        return stats

    def detect_sensor_failure(self, device_id: str, sensor_type: str) -> dict:
        """
        Detect potential sensor failure based on anomaly patterns.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor

        Returns:
            Failure detection result
        """
        baseline = self._baselines.get(device_id, {}).get(sensor_type)
        anomaly_count = self._anomaly_counts.get(device_id, {}).get(sensor_type, 0)

        result = {
            "device_id": device_id,
            "sensor_type": sensor_type,
            "status": "healthy",
            "confidence": 1.0,
            "issues": [],
        }

        if baseline is None:
            result["status"] = "unknown"
            result["issues"].append("No baseline data available")
            return result

        if len(baseline._values) < 10:
            result["status"] = "calibrating"
            result["issues"].append("Insufficient data for analysis")
            return result

        recent = list(baseline._values)[-10:]
        if len(set(recent)) == 1:
            result["status"] = "failed"
            result["confidence"] = 0.9
            result["issues"].append("Sensor reporting constant values (flatline)")
            return result

        if baseline.is_calibrated:
            total = len(baseline._values)
            anomaly_rate = anomaly_count / total if total > 0 else 0

            if anomaly_rate > 0.3:
                result["status"] = "degraded"
                result["confidence"] = min(1.0, anomaly_rate * 2)
                result["issues"].append(f"High anomaly rate: {anomaly_rate:.1%}")

        last = self._last_readings.get(device_id, {}).get(sensor_type)
        if last is not None:
            last_time, _ = last
            gap = (datetime.now(timezone.utc) - last_time).total_seconds()

            expected_interval = settings.iot.aggregation_interval
            if gap > expected_interval * 3:
                result["status"] = "unresponsive"
                result["confidence"] = min(1.0, gap / (expected_interval * 10))
                result["issues"].append(f"No readings for {gap:.0f} seconds")

        return result

    def reset_device(self, device_id: str) -> None:
        """Reset all tracking data for a device."""
        self._baselines.pop(device_id, None)
        self._last_readings.pop(device_id, None)
        self._anomaly_counts.pop(device_id, None)
        logger.info(f"Reset anomaly detection data for device {device_id}")

    def get_health_summary(self, device_ids: list[str]) -> dict:
        """
        Get health summary for multiple devices.

        Args:
            device_ids: List of device identifiers

        Returns:
            Summary of device health statuses
        """
        summary = {
            "total_devices": len(device_ids),
            "healthy": 0,
            "degraded": 0,
            "failed": 0,
            "unknown": 0,
            "devices": {},
        }

        sensor_types = ["temperature", "humidity", "soil_moisture", "light_intensity"]

        for device_id in device_ids:
            device_status = "healthy"
            device_issues = []

            for sensor_type in sensor_types:
                failure_check = self.detect_sensor_failure(device_id, sensor_type)

                if failure_check["status"] == "failed":
                    device_status = "failed"
                    device_issues.extend(failure_check["issues"])
                elif failure_check["status"] == "degraded" and device_status != "failed":
                    device_status = "degraded"
                    device_issues.extend(failure_check["issues"])
                elif failure_check["status"] == "unknown" and device_status == "healthy":
                    device_status = "unknown"

            summary["devices"][device_id] = {
                "status": device_status,
                "issues": device_issues,
            }
            summary[device_status] += 1

        return summary
