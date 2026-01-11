"""
Pydantic schemas for the Tea Leaf Disease Detection Platform API.
Defines request/response models for all endpoints.
"""

from datetime import datetime
from enum import Enum
from typing import Optional, Any
from pydantic import BaseModel, Field, field_validator
import uuid


class DiseaseClass(str, Enum):
    """Tea leaf disease classification types."""

    HEALTHY = "healthy"
    RED_RUST = "red_rust"
    BLISTER_BLIGHT = "blister_blight"


class SeverityLevel(str, Enum):
    """Disease severity levels."""

    NONE = "none"
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class FeedbackType(str, Enum):
    """Types of user feedback."""

    CORRECT = "correct"
    INCORRECT = "incorrect"
    UNCERTAIN = "uncertain"


class SyncStatus(str, Enum):
    """Synchronization status states."""

    PENDING = "pending"
    SYNCING = "syncing"
    SYNCED = "synced"
    FAILED = "failed"
    CONFLICT = "conflict"


class BoundingBox(BaseModel):
    """Bounding box coordinates for detected objects."""

    x_min: float = Field(..., ge=0, description="Left edge coordinate")
    y_min: float = Field(..., ge=0, description="Top edge coordinate")
    x_max: float = Field(..., ge=0, description="Right edge coordinate")
    y_max: float = Field(..., ge=0, description="Bottom edge coordinate")
    confidence: float = Field(..., ge=0, le=1, description="Detection confidence")

    @field_validator("x_max")
    @classmethod
    def x_max_greater_than_x_min(cls, v: float, info) -> float:
        if "x_min" in info.data and v <= info.data["x_min"]:
            raise ValueError("x_max must be greater than x_min")
        return v

    @field_validator("y_max")
    @classmethod
    def y_max_greater_than_y_min(cls, v: float, info) -> float:
        if "y_min" in info.data and v <= info.data["y_min"]:
            raise ValueError("y_max must be greater than y_min")
        return v


class Detection(BaseModel):
    """Single object detection result."""

    detection_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    class_name: DiseaseClass
    class_id: int = Field(..., ge=0, le=2)
    confidence: float = Field(..., ge=0, le=1)
    bounding_box: BoundingBox
    area_percentage: float = Field(..., ge=0, le=100, description="Affected area percentage")


class ImageQualityMetrics(BaseModel):
    """Image quality assessment metrics."""

    overall_score: float = Field(..., ge=0, le=1)
    blur_score: float = Field(..., ge=0, le=1)
    brightness_score: float = Field(..., ge=0, le=1)
    contrast_score: float = Field(..., ge=0, le=1)
    is_acceptable: bool
    issues: list[str] = Field(default_factory=list)


class InferenceRequest(BaseModel):
    """Request schema for image inference."""

    image_id: Optional[str] = Field(default=None, description="Optional image identifier")
    plantation_id: Optional[str] = Field(default=None, description="Plantation identifier")
    location_lat: Optional[float] = Field(default=None, ge=-90, le=90)
    location_lng: Optional[float] = Field(default=None, ge=-180, le=180)
    capture_timestamp: Optional[datetime] = Field(default=None)
    request_explainability: bool = Field(default=False)
    metadata: dict[str, Any] = Field(default_factory=dict)


class InferenceResponse(BaseModel):
    """Response schema for image inference."""

    request_id: str
    image_id: str
    timestamp: datetime
    processing_time_ms: float
    model_version: str
    image_quality: ImageQualityMetrics
    detections: list[Detection]
    summary: "DetectionSummary"
    explainability_task_id: Optional[str] = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class DetectionSummary(BaseModel):
    """Summary of detection results."""

    total_leaves_detected: int = Field(..., ge=0)
    healthy_count: int = Field(..., ge=0)
    red_rust_count: int = Field(..., ge=0)
    blister_blight_count: int = Field(..., ge=0)
    overall_health_score: float = Field(..., ge=0, le=100)
    dominant_disease: Optional[DiseaseClass] = None
    severity_level: SeverityLevel
    requires_immediate_action: bool


class ExplainabilityRequest(BaseModel):
    """Request schema for Grad-CAM explainability."""

    image_id: str
    detection_ids: Optional[list[str]] = Field(
        default=None,
        description="Specific detections to explain. If None, explains all."
    )
    target_classes: Optional[list[DiseaseClass]] = Field(
        default=None,
        description="Specific classes to generate heatmaps for"
    )


class ExplainabilityResult(BaseModel):
    """Single explainability result for a detection."""

    detection_id: str
    class_name: DiseaseClass
    heatmap_url: str
    attention_regions: list[dict[str, Any]]
    confidence_breakdown: dict[str, float]


class ExplainabilityResponse(BaseModel):
    """Response schema for Grad-CAM explainability."""

    task_id: str
    image_id: str
    status: str
    processing_time_ms: Optional[float] = None
    results: list[ExplainabilityResult] = Field(default_factory=list)
    combined_heatmap_url: Optional[str] = None


class SensorReading(BaseModel):
    """Individual sensor reading."""

    sensor_id: str
    sensor_type: str
    value: float
    unit: str
    timestamp: datetime
    quality: float = Field(default=1.0, ge=0, le=1, description="Reading quality score")


class IoTDataPayload(BaseModel):
    """IoT sensor data ingestion payload."""

    device_id: str
    plantation_id: str
    timestamp: datetime
    temperature: Optional[float] = Field(default=None, description="Temperature in Celsius")
    humidity: Optional[float] = Field(default=None, ge=0, le=100, description="Relative humidity %")
    soil_moisture: Optional[float] = Field(default=None, ge=0, le=100, description="Soil moisture %")
    light_intensity: Optional[float] = Field(default=None, ge=0, description="Light in lux")
    battery_level: Optional[float] = Field(default=None, ge=0, le=100)
    signal_strength: Optional[float] = Field(default=None, ge=-100, le=0, description="RSSI in dBm")
    raw_readings: list[SensorReading] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


class IoTDataResponse(BaseModel):
    """Response for IoT data ingestion."""

    ingestion_id: str
    device_id: str
    timestamp: datetime
    status: str
    validation_results: dict[str, bool]
    alerts: list[str] = Field(default_factory=list)


class EnvironmentalConditions(BaseModel):
    """Current environmental conditions summary."""

    plantation_id: str
    timestamp: datetime
    temperature_avg: Optional[float] = None
    temperature_min: Optional[float] = None
    temperature_max: Optional[float] = None
    humidity_avg: Optional[float] = None
    soil_moisture_avg: Optional[float] = None
    light_intensity_avg: Optional[float] = None
    disease_risk_factors: dict[str, float] = Field(default_factory=dict)
    sensor_health: dict[str, str] = Field(default_factory=dict)


class RecommendationPriority(str, Enum):
    """Priority levels for recommendations."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class Recommendation(BaseModel):
    """Single recommendation item."""

    recommendation_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    category: str
    priority: RecommendationPriority
    title: str
    description: str
    action_steps: list[str]
    expected_outcome: str
    timing: Optional[str] = None
    cost_estimate: Optional[str] = None
    related_diseases: list[DiseaseClass] = Field(default_factory=list)


class RecommendationRequest(BaseModel):
    """Request for disease recommendations."""

    plantation_id: str
    detection_summary: Optional[DetectionSummary] = None
    environmental_conditions: Optional[EnvironmentalConditions] = None
    include_preventive: bool = Field(default=True)
    max_recommendations: int = Field(default=10, ge=1, le=50)


class RecommendationResponse(BaseModel):
    """Response containing recommendations."""

    request_id: str
    plantation_id: str
    timestamp: datetime
    recommendations: list[Recommendation]
    overall_risk_assessment: str
    next_assessment_date: Optional[datetime] = None


class UserFeedback(BaseModel):
    """User feedback on detection results."""

    feedback_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    image_id: str
    detection_id: Optional[str] = None
    feedback_type: FeedbackType
    correct_class: Optional[DiseaseClass] = None
    user_notes: Optional[str] = Field(default=None, max_length=1000)
    timestamp: datetime = Field(default_factory=lambda: datetime.now())
    user_id: Optional[str] = None


class FeedbackResponse(BaseModel):
    """Response for feedback submission."""

    feedback_id: str
    status: str
    message: str
    retraining_queued: bool = False


class SyncQueueItem(BaseModel):
    """Item in the synchronization queue."""

    item_id: str
    item_type: str
    action: str
    data: dict[str, Any]
    created_at: datetime
    priority: int = Field(default=0)
    retry_count: int = Field(default=0)
    max_retries: int = Field(default=5)
    status: SyncStatus = Field(default=SyncStatus.PENDING)
    error_message: Optional[str] = None


class SyncStatusResponse(BaseModel):
    """Response for sync status queries."""

    is_online: bool
    last_sync_time: Optional[datetime] = None
    pending_uploads: int = Field(..., ge=0)
    pending_downloads: int = Field(..., ge=0)
    failed_items: int = Field(..., ge=0)
    queue_size: int = Field(..., ge=0)
    storage_used_mb: float = Field(..., ge=0)
    storage_available_mb: float = Field(..., ge=0)


class HealthCheckResponse(BaseModel):
    """API health check response."""

    status: str
    version: str
    timestamp: datetime
    services: dict[str, str]
    model_loaded: bool
    storage_status: str
    redis_status: str


class ErrorResponse(BaseModel):
    """Standard error response."""

    error: bool = True
    error_code: str
    message: str
    details: dict[str, Any] = Field(default_factory=dict)
    request_id: Optional[str] = None
    timestamp: datetime = Field(default_factory=lambda: datetime.now())


class BatchInferenceRequest(BaseModel):
    """Request for batch image inference."""

    images: list[str] = Field(..., min_length=1, max_length=50, description="List of image IDs")
    plantation_id: Optional[str] = None
    request_explainability: bool = Field(default=False)


class BatchInferenceResponse(BaseModel):
    """Response for batch inference."""

    batch_id: str
    status: str
    total_images: int
    processed: int
    failed: int
    results: list[InferenceResponse] = Field(default_factory=list)
    errors: list[dict[str, Any]] = Field(default_factory=list)


class ModelInfoResponse(BaseModel):
    """Model information response."""

    model_name: str
    model_version: str
    model_type: str
    input_size: int
    classes: list[str]
    device: str
    quantization: Optional[str] = None
    loaded_at: datetime
    total_inferences: int
    average_inference_time_ms: float


InferenceResponse.model_rebuild()
