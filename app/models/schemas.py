from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from typing import List, Optional, Literal
from enum import Enum

class SoilHealth(str, Enum):
    GOOD = "Good"
    FAIR = "Fair"
    POOR = "Poor"

class SoilData(BaseModel):
    """Schema for incoming soil sensor data with 7 features"""
    device_id: str = Field(..., min_length=1, max_length=50)
    hectare_id: int = Field(..., gt=0, le=1000)
    N: float = Field(..., ge=0, le=500, description="Nitrogen level")
    P: float = Field(..., ge=0, le=500, description="Phosphorus level")
    K: float = Field(..., ge=0, le=500, description="Potassium level")
    pH: float = Field(..., ge=0, le=14, description="pH level")
    EC: float = Field(..., ge=0, le=10, description="Electrical Conductivity (dS/m)")
    temperature: float = Field(..., ge=-10, le=50, description="Temperature (°C)")
    humidity: float = Field(..., ge=0, le=100, description="Humidity (%)")

    @field_validator('pH')
    def validate_ph(cls, v):
        if v < 0 or v > 14:
            raise ValueError('pH must be between 0 and 14')
        return v
    
    @field_validator('EC')
    def validate_ec(cls, v):
        if v < 0 or v > 10:
            raise ValueError('EC must be between 0 and 10 dS/m')
        return v

class PredictionResponse(BaseModel):
    """Schema for prediction response"""
    hectare_id: int
    soil_health: SoilHealth
    fertilizer: List[str]
    timestamp: datetime
    device_id: str
    N: float
    P: float
    K: float
    pH: float
    EC: float
    temperature: float
    humidity: float
    
    class Config:
        json_schema_extra = {
            "example": {
                "hectare_id": 1,
                "soil_health": "Good",
                "fertilizer": ["Maintain_Current_Practice"],
                "timestamp": "2024-01-01T00:00:00",
                "device_id": "esp32_01",
                "N": 150.5,
                "P": 45.2,
                "K": 180.3,
                "pH": 6.2,
                "EC": 0.8,
                "temperature": 25.5,
                "humidity": 65.0
            }
        }

class PredictionDocument(PredictionResponse):
    """Schema for MongoDB document"""
    _id: Optional[str] = None
    
    class Config:
        arbitrary_types_allowed = True