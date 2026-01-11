"""
Security utilities for the Tea Leaf Disease Detection Platform.
Handles authentication, encryption, and API key management.
"""

import secrets
import hashlib
import hmac
import base64
from datetime import datetime, timedelta, timezone
from typing import Optional, Any
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import jwt

from configs.settings import settings
from src.core.exceptions import AuthenticationError, AuthorizationError


class SecurityManager:
    """Manages security operations including encryption and authentication."""

    def __init__(self):
        self._fernet: Optional[Fernet] = None
        self._init_encryption()

    def _init_encryption(self) -> None:
        """Initialize Fernet encryption with the configured key."""
        encryption_key = settings.sync.encryption_key
        if encryption_key:
            key = self._derive_key(encryption_key)
            self._fernet = Fernet(key)

    def _derive_key(self, password: str, salt: Optional[bytes] = None) -> bytes:
        """Derive a Fernet-compatible key from a password."""
        if salt is None:
            salt = b"tealeaf_salt_v1"

        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=480000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        return key

    def encrypt_data(self, data: bytes) -> bytes:
        """
        Encrypt binary data using Fernet encryption.

        Args:
            data: Binary data to encrypt

        Returns:
            Encrypted data

        Raises:
            ValueError: If encryption is not configured
        """
        if self._fernet is None:
            raise ValueError("Encryption not configured. Set ENCRYPTION_KEY in environment.")
        return self._fernet.encrypt(data)

    def decrypt_data(self, encrypted_data: bytes) -> bytes:
        """
        Decrypt binary data using Fernet encryption.

        Args:
            encrypted_data: Encrypted binary data

        Returns:
            Decrypted data

        Raises:
            ValueError: If encryption is not configured or decryption fails
        """
        if self._fernet is None:
            raise ValueError("Encryption not configured. Set ENCRYPTION_KEY in environment.")
        return self._fernet.decrypt(encrypted_data)

    def encrypt_string(self, text: str) -> str:
        """Encrypt a string and return base64-encoded result."""
        encrypted = self.encrypt_data(text.encode("utf-8"))
        return base64.urlsafe_b64encode(encrypted).decode("utf-8")

    def decrypt_string(self, encrypted_text: str) -> str:
        """Decrypt a base64-encoded encrypted string."""
        encrypted = base64.urlsafe_b64decode(encrypted_text.encode("utf-8"))
        decrypted = self.decrypt_data(encrypted)
        return decrypted.decode("utf-8")

    @staticmethod
    def generate_api_key() -> str:
        """Generate a secure API key."""
        return secrets.token_urlsafe(32)

    @staticmethod
    def hash_api_key(api_key: str) -> str:
        """Hash an API key for secure storage."""
        return hashlib.sha256(api_key.encode()).hexdigest()

    @staticmethod
    def verify_api_key(api_key: str, hashed_key: str) -> bool:
        """Verify an API key against its hash."""
        return hmac.compare_digest(
            hashlib.sha256(api_key.encode()).hexdigest(),
            hashed_key,
        )

    def create_access_token(
        self,
        data: dict[str, Any],
        expires_delta: Optional[timedelta] = None,
    ) -> str:
        """
        Create a JWT access token.

        Args:
            data: Token payload data
            expires_delta: Optional custom expiration time

        Returns:
            Encoded JWT token
        """
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(
                minutes=settings.security.access_token_expire_minutes
            )
        to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc)})
        encoded_jwt = jwt.encode(
            to_encode,
            settings.security.secret_key,
            algorithm=settings.security.algorithm,
        )
        return encoded_jwt

    def verify_access_token(self, token: str) -> dict[str, Any]:
        """
        Verify and decode a JWT access token.

        Args:
            token: JWT token to verify

        Returns:
            Decoded token payload

        Raises:
            AuthenticationError: If token is invalid or expired
        """
        try:
            payload = jwt.decode(
                token,
                settings.security.secret_key,
                algorithms=[settings.security.algorithm],
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Token has expired")
        except jwt.InvalidTokenError as e:
            raise AuthenticationError(f"Invalid token: {str(e)}")

    @staticmethod
    def generate_device_id() -> str:
        """Generate a unique device identifier."""
        return secrets.token_hex(16)

    @staticmethod
    def generate_request_id() -> str:
        """Generate a unique request identifier."""
        return secrets.token_hex(8)

    def create_device_token(
        self,
        device_id: str,
        plantation_id: str,
        expires_days: int = 365,
    ) -> str:
        """
        Create a long-lived device token for IoT sensors.

        Args:
            device_id: Unique device identifier
            plantation_id: Associated plantation identifier
            expires_days: Token validity in days

        Returns:
            Device JWT token
        """
        return self.create_access_token(
            data={
                "device_id": device_id,
                "plantation_id": plantation_id,
                "type": "device",
            },
            expires_delta=timedelta(days=expires_days),
        )

    def verify_device_token(self, token: str) -> dict[str, Any]:
        """
        Verify a device token.

        Args:
            token: Device JWT token

        Returns:
            Decoded token payload

        Raises:
            AuthenticationError: If token is invalid
            AuthorizationError: If token is not a device token
        """
        payload = self.verify_access_token(token)
        if payload.get("type") != "device":
            raise AuthorizationError("Invalid token type for device authentication")
        return payload


class RateLimiter:
    """Simple in-memory rate limiter for API endpoints."""

    def __init__(self):
        self._requests: dict[str, list[datetime]] = {}

    def is_allowed(
        self,
        key: str,
        max_requests: Optional[int] = None,
        window_seconds: Optional[int] = None,
    ) -> bool:
        """
        Check if a request is allowed under the rate limit.

        Args:
            key: Unique identifier for the rate limit (e.g., IP address, API key)
            max_requests: Maximum number of requests allowed in the window
            window_seconds: Time window in seconds

        Returns:
            True if request is allowed, False otherwise
        """
        max_requests = max_requests or settings.security.rate_limit_requests
        window_seconds = window_seconds or settings.security.rate_limit_window

        now = datetime.now(timezone.utc)
        window_start = now - timedelta(seconds=window_seconds)

        if key not in self._requests:
            self._requests[key] = []

        self._requests[key] = [
            req_time for req_time in self._requests[key] if req_time > window_start
        ]

        if len(self._requests[key]) >= max_requests:
            return False

        self._requests[key].append(now)
        return True

    def get_remaining(
        self,
        key: str,
        max_requests: Optional[int] = None,
        window_seconds: Optional[int] = None,
    ) -> int:
        """Get the number of remaining requests for a key."""
        max_requests = max_requests or settings.security.rate_limit_requests
        window_seconds = window_seconds or settings.security.rate_limit_window

        now = datetime.now(timezone.utc)
        window_start = now - timedelta(seconds=window_seconds)

        if key not in self._requests:
            return max_requests

        current_requests = len(
            [req_time for req_time in self._requests[key] if req_time > window_start]
        )
        return max(0, max_requests - current_requests)

    def clear(self, key: Optional[str] = None) -> None:
        """Clear rate limit data for a key or all keys."""
        if key:
            self._requests.pop(key, None)
        else:
            self._requests.clear()


security_manager = SecurityManager()
rate_limiter = RateLimiter()
