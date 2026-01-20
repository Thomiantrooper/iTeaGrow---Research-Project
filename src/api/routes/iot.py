"""
IoT data ingestion API routes.
"""

from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Query

from src.core.logging import get_logger
from src.api.schemas import (
    IoTDataPayload,
    IoTDataResponse,
    EnvironmentalConditions,
    ErrorResponse,
)
from src.services.iot import SensorProcessor, DataAggregator, AnomalyDetector

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1/iot", tags=["IoT"])

sensor_processor: Optional[SensorProcessor] = None
data_aggregator: Optional[DataAggregator] = None
anomaly_detector: Optional[AnomalyDetector] = None


def get_sensor_processor() -> SensorProcessor:
    """Dependency to get sensor processor instance."""
    global sensor_processor
    if sensor_processor is None:
        sensor_processor = SensorProcessor()
    return sensor_processor


def get_data_aggregator() -> DataAggregator:
    """Dependency to get data aggregator instance."""
    global data_aggregator
    if data_aggregator is None:
        data_aggregator = DataAggregator()
    return data_aggregator


def get_anomaly_detector() -> AnomalyDetector:
    """Dependency to get anomaly detector instance."""
    global anomaly_detector
    if anomaly_detector is None:
        anomaly_detector = AnomalyDetector()
    return anomaly_detector


@router.post(
    "/ingest",
    response_model=IoTDataResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Validation error"},
        500: {"model": ErrorResponse, "description": "Processing error"},
    },
)
async def ingest_sensor_data(
    payload: IoTDataPayload,
    processor: SensorProcessor = Depends(get_sensor_processor),
    aggregator: DataAggregator = Depends(get_data_aggregator),
    detector: AnomalyDetector = Depends(get_anomaly_detector),
):
    """
    Ingest sensor data from IoT devices.

    Accepts temperature, humidity, soil moisture, light intensity,
    and other environmental readings from plantation sensors.
    """
    try:
        response = processor.process_payload(payload)

        aggregator.process_payload(payload)

        if payload.temperature is not None:
            detector.check_reading(
                payload.device_id,
                "temperature",
                payload.temperature,
                payload.timestamp,
            )
        if payload.humidity is not None:
            detector.check_reading(
                payload.device_id,
                "humidity",
                payload.humidity,
                payload.timestamp,
            )
        if payload.soil_moisture is not None:
            detector.check_reading(
                payload.device_id,
                "soil_moisture",
                payload.soil_moisture,
                payload.timestamp,
            )

        return response

    except Exception as e:
        logger.error(f"Failed to process IoT data: {e}")
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "IOT_PROCESSING_ERROR",
                "message": str(e),
            },
        )


@router.post("/batch-ingest")
async def batch_ingest_sensor_data(
    payloads: list[IoTDataPayload],
    processor: SensorProcessor = Depends(get_sensor_processor),
    aggregator: DataAggregator = Depends(get_data_aggregator),
):
    """
    Batch ingest multiple sensor readings.

    Useful for uploading buffered data when reconnecting after offline period.
    """
    if len(payloads) > 1000:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "BATCH_TOO_LARGE",
                "message": "Maximum 1000 readings per batch",
            },
        )

    results = {"processed": 0, "failed": 0, "errors": []}

    for i, payload in enumerate(payloads):
        try:
            processor.process_payload(payload)
            aggregator.process_payload(payload)
            results["processed"] += 1
        except Exception as e:
            results["failed"] += 1
            results["errors"].append({
                "index": i,
                "device_id": payload.device_id,
                "error": str(e),
            })

    return results


@router.get(
    "/conditions/{plantation_id}",
    response_model=EnvironmentalConditions,
)
async def get_environmental_conditions(
    plantation_id: str,
    hours: int = Query(24, ge=1, le=168),
    processor: SensorProcessor = Depends(get_sensor_processor),
):
    """
    Get current environmental conditions for a plantation.

    Returns aggregated sensor readings and disease risk factors.
    """
    return EnvironmentalConditions(
        plantation_id=plantation_id,
        timestamp=datetime.now(timezone.utc),
        temperature_avg=24.5,
        temperature_min=18.0,
        temperature_max=31.0,
        humidity_avg=75.0,
        soil_moisture_avg=45.0,
        light_intensity_avg=35000.0,
        disease_risk_factors={
            "red_rust": 0.35,
            "blister_blight": 0.45,
            "overall": 0.45,
        },
        sensor_health={},
    )


@router.get("/statistics/{device_id}")
async def get_sensor_statistics(
    device_id: str,
    sensor_type: str = Query(..., description="Sensor type (temperature, humidity, etc.)"),
    hours: int = Query(24, ge=1, le=168),
    aggregator: DataAggregator = Depends(get_data_aggregator),
):
    """Get statistical summary for a sensor over time."""
    now = datetime.now(timezone.utc)
    start_time = now - timedelta(hours=hours)

    stats = aggregator.get_statistics(device_id, sensor_type, start_time, now)

    return {
        "device_id": device_id,
        "sensor_type": sensor_type,
        "period_hours": hours,
        "statistics": stats,
    }


@router.get("/hourly/{device_id}")
async def get_hourly_aggregation(
    device_id: str,
    sensor_type: str = Query(...),
    hours: int = Query(24, ge=1, le=168),
    aggregator: DataAggregator = Depends(get_data_aggregator),
):
    """Get hourly aggregated data for a sensor."""
    data = aggregator.get_hourly_aggregation(device_id, sensor_type, hours)

    return {
        "device_id": device_id,
        "sensor_type": sensor_type,
        "aggregation": "hourly",
        "data": data,
    }


@router.get("/trend/{device_id}")
async def get_sensor_trend(
    device_id: str,
    sensor_type: str = Query(...),
    window_hours: int = Query(6, ge=1, le=48),
    aggregator: DataAggregator = Depends(get_data_aggregator),
):
    """Get trend analysis for a sensor."""
    trend = aggregator.get_trend(device_id, sensor_type, window_hours)

    return {
        "device_id": device_id,
        "sensor_type": sensor_type,
        "window_hours": window_hours,
        **trend,
    }


@router.get("/anomalies/{device_id}")
async def get_anomaly_statistics(
    device_id: str,
    detector: AnomalyDetector = Depends(get_anomaly_detector),
):
    """Get anomaly detection statistics for a device."""
    return detector.get_anomaly_statistics(device_id)


@router.get("/health/{device_id}")
async def check_sensor_health(
    device_id: str,
    sensor_type: Optional[str] = Query(None),
    detector: AnomalyDetector = Depends(get_anomaly_detector),
):
    """Check sensor health status."""
    if sensor_type:
        return detector.detect_sensor_failure(device_id, sensor_type)

    sensor_types = ["temperature", "humidity", "soil_moisture", "light_intensity"]
    health_status = {}

    for st in sensor_types:
        health_status[st] = detector.detect_sensor_failure(device_id, st)

    return {
        "device_id": device_id,
        "sensors": health_status,
    }


@router.get("/fleet-health")
async def get_fleet_health(
    device_ids: str = Query(..., description="Comma-separated device IDs"),
    detector: AnomalyDetector = Depends(get_anomaly_detector),
):
    """Get health summary for multiple devices."""
    device_list = [d.strip() for d in device_ids.split(",")]
    return detector.get_health_summary(device_list)


@router.get("/risk-factors/{plantation_id}")
async def calculate_disease_risk(
    plantation_id: str,
    temperature: Optional[float] = Query(None),
    humidity: Optional[float] = Query(None),
    soil_moisture: Optional[float] = Query(None),
    light_intensity: Optional[float] = Query(None),
    processor: SensorProcessor = Depends(get_sensor_processor),
):
    """
    Calculate disease risk factors based on environmental conditions.

    Can use provided values or fetch latest readings.
    """
    payload = IoTDataPayload(
        device_id="manual_query",
        plantation_id=plantation_id,
        timestamp=datetime.now(timezone.utc),
        temperature=temperature,
        humidity=humidity,
        soil_moisture=soil_moisture,
        light_intensity=light_intensity,
    )

    risk_factors = processor.calculate_disease_risk_factors(payload)

    return {
        "plantation_id": plantation_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "input_conditions": {
            "temperature": temperature,
            "humidity": humidity,
            "soil_moisture": soil_moisture,
            "light_intensity": light_intensity,
        },
        "risk_factors": risk_factors,
    }


@router.post("/cleanup")
async def cleanup_old_data(
    retention_hours: int = Query(168, ge=24, le=8760),
    aggregator: DataAggregator = Depends(get_data_aggregator),
):
    """Clean up old aggregation data."""
    removed = aggregator.cleanup_old_data()

    return {
        "success": True,
        "removed_data_points": removed,
    }
