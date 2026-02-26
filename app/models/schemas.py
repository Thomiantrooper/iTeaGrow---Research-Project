from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from typing import List, Optional, Literal
from enum import Enum

class SoilHealth(str, Enum):
    GOOD = "Good"
    FAIR = "Fair"
    POOR = "Poor"

class SoilData(BaseModel):
    """Schema for incoming soil sensor data from ESP32"""
    # ESP32 sends: division_id, block_id, hectare_id, avg_temp, avg_hum, avg_ec, avg_ph, avg_n, avg_p, avg_k, reading_count
    
    # Map ESP32 fields to what your backend expects
    device_id: str = Field(..., alias="division_id", min_length=1, max_length=50)
    hectare_id: int = Field(..., alias="hectare_id", gt=0, le=1000)
    N: float = Field(..., alias="avg_n", ge=0, le=500, description="Nitrogen level (mg/kg)")
    P: float = Field(..., alias="avg_p", ge=0, le=500, description="Phosphorus level (mg/kg)")
    K: float = Field(..., alias="avg_k", ge=0, le=500, description="Potassium level (mg/kg)")
    pH: float = Field(..., alias="avg_ph", ge=0, le=14, description="pH level")
    EC: float = Field(..., alias="avg_ec", description="Electrical Conductivity (will be converted from µS/cm to dS/m)")
    temperature: float = Field(..., alias="avg_temp", ge=-10, le=50, description="Temperature (°C)")
    humidity: float = Field(..., alias="avg_hum", ge=0, le=100, description="Humidity (%)")
    
    # Optional fields from ESP32
    block_id: Optional[int] = Field(None, alias="block_id")
    reading_count: Optional[int] = Field(None, alias="reading_count")
    
    class Config:
        populate_by_name = True
        extra = "ignore"
        json_schema_extra = {
            "example": {
                "division_id": "north_estate_01",
                "block_id": 1,
                "hectare_id": 1,
                "avg_temp": 24.5,
                "avg_hum": 65.2,
                "avg_ec": 418.8,
                "avg_ph": 5.8,
                "avg_n": 145.2,
                "avg_p": 38.5,
                "avg_k": 172.3,
                "reading_count": 20
            }
        }

    @field_validator('pH')
    def validate_ph(cls, v):
        if v < 0 or v > 14:
            raise ValueError('pH must be between 0 and 14')
        return v
    
    @field_validator('EC')
    def convert_and_validate_ec(cls, v):
        """Convert EC from µS/cm to dS/m and validate"""
        # Convert from µS/cm to dS/m (divide by 1000)
        ec_ds_per_m = v / 1000.0
        
        # Validate the converted value is in range (0-10 dS/m)
        if ec_ds_per_m < 0 or ec_ds_per_m > 10:
            raise ValueError(f'EC must be between 0 and 10 dS/m after conversion (got {v} µS/cm = {ec_ds_per_m} dS/m)')
        
        return ec_ds_per_m

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
    EC: float  # This will be stored in dS/m
    temperature: float
    humidity: float
    block_id: Optional[int] = None
    reading_count: Optional[int] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "hectare_id": 1,
                "soil_health": "Good",
                "fertilizer": ["Maintain_Current_Practice"],
                "timestamp": "2024-01-01T00:00:00",
                "device_id": "north_estate_01",
                "N": 145.2,
                "P": 38.5,
                "K": 172.3,
                "pH": 5.8,
                "EC": 0.4188,  # Now in dS/m
                "temperature": 24.5,
                "humidity": 65.2,
                "block_id": 1,
                "reading_count": 20
            }
        }

class PredictionDocument(PredictionResponse):
    """Schema for MongoDB document"""
    _id: Optional[str] = None
    
    class Config:
        arbitrary_types_allowed = True