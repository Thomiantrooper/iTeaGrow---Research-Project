"""
Custom exceptions for the Tea Leaf Disease Detection Platform.
Provides structured error handling across all services.
"""

from typing import Optional, Any


class BaseAppException(Exception):
    """Base exception for all application errors."""

    def __init__(
        self,
        message: str,
        error_code: str = "UNKNOWN_ERROR",
        details: Optional[dict[str, Any]] = None,
        status_code: int = 500,
    ):
        self.message = message
        self.error_code = error_code
        self.details = details or {}
        self.status_code = status_code
        super().__init__(self.message)

    def to_dict(self) -> dict[str, Any]:
        """Convert exception to dictionary for API responses."""
        return {
            "error": True,
            "error_code": self.error_code,
            "message": self.message,
            "details": self.details,
        }


class ValidationError(BaseAppException):
    """Raised when input validation fails."""

    def __init__(
        self,
        message: str = "Validation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            details=details,
            status_code=422,
        )


class ModelError(BaseAppException):
    """Raised when ML model operations fail."""

    def __init__(
        self,
        message: str = "Model operation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="MODEL_ERROR",
            details=details,
            status_code=500,
        )


class ModelLoadError(ModelError):
    """Raised when model loading fails."""

    def __init__(
        self,
        message: str = "Failed to load model",
        model_path: Optional[str] = None,
    ):
        super().__init__(
            message=message,
            details={"model_path": model_path},
        )
        self.error_code = "MODEL_LOAD_ERROR"


class InferenceError(ModelError):
    """Raised when model inference fails."""

    def __init__(
        self,
        message: str = "Inference failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(message=message, details=details)
        self.error_code = "INFERENCE_ERROR"


class ImageQualityError(ValidationError):
    """Raised when image quality is insufficient."""

    def __init__(
        self,
        message: str = "Image quality is too low for reliable detection",
        quality_score: Optional[float] = None,
        issues: Optional[list[str]] = None,
    ):
        super().__init__(
            message=message,
            details={"quality_score": quality_score, "issues": issues or []},
        )
        self.error_code = "IMAGE_QUALITY_ERROR"
        self.status_code = 400


class StorageError(BaseAppException):
    """Raised when storage operations fail."""

    def __init__(
        self,
        message: str = "Storage operation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="STORAGE_ERROR",
            details=details,
            status_code=500,
        )


class LocalStorageError(StorageError):
    """Raised when local storage operations fail."""

    def __init__(
        self,
        message: str = "Local storage operation failed",
        path: Optional[str] = None,
    ):
        super().__init__(message=message, details={"path": path})
        self.error_code = "LOCAL_STORAGE_ERROR"


class CloudStorageError(StorageError):
    """Raised when cloud storage operations fail."""

    def __init__(
        self,
        message: str = "Cloud storage operation failed",
        bucket: Optional[str] = None,
        key: Optional[str] = None,
    ):
        super().__init__(message=message, details={"bucket": bucket, "key": key})
        self.error_code = "CLOUD_STORAGE_ERROR"


class IoTError(BaseAppException):
    """Raised when IoT sensor operations fail."""

    def __init__(
        self,
        message: str = "IoT operation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="IOT_ERROR",
            details=details,
            status_code=500,
        )


class SensorError(IoTError):
    """Raised when a specific sensor fails."""

    def __init__(
        self,
        message: str = "Sensor error",
        sensor_id: Optional[str] = None,
        sensor_type: Optional[str] = None,
    ):
        super().__init__(
            message=message,
            details={"sensor_id": sensor_id, "sensor_type": sensor_type},
        )
        self.error_code = "SENSOR_ERROR"


class SensorDataValidationError(IoTError):
    """Raised when sensor data fails validation."""

    def __init__(
        self,
        message: str = "Sensor data validation failed",
        sensor_id: Optional[str] = None,
        invalid_readings: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            details={"sensor_id": sensor_id, "invalid_readings": invalid_readings},
        )
        self.error_code = "SENSOR_DATA_VALIDATION_ERROR"
        self.status_code = 400


class SyncError(BaseAppException):
    """Raised when synchronization operations fail."""

    def __init__(
        self,
        message: str = "Sync operation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="SYNC_ERROR",
            details=details,
            status_code=500,
        )


class NetworkError(SyncError):
    """Raised when network connectivity fails."""

    def __init__(
        self,
        message: str = "Network connectivity error",
        retry_after: Optional[int] = None,
    ):
        super().__init__(message=message, details={"retry_after": retry_after})
        self.error_code = "NETWORK_ERROR"
        self.status_code = 503


class ConflictError(SyncError):
    """Raised when data sync conflicts occur."""

    def __init__(
        self,
        message: str = "Data sync conflict detected",
        local_version: Optional[str] = None,
        remote_version: Optional[str] = None,
    ):
        super().__init__(
            message=message,
            details={
                "local_version": local_version,
                "remote_version": remote_version,
            },
        )
        self.error_code = "CONFLICT_ERROR"
        self.status_code = 409


class AuthenticationError(BaseAppException):
    """Raised when authentication fails."""

    def __init__(
        self,
        message: str = "Authentication failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="AUTHENTICATION_ERROR",
            details=details,
            status_code=401,
        )


class AuthorizationError(BaseAppException):
    """Raised when authorization fails."""

    def __init__(
        self,
        message: str = "Access denied",
        required_permission: Optional[str] = None,
    ):
        super().__init__(
            message=message,
            error_code="AUTHORIZATION_ERROR",
            details={"required_permission": required_permission},
            status_code=403,
        )


class RateLimitError(BaseAppException):
    """Raised when rate limit is exceeded."""

    def __init__(
        self,
        message: str = "Rate limit exceeded",
        retry_after: int = 60,
    ):
        super().__init__(
            message=message,
            error_code="RATE_LIMIT_ERROR",
            details={"retry_after": retry_after},
            status_code=429,
        )


class ExplainabilityError(BaseAppException):
    """Raised when explainability operations fail."""

    def __init__(
        self,
        message: str = "Explainability operation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="EXPLAINABILITY_ERROR",
            details=details,
            status_code=500,
        )


class RecommendationError(BaseAppException):
    """Raised when recommendation generation fails."""

    def __init__(
        self,
        message: str = "Recommendation generation failed",
        details: Optional[dict[str, Any]] = None,
    ):
        super().__init__(
            message=message,
            error_code="RECOMMENDATION_ERROR",
            details=details,
            status_code=500,
        )
