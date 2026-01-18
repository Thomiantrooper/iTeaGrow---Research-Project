from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
from datetime import datetime

# User Models
class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    full_name: str = Field(..., min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    role: str = Field(default="farmer")
    language_preference: str = Field(default="en")

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: str
    username: str
    full_name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    role: str = "farmer"
    language_preference: str = "en"
    created_at: datetime
    is_active: bool = True

    model_config = ConfigDict(from_attributes=True)

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    language_preference: Optional[str] = None

class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=6)

# Token Models
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class TokenData(BaseModel):
    username: Optional[str] = None
    user_id: Optional[str] = None

# Disease Detection Models
class BoundingBoxModel(BaseModel):
    x_min: float
    y_min: float
    x_max: float
    y_max: float
    confidence: float

class DetectionItem(BaseModel):
    detection_id: str
    class_name: str
    class_id: int
    confidence: float
    area_percentage: Optional[float] = None
    bounding_box: Optional[BoundingBoxModel] = None

class DetectionSummary(BaseModel):
    total_leaves_detected: int = 0
    healthy_count: int = 0
    red_rust_count: int = 0
    blister_blight_count: int = 0
    overall_health_score: float = 0.0
    dominant_disease: Optional[str] = None
    severity_level: str = "Low"
    requires_immediate_action: bool = False

class DiseaseDetection(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    image_path: str
    image_data: Optional[str] = None  # Base64 encoded image for storage
    disease_name: str
    confidence: float
    severity: Optional[str] = None
    recommendations: Optional[List[str]] = None
    # Enhanced detection data
    detections: Optional[List[DetectionItem]] = None
    summary: Optional[DetectionSummary] = None
    # Environmental context
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    air_quality: Optional[float] = None
    # Processing metadata
    processing_time_ms: Optional[float] = None
    model_version: Optional[str] = None
    request_id: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(populate_by_name=True)

class DiseaseDetectionCreate(BaseModel):
    image_path: Optional[str] = None
    image_data: Optional[str] = None  # Base64 encoded image
    disease_name: str
    confidence: float
    severity: Optional[str] = None
    recommendations: Optional[List[str]] = None
    # Enhanced detection data
    detections: Optional[List[DetectionItem]] = None
    summary: Optional[DetectionSummary] = None
    # Environmental context
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    air_quality: Optional[float] = None
    # Processing metadata
    processing_time_ms: Optional[float] = None
    model_version: Optional[str] = None
    request_id: Optional[str] = None

# IoT Data Models
class IoTDataPoint(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    device_id: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    air_quality: Optional[float] = None
    light_level: Optional[float] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(populate_by_name=True)

class IoTDataCreate(BaseModel):
    device_id: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    air_quality: Optional[float] = None
    light_level: Optional[float] = None

# Sync Models
class SyncData(BaseModel):
    users: Optional[List[dict]] = None
    disease_detections: Optional[List[dict]] = None
    iot_data: Optional[List[dict]] = None
    last_sync: datetime = Field(default_factory=datetime.utcnow)
