from fastapi import APIRouter, HTTPException, status, Depends
from datetime import datetime, timedelta
from typing import List
import traceback
from database import get_database
from models import (
    UserCreate, UserLogin, UserResponse, UserUpdate,
    Token, PasswordChange
)
from auth import (
    get_password_hash, verify_password, create_access_token,
    get_current_active_user
)
from config import settings

router = APIRouter(prefix="/api/users", tags=["users"])

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate):
    """Register a new user"""
    try:
        db = get_database()

        if db is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Database not connected"
            )

        # Check if username already exists
        existing_user = await db.users.find_one({"username": user.username})
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already registered"
            )

        # Check if email already exists (if provided)
        if user.email:
            existing_email = await db.users.find_one({"email": user.email})
            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )

        # Create user document - only include non-null optional fields
        # This allows sparse index on email to work properly
        user_doc = {
            "username": user.username,
            "full_name": user.full_name,
            "role": user.role,
            "language_preference": user.language_preference,
            "hashed_password": get_password_hash(user.password),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "is_active": True
        }
        # Only add email and phone if they have actual values (not None or empty)
        if user.email is not None and user.email != "":
            user_doc["email"] = user.email
        if user.phone is not None and user.phone != "":
            user_doc["phone"] = user.phone

        result = await db.users.insert_one(user_doc)
        user_doc["_id"] = result.inserted_id

        # Create access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.username, "user_id": str(result.inserted_id)},
            expires_delta=access_token_expires
        )

        return Token(
            access_token=access_token,
            user=UserResponse(
                id=str(result.inserted_id),
                username=user.username,
                full_name=user.full_name,
                email=user.email,
                phone=user.phone,
                role=user.role,
                language_preference=user.language_preference,
                created_at=user_doc["created_at"],
                is_active=True
            )
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Registration error: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@router.post("/login", response_model=Token)
async def login(credentials: UserLogin):
    """Login with username and password"""
    try:
        db = get_database()

        user = await db.users.find_one({"username": credentials.username})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password"
            )

        if not verify_password(credentials.password, user["hashed_password"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password"
            )

        if not user.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User account is deactivated"
            )

        # Create access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user["username"], "user_id": str(user["_id"])},
            expires_delta=access_token_expires
        )

        return Token(
            access_token=access_token,
            user=UserResponse(
                id=str(user["_id"]),
                username=user["username"],
                full_name=user["full_name"],
                email=user.get("email"),
                phone=user.get("phone"),
                role=user.get("role", "farmer"),
                language_preference=user.get("language_preference", "en"),
                created_at=user["created_at"],
                is_active=user.get("is_active", True)
            )
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"Login error: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: dict = Depends(get_current_active_user)):
    """Get current user profile"""
    return UserResponse(
        id=str(current_user["_id"]),
        username=current_user["username"],
        full_name=current_user["full_name"],
        email=current_user.get("email"),
        phone=current_user.get("phone"),
        role=current_user.get("role", "farmer"),
        language_preference=current_user.get("language_preference", "en"),
        created_at=current_user["created_at"],
        is_active=current_user.get("is_active", True)
    )

@router.put("/me", response_model=UserResponse)
async def update_profile(
    update: UserUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    """Update current user profile"""
    db = get_database()

    update_data = {k: v for k, v in update.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update"
        )

    update_data["updated_at"] = datetime.utcnow()

    await db.users.update_one(
        {"_id": current_user["_id"]},
        {"$set": update_data}
    )

    updated_user = await db.users.find_one({"_id": current_user["_id"]})

    return UserResponse(
        id=str(updated_user["_id"]),
        username=updated_user["username"],
        full_name=updated_user["full_name"],
        email=updated_user.get("email"),
        phone=updated_user.get("phone"),
        role=updated_user.get("role", "farmer"),
        language_preference=updated_user.get("language_preference", "en"),
        created_at=updated_user["created_at"],
        is_active=updated_user.get("is_active", True)
    )

@router.post("/change-password")
async def change_password(
    passwords: PasswordChange,
    current_user: dict = Depends(get_current_active_user)
):
    """Change user password"""
    db = get_database()

    # Verify current password
    if not verify_password(passwords.current_password, current_user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    # Update password
    await db.users.update_one(
        {"_id": current_user["_id"]},
        {
            "$set": {
                "hashed_password": get_password_hash(passwords.new_password),
                "updated_at": datetime.utcnow()
            }
        }
    )

    return {"message": "Password changed successfully"}

@router.post("/verify-token", response_model=UserResponse)
async def verify_token(current_user: dict = Depends(get_current_active_user)):
    """Verify if the current token is valid and return user info"""
    return UserResponse(
        id=str(current_user["_id"]),
        username=current_user["username"],
        full_name=current_user["full_name"],
        email=current_user.get("email"),
        phone=current_user.get("phone"),
        role=current_user.get("role", "farmer"),
        language_preference=current_user.get("language_preference", "en"),
        created_at=current_user["created_at"],
        is_active=current_user.get("is_active", True)
    )
