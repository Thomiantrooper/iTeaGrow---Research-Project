"""
Data aggregation for IoT sensor readings.
Provides time-series aggregation and statistical analysis.
"""

from datetime import datetime, timezone, timedelta
from typing import Optional
from collections import defaultdict
import statistics

from configs.settings import settings
from src.core.logging import get_logger
from src.api.schemas import IoTDataPayload

logger = get_logger(__name__)


class TimeSeriesBuffer:
    """Circular buffer for time-series sensor data."""

    def __init__(self, max_size: int = 1000):
        self.max_size = max_size
        self._data: list[tuple[datetime, float]] = []

    def add(self, timestamp: datetime, value: float) -> None:
        """Add a data point to the buffer."""
        self._data.append((timestamp, value))
        if len(self._data) > self.max_size:
            self._data.pop(0)

    def get_range(
        self,
        start: datetime,
        end: datetime,
    ) -> list[tuple[datetime, float]]:
        """Get data points within a time range."""
        return [
            (ts, val) for ts, val in self._data
            if start <= ts <= end
        ]

    def get_latest(self, n: int = 1) -> list[tuple[datetime, float]]:
        """Get the n most recent data points."""
        return self._data[-n:]

    def clear(self) -> None:
        """Clear all data from the buffer."""
        self._data.clear()

    def __len__(self) -> int:
        return len(self._data)


class DataAggregator:
    """
    Aggregates and analyzes IoT sensor data over time.
    Provides hourly, daily, and custom interval statistics.
    """

    def __init__(
        self,
        aggregation_interval: Optional[int] = None,
        retention_hours: int = 168,
    ):
        """
        Initialize the data aggregator.

        Args:
            aggregation_interval: Aggregation interval in seconds
            retention_hours: Hours of data to retain (default: 1 week)
        """
        self.aggregation_interval = (
            aggregation_interval or settings.iot.aggregation_interval
        )
        self.retention_hours = retention_hours

        self._buffers: dict[str, dict[str, TimeSeriesBuffer]] = defaultdict(
            lambda: defaultdict(lambda: TimeSeriesBuffer())
        )

        self._aggregated_stats: dict[str, dict[str, list[dict]]] = defaultdict(
            lambda: defaultdict(list)
        )

    def add_reading(
        self,
        device_id: str,
        sensor_type: str,
        timestamp: datetime,
        value: float,
    ) -> None:
        """
        Add a sensor reading to the aggregation buffer.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor
            timestamp: Reading timestamp
            value: Sensor value
        """
        self._buffers[device_id][sensor_type].add(timestamp, value)

    def process_payload(self, payload: IoTDataPayload) -> None:
        """
        Process an IoT payload and add all readings to buffers.

        Args:
            payload: IoT data payload
        """
        device_id = payload.device_id
        timestamp = payload.timestamp

        if payload.temperature is not None:
            self.add_reading(device_id, "temperature", timestamp, payload.temperature)

        if payload.humidity is not None:
            self.add_reading(device_id, "humidity", timestamp, payload.humidity)

        if payload.soil_moisture is not None:
            self.add_reading(device_id, "soil_moisture", timestamp, payload.soil_moisture)

        if payload.light_intensity is not None:
            self.add_reading(device_id, "light_intensity", timestamp, payload.light_intensity)

        if payload.battery_level is not None:
            self.add_reading(device_id, "battery", timestamp, payload.battery_level)

        for reading in payload.raw_readings:
            self.add_reading(
                device_id,
                f"raw_{reading.sensor_type}",
                reading.timestamp,
                reading.value,
            )

    def get_statistics(
        self,
        device_id: str,
        sensor_type: str,
        start_time: datetime,
        end_time: datetime,
    ) -> dict:
        """
        Calculate statistics for a sensor over a time range.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor
            start_time: Start of time range
            end_time: End of time range

        Returns:
            Dictionary with statistical measures
        """
        buffer = self._buffers.get(device_id, {}).get(sensor_type)
        if not buffer:
            return self._empty_stats()

        data = buffer.get_range(start_time, end_time)
        if not data:
            return self._empty_stats()

        values = [v for _, v in data]

        return {
            "count": len(values),
            "min": min(values),
            "max": max(values),
            "mean": statistics.mean(values),
            "median": statistics.median(values),
            "std_dev": statistics.stdev(values) if len(values) > 1 else 0.0,
            "first_timestamp": data[0][0].isoformat(),
            "last_timestamp": data[-1][0].isoformat(),
            "first_value": data[0][1],
            "last_value": data[-1][1],
        }

    def _empty_stats(self) -> dict:
        """Return empty statistics dictionary."""
        return {
            "count": 0,
            "min": None,
            "max": None,
            "mean": None,
            "median": None,
            "std_dev": None,
            "first_timestamp": None,
            "last_timestamp": None,
            "first_value": None,
            "last_value": None,
        }

    def get_hourly_aggregation(
        self,
        device_id: str,
        sensor_type: str,
        hours: int = 24,
    ) -> list[dict]:
        """
        Get hourly aggregated statistics.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor
            hours: Number of hours to aggregate

        Returns:
            List of hourly statistics
        """
        now = datetime.now(timezone.utc)
        results = []

        for h in range(hours):
            end_time = now - timedelta(hours=h)
            start_time = end_time - timedelta(hours=1)

            stats = self.get_statistics(device_id, sensor_type, start_time, end_time)
            stats["hour"] = start_time.strftime("%Y-%m-%d %H:00")
            results.append(stats)

        return list(reversed(results))

    def get_daily_aggregation(
        self,
        device_id: str,
        sensor_type: str,
        days: int = 7,
    ) -> list[dict]:
        """
        Get daily aggregated statistics.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor
            days: Number of days to aggregate

        Returns:
            List of daily statistics
        """
        now = datetime.now(timezone.utc)
        results = []

        for d in range(days):
            end_time = now - timedelta(days=d)
            start_time = end_time - timedelta(days=1)

            stats = self.get_statistics(device_id, sensor_type, start_time, end_time)
            stats["date"] = start_time.strftime("%Y-%m-%d")
            results.append(stats)

        return list(reversed(results))

    def get_trend(
        self,
        device_id: str,
        sensor_type: str,
        window_hours: int = 6,
    ) -> dict:
        """
        Calculate trend for a sensor over a time window.

        Args:
            device_id: Device identifier
            sensor_type: Type of sensor
            window_hours: Time window in hours

        Returns:
            Trend analysis dictionary
        """
        now = datetime.now(timezone.utc)
        start_time = now - timedelta(hours=window_hours)

        buffer = self._buffers.get(device_id, {}).get(sensor_type)
        if not buffer:
            return {"trend": "unknown", "change": 0.0, "data_points": 0}

        data = buffer.get_range(start_time, now)
        if len(data) < 2:
            return {"trend": "insufficient_data", "change": 0.0, "data_points": len(data)}

        values = [v for _, v in data]
        first_half_mean = statistics.mean(values[:len(values)//2])
        second_half_mean = statistics.mean(values[len(values)//2:])

        change = second_half_mean - first_half_mean
        change_percent = (change / first_half_mean * 100) if first_half_mean != 0 else 0

        if abs(change_percent) < 5:
            trend = "stable"
        elif change > 0:
            trend = "increasing"
        else:
            trend = "decreasing"

        return {
            "trend": trend,
            "change": change,
            "change_percent": change_percent,
            "data_points": len(data),
            "first_half_mean": first_half_mean,
            "second_half_mean": second_half_mean,
        }

    def get_plantation_summary(
        self,
        plantation_id: str,
        device_ids: list[str],
        hours: int = 24,
    ) -> dict:
        """
        Get summary statistics for all devices in a plantation.

        Args:
            plantation_id: Plantation identifier
            device_ids: List of device identifiers
            hours: Time window in hours

        Returns:
            Plantation-wide summary statistics
        """
        now = datetime.now(timezone.utc)
        start_time = now - timedelta(hours=hours)

        summary = {
            "plantation_id": plantation_id,
            "period_start": start_time.isoformat(),
            "period_end": now.isoformat(),
            "device_count": len(device_ids),
            "sensors": {},
        }

        sensor_types = ["temperature", "humidity", "soil_moisture", "light_intensity"]

        for sensor_type in sensor_types:
            all_values = []

            for device_id in device_ids:
                buffer = self._buffers.get(device_id, {}).get(sensor_type)
                if buffer:
                    data = buffer.get_range(start_time, now)
                    all_values.extend([v for _, v in data])

            if all_values:
                summary["sensors"][sensor_type] = {
                    "count": len(all_values),
                    "min": min(all_values),
                    "max": max(all_values),
                    "mean": statistics.mean(all_values),
                    "std_dev": statistics.stdev(all_values) if len(all_values) > 1 else 0.0,
                }
            else:
                summary["sensors"][sensor_type] = None

        return summary

    def cleanup_old_data(self) -> int:
        """
        Remove data older than retention period.

        Returns:
            Number of data points removed
        """
        cutoff = datetime.now(timezone.utc) - timedelta(hours=self.retention_hours)
        removed = 0

        for device_buffers in self._buffers.values():
            for buffer in device_buffers.values():
                original_len = len(buffer)
                buffer._data = [
                    (ts, val) for ts, val in buffer._data
                    if ts > cutoff
                ]
                removed += original_len - len(buffer)

        if removed > 0:
            logger.info(f"Cleaned up {removed} old data points")

        return removed
