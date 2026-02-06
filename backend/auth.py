from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from config import settings
from database import get_database
from models import TokenData

security = HTTPBearer()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return bcrypt.checkpw(
        plain_password.encode('utf-8'),
        hashed_password.encode('utf-8')
    )

def get_password_hash(password: str) -> str:
    """Hash a password"""
    return bcrypt.hashpw(
        password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_token(token: str) -> Optional[TokenData]:
    """Decode and validate a JWT token"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        user_id: str = payload.get("user_id")
        if username is None:
            return None
        return TokenData(username=username, user_id=user_id)
    except JWTError:
        return None

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get the current authenticated user from JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token = credentials.credentials
    token_data = decode_token(token)

    if token_data is None:
        raise credentials_exception

    db = get_database()

    # MOCK AUTHENTICATION FALLBACK
    if db is None:
        mock_users = {
            "admin": {"id": "mock_admin_id", "role": "admin", "full_name": "Mock Administrator"},
            "manager": {"id": "mock_manager_id", "role": "manager", "full_name": "Mock Manager"},
            "farmer": {"id": "mock_farmer_id", "role": "farmer", "full_name": "Mock Farmer"}
        }
        
        if token_data.username in mock_users:
            user_info = mock_users[token_data.username]
            print(f"[INFO] Using mock {user_info['role']} user")
            return {
                "_id": user_info["id"],
                "username": token_data.username,
                "full_name": user_info["full_name"],
                "email": f"{token_data.username}@example.com",
                "hashed_password": "mock_hash", # Not checked here (token validation)
                "role": user_info["role"],
                "is_active": True,
                "created_at": datetime.utcnow()
            }
        raise credentials_exception

    user = await db.users.find_one({"username": token_data.username})

    if user is None:
        raise credentials_exception

    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )

    return user

async def get_current_active_user(current_user: dict = Depends(get_current_user)):
    """Get current active user"""
    return current_user
