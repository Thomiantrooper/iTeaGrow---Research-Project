"""
Pydantic schemas for user authentication API.
"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class LoginRequest(BaseModel):
    """Login request schema."""
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=3)


class RegisterRequest(BaseModel):
    """User registration request schema."""
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=3)
    full_name: str = Field(..., min_length=1, max_length=100)
    role: str = Field(..., pattern="^(farmer|manager|admin)$")
    email: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    language_preference: str = Field(default="en", pattern="^(en|si|ta)$")


class UserResponse(BaseModel):
    """User response schema (without password)."""
    id: str
    username: str
    full_name: str
    role: str
    email: Optional[str] = None
    phone: Optional[str] = None
    language_preference: str = "en"
    is_active: bool = True
    created_at: Optional[str] = None
    
    class Config:
        from_attributes = True


class LoginResponse(BaseModel):
    """Login response schema with token and user."""
    access_token: str
    user: UserResponse


class UpdateUserRequest(BaseModel):
    """Update user profile request schema."""
    full_name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    language_preference: Optional[str] = Field(None, pattern="^(en|si|ta)$")
