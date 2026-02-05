"""
User authentication and management API routes.
"""

from fastapi import APIRouter, HTTPException, Header, Depends
from typing import Optional

from src.api.schemas.user_schemas import (
    LoginRequest,
    LoginResponse,
    RegisterRequest,
    UserResponse,
    UpdateUserRequest,
)
from src.services.database.user_db import get_user_db
from src.services.auth.jwt_handler import create_access_token, verify_token
from src.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/api/users", tags=["Users"])


def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """
    Dependency to extract and verify user ID from JWT token.
    
    Args:
        authorization: Authorization header with Bearer token
        
    Returns:
        User ID from token
        
    Raises:
        HTTPException: If token is missing or invalid
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
    
    token = authorization.replace("Bearer ", "")
    payload = verify_token(token)
    
    if not payload or "user_id" not in payload:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    return str(payload["user_id"])


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """
    Login with username and password.
    
    Returns JWT access token and user information.
    """
    logger.info(f"Login attempt for user: {request.username}")
    
    db = get_user_db()
    user = await db.verify_credentials(request.username, request.password)
    
    if not user:
        logger.warning(f"Failed login attempt for user: {request.username}")
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    if not user.get('is_active', True):
        logger.warning(f"Login attempt for inactive user: {request.username}")
        raise HTTPException(status_code=403, detail="User account is inactive")
    
    # Create JWT token
    token_data = {
        "user_id": str(user['id']),
        "username": user['username'],
        "role": user['role']
    }
    access_token = create_access_token(token_data)
    
    # Prepare user response (remove password_hash)
    user_response = UserResponse(
        id=str(user['id']),
        username=user['username'],
        full_name=user['full_name'],
        role=user['role'],
        email=user.get('email'),
        phone=user.get('phone'),
        language_preference=user.get('language_preference', 'en'),
        is_active=user.get('is_active', True),
        created_at=user.get('created_at')
    )
    
    logger.info(f"Successful login for user: {request.username}")
    
    return LoginResponse(
        access_token=access_token,
        user=user_response
    )


@router.post("/register", response_model=LoginResponse)
async def register(request: RegisterRequest):
    """
    Register a new user.
    
    Returns JWT access token and user information.
    """
    logger.info(f"Registration attempt for username: {request.username}")
    
    db = get_user_db()
    
    # Create user
    user = await db.create_user(
        username=request.username,
        password=request.password,
        full_name=request.full_name,
        role=request.role,
        email=request.email,
        phone=request.phone,
        language_preference=request.language_preference
    )
    
    if not user:
        logger.warning(f"Registration failed - username already exists: {request.username}")
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Create JWT token
    token_data = {
        "user_id": str(user['id']),
        "username": user['username'],
        "role": user['role']
    }
    access_token = create_access_token(token_data)
    
    # Prepare user response
    user_response = UserResponse(
        id=str(user['id']),
        username=user['username'],
        full_name=user['full_name'],
        role=user['role'],
        email=user.get('email'),
        phone=user.get('phone'),
        language_preference=user.get('language_preference', 'en'),
        is_active=user.get('is_active', True),
        created_at=user.get('created_at')
    )
    
    logger.info(f"Successful registration for user: {request.username}")
    
    return LoginResponse(
        access_token=access_token,
        user=user_response
    )


@router.post("/verify-token", response_model=UserResponse)
async def verify_user_token(user_id: str = Depends(get_current_user_id)):
    """
    Verify JWT token and return current user information.
    """
    db = get_user_db()
    user = await db.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return UserResponse(
        id=str(user['id']),
        username=user['username'],
        full_name=user['full_name'],
        role=user['role'],
        email=user.get('email'),
        phone=user.get('phone'),
        language_preference=user.get('language_preference', 'en'),
        is_active=user.get('is_active', True),
        created_at=user.get('created_at')
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user(user_id: str = Depends(get_current_user_id)):
    """
    Get current authenticated user information.
    """
    db = get_user_db()
    user = await db.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return UserResponse(
        id=str(user['id']),
        username=user['username'],
        full_name=user['full_name'],
        role=user['role'],
        email=user.get('email'),
        phone=user.get('phone'),
        language_preference=user.get('language_preference', 'en'),
        is_active=user.get('is_active', True),
        created_at=user.get('created_at')
    )


@router.put("/me", response_model=UserResponse)
async def update_current_user(
    request: UpdateUserRequest,
    user_id: str = Depends(get_current_user_id)
):
    """
    Update current authenticated user profile.
    """
    db = get_user_db()
    
    # Prepare updates (only include non-None values)
    updates = {}
    if request.full_name is not None:
        updates['full_name'] = request.full_name
    if request.email is not None:
        updates['email'] = request.email
    if request.phone is not None:
        updates['phone'] = request.phone
    if request.language_preference is not None:
        updates['language_preference'] = request.language_preference
    
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    success = await db.update_user(user_id, updates)
    
    if not success:
        raise HTTPException(status_code=500, detail="Failed to update user")
    
    # Return updated user
    user = await db.get_user_by_id(user_id)
    
    return UserResponse(
        id=str(user['id']),
        username=user['username'],
        full_name=user['full_name'],
        role=user['role'],
        email=user.get('email'),
        phone=user.get('phone'),
        language_preference=user.get('language_preference', 'en'),
        is_active=user.get('is_active', True),
        created_at=user.get('created_at')
    )


@router.post("/logout")
async def logout(user_id: str = Depends(get_current_user_id)):
    """
    Logout current user.
    
    Note: Since we're using stateless JWT tokens, logout is handled client-side
    by clearing the token. This endpoint is provided for consistency and can be
    extended to implement token blacklisting if needed.
    """
    logger.info(f"User {user_id} logged out")
    
    return {
        "success": True,
        "message": "Logged out successfully"
    }
