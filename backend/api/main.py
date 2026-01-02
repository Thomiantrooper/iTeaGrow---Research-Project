"""
Tea Leaf Disease Detection API
===============================
FastAPI backend for cloud sync, model management, and analytics.
"""

from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from enum import Enum
import uuid
import os
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Tea Leaf Disease Detection API",
    description="Backend API for Sri Lankan tea plantation disease monitoring",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()


# Enums
class DiseaseType(str, Enum):
    HEALTHY = "healthy"
    RED_RUST = "red_rust"
    BLISTER_BLIGHT = "blister_blight"


class SyncStatus(str, Enum):
    PENDING = "pending"
    SYNCED = "synced"
    FAILED = "failed"


# Pydantic Models
class Detection(BaseModel):
    bbox: List[float]
    class_name: str = Field(alias="class")
    confidence: float

    class Config:
        populate_by_name = True


class ScanData(BaseModel):
    id: str
    imageData: Optional[str] = None
    diseaseType: DiseaseType
    confidence: float
    affectedCount: int
    totalLeaves: int
    detections: List[Dict[str, Any]]
    recommendations: List[Dict[str, Any]]
    environmentalData: Optional[Dict[str, Any]] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    createdAt: str


class SensorReading(BaseModel):
    id: str
    deviceId: str
    temperature: float
    humidity: float
    soilMoisture: float
    lightIntensity: float
    isValid: bool
    createdAt: str


class SensorBatchSync(BaseModel):
    readings: List[SensorReading]


class FeedbackItem(BaseModel):
    id: str
    scanId: str
    predictedDisease: str
    correctDisease: str
    notes: Optional[str] = None
    createdAt: str


class FeedbackBatchSync(BaseModel):
    feedback: List[FeedbackItem]


class SyncResponse(BaseModel):
    success: bool
    synced_count: int
    message: str


class ModelInfo(BaseModel):
    version: str
    downloadUrl: str
    checksum: str
    releaseNotes: str
    minAppVersion: str


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str


class DiseaseStats(BaseModel):
    total_scans: int
    disease_counts: Dict[str, int]
    recent_alerts: int
    avg_confidence: float


# In-memory storage (replace with database in production)
scans_db: Dict[str, ScanData] = {}
sensors_db: Dict[str, SensorReading] = {}
feedback_db: Dict[str, FeedbackItem] = {}


# Authentication (simplified - use proper auth in production)
async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify JWT token."""
    # In production, implement proper JWT verification
    if not credentials.credentials:
        raise HTTPException(status_code=401, detail="Invalid token")
    return credentials.credentials


# Routes
@app.get("/", response_model=HealthResponse)
async def root():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0"
    )


@app.get("/api/v1/health", response_model=HealthResponse)
async def health_check():
    """API health check."""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0"
    )


# Sync Endpoints
@app.post("/api/v1/sync/scans", response_model=SyncResponse)
async def sync_scan(
    scan: ScanData,
    background_tasks: BackgroundTasks,
    # token: str = Depends(verify_token)
):
    """Sync a scan record from mobile device."""
    try:
        # Store scan
        scans_db[scan.id] = scan

        # Process image in background if provided
        if scan.imageData:
            background_tasks.add_task(process_image, scan.id, scan.imageData)

        logger.info(f"Synced scan {scan.id}, disease: {scan.diseaseType}")

        return SyncResponse(
            success=True,
            synced_count=1,
            message="Scan synced successfully"
        )
    except Exception as e:
        logger.error(f"Failed to sync scan: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/sync/sensors", response_model=SyncResponse)
async def sync_sensors(
    data: SensorBatchSync,
    # token: str = Depends(verify_token)
):
    """Sync sensor readings in batch."""
    try:
        for reading in data.readings:
            sensors_db[reading.id] = reading

        logger.info(f"Synced {len(data.readings)} sensor readings")

        return SyncResponse(
            success=True,
            synced_count=len(data.readings),
            message=f"Synced {len(data.readings)} sensor readings"
        )
    except Exception as e:
        logger.error(f"Failed to sync sensors: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/sync/feedback", response_model=SyncResponse)
async def sync_feedback(
    data: FeedbackBatchSync,
    background_tasks: BackgroundTasks,
    # token: str = Depends(verify_token)
):
    """Sync user feedback for model improvement."""
    try:
        for item in data.feedback:
            feedback_db[item.id] = item

            # Queue for model retraining pipeline
            background_tasks.add_task(process_feedback, item)

        logger.info(f"Synced {len(data.feedback)} feedback items")

        return SyncResponse(
            success=True,
            synced_count=len(data.feedback),
            message=f"Synced {len(data.feedback)} feedback items"
        )
    except Exception as e:
        logger.error(f"Failed to sync feedback: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Model Management
@app.get("/api/v1/model/latest", response_model=ModelInfo)
async def get_latest_model():
    """Get latest model version information."""
    return ModelInfo(
        version="1.0.0",
        downloadUrl="https://storage.example.com/models/yolov8n-tea-v1.0.0.onnx",
        checksum="abc123def456",
        releaseNotes="Initial release with Red Rust and Blister Blight detection",
        minAppVersion="1.0.0"
    )


@app.get("/api/v1/model/check/{current_version}")
async def check_model_update(current_version: str):
    """Check if model update is available."""
    latest_version = "1.0.0"

    return {
        "updateAvailable": current_version < latest_version,
        "currentVersion": current_version,
        "latestVersion": latest_version
    }


# Analytics
@app.get("/api/v1/analytics/stats", response_model=DiseaseStats)
async def get_disease_stats(
    days: int = 30,
    # token: str = Depends(verify_token)
):
    """Get disease detection statistics."""
    # Calculate stats from stored data
    cutoff = datetime.utcnow() - timedelta(days=days)

    disease_counts = {"healthy": 0, "red_rust": 0, "blister_blight": 0}
    total_confidence = 0
    alert_count = 0

    for scan in scans_db.values():
        scan_date = datetime.fromisoformat(scan.createdAt.replace('Z', '+00:00'))
        if scan_date > cutoff:
            disease_counts[scan.diseaseType.value] = disease_counts.get(scan.diseaseType.value, 0) + 1
            total_confidence += scan.confidence

            if scan.diseaseType != DiseaseType.HEALTHY:
                alert_count += 1

    total_scans = len(scans_db)
    avg_confidence = total_confidence / total_scans if total_scans > 0 else 0

    return DiseaseStats(
        total_scans=total_scans,
        disease_counts=disease_counts,
        recent_alerts=alert_count,
        avg_confidence=avg_confidence
    )


@app.get("/api/v1/analytics/trends")
async def get_disease_trends(
    days: int = 7,
    # token: str = Depends(verify_token)
):
    """Get disease detection trends over time."""
    # Group scans by date
    daily_counts = {}
    cutoff = datetime.utcnow() - timedelta(days=days)

    for scan in scans_db.values():
        scan_date = datetime.fromisoformat(scan.createdAt.replace('Z', '+00:00'))
        if scan_date > cutoff:
            date_key = scan_date.strftime('%Y-%m-%d')
            if date_key not in daily_counts:
                daily_counts[date_key] = {"healthy": 0, "red_rust": 0, "blister_blight": 0}
            daily_counts[date_key][scan.diseaseType.value] += 1

    return {
        "period_days": days,
        "daily_counts": daily_counts
    }


@app.get("/api/v1/analytics/environmental")
async def get_environmental_analysis(
    device_id: Optional[str] = None,
    hours: int = 24,
    # token: str = Depends(verify_token)
):
    """Analyze environmental conditions and disease correlation."""
    cutoff = datetime.utcnow() - timedelta(hours=hours)

    readings = []
    for reading in sensors_db.values():
        if device_id and reading.deviceId != device_id:
            continue

        reading_date = datetime.fromisoformat(reading.createdAt.replace('Z', '+00:00'))
        if reading_date > cutoff:
            readings.append(reading)

    if not readings:
        return {"error": "No data available"}

    # Calculate averages
    avg_temp = sum(r.temperature for r in readings) / len(readings)
    avg_humidity = sum(r.humidity for r in readings) / len(readings)
    avg_soil = sum(r.soilMoisture for r in readings) / len(readings)
    avg_light = sum(r.lightIntensity for r in readings) / len(readings)

    # Assess risk
    red_rust_risk = "low"
    if 25 <= avg_temp <= 30 and avg_humidity >= 70:
        red_rust_risk = "high" if avg_humidity >= 80 else "medium"

    blister_risk = "low"
    if 15 <= avg_temp <= 25 and avg_humidity >= 85:
        blister_risk = "high"
    elif avg_humidity >= 75:
        blister_risk = "medium"

    return {
        "period_hours": hours,
        "sample_count": len(readings),
        "averages": {
            "temperature": round(avg_temp, 1),
            "humidity": round(avg_humidity, 1),
            "soilMoisture": round(avg_soil, 1),
            "lightIntensity": round(avg_light, 0)
        },
        "risk_assessment": {
            "red_rust": red_rust_risk,
            "blister_blight": blister_risk
        }
    }


# Recommendations
@app.get("/api/v1/recommendations/{disease_type}")
async def get_recommendations(disease_type: str):
    """Get disease-specific recommendations."""
    recommendations = {
        "red_rust": {
            "preventive": [
                {"action": "Maintain proper shade management", "priority": "medium"},
                {"action": "Ensure good air circulation", "priority": "medium"},
                {"action": "Apply copper-based fungicide spray", "priority": "high"},
                {"action": "Avoid excessive nitrogen fertilization", "priority": "low"}
            ],
            "corrective": [
                {"action": "Apply copper oxychloride spray (0.5%)", "priority": "urgent"},
                {"action": "Remove severely infected leaves", "priority": "high"},
                {"action": "Increase monitoring frequency", "priority": "medium"}
            ]
        },
        "blister_blight": {
            "preventive": [
                {"action": "Maintain proper drainage", "priority": "high"},
                {"action": "Apply protective copper fungicide", "priority": "high"},
                {"action": "Avoid plucking during wet conditions", "priority": "medium"}
            ],
            "corrective": [
                {"action": "Apply hexaconazole fungicide", "priority": "urgent"},
                {"action": "Remove infected young shoots", "priority": "high"},
                {"action": "Suspend plucking for 7-10 days", "priority": "medium"}
            ]
        },
        "healthy": {
            "preventive": [
                {"action": "Continue regular monitoring", "priority": "low"},
                {"action": "Maintain optimal growing conditions", "priority": "low"}
            ],
            "corrective": []
        }
    }

    if disease_type not in recommendations:
        raise HTTPException(status_code=404, detail="Disease type not found")

    return recommendations[disease_type]


# Background Tasks
async def process_image(scan_id: str, image_data: str):
    """Process and store image in cloud storage."""
    logger.info(f"Processing image for scan {scan_id}")
    # In production: decode base64, upload to S3/MinIO, etc.
    pass


async def process_feedback(feedback: FeedbackItem):
    """Queue feedback for model retraining pipeline."""
    logger.info(f"Processing feedback {feedback.id}: {feedback.predictedDisease} -> {feedback.correctDisease}")
    # In production: add to retraining queue, update active learning pool, etc.
    pass


# Error handlers
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}")
    return {"error": "Internal server error", "detail": str(exc)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
