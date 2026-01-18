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
class DiseaseDetection(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    image_path: str
    disease_name: str
    confidence: float
    severity: Optional[str] = None
    recommendations: Optional[List[str]] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(populate_by_name=True)

class DiseaseDetectionCreate(BaseModel):
    image_path: str
    disease_name: str
    confidence: float
    severity: Optional[str] = None
    recommendations: Optional[List[str]] = None

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
