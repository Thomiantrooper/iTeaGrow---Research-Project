"""
Configuration settings for the Tea Leaf Disease Detection Platform.
Uses Pydantic Settings for type-safe environment variable management.
"""

from functools import lru_cache
from typing import Optional, List
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings


class DatabaseSettings(BaseSettings):
    """Database configuration settings."""

    host: str = Field(default="localhost", alias="DB_HOST")
    port: int = Field(default=5432, alias="DB_PORT")
    name: str = Field(default="tealeaf_db", alias="DB_NAME")
    user: str = Field(default="tealeaf", alias="DB_USER")
    password: str = Field(default="tealeaf_secret", alias="DB_PASSWORD")

    @property
    def url(self) -> str:
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.name}"

    model_config = {"env_prefix": "", "extra": "ignore"}


class RedisSettings(BaseSettings):
    """Redis configuration settings."""

    host: str = Field(default="localhost", alias="REDIS_HOST")
    port: int = Field(default=6379, alias="REDIS_PORT")
    password: Optional[str] = Field(default=None, alias="REDIS_PASSWORD")
    db: int = Field(default=0, alias="REDIS_DB")

    @property
    def url(self) -> str:
        if self.password:
            return f"redis://:{self.password}@{self.host}:{self.port}/{self.db}"
        return f"redis://{self.host}:{self.port}/{self.db}"

    model_config = {"env_prefix": "", "extra": "ignore"}


class MinIOSettings(BaseSettings):
    """MinIO/S3 storage configuration settings."""

    endpoint: str = Field(default="localhost:9000", alias="MINIO_ENDPOINT")
    access_key: str = Field(default="minioadmin", alias="MINIO_ACCESS_KEY")
    secret_key: str = Field(default="minioadmin", alias="MINIO_SECRET_KEY")
    secure: bool = Field(default=False, alias="MINIO_SECURE")
    bucket_images: str = Field(default="tea-leaf-images", alias="MINIO_BUCKET_IMAGES")
    bucket_models: str = Field(default="tea-leaf-models", alias="MINIO_BUCKET_MODELS")
    bucket_exports: str = Field(
        default="tea-leaf-exports", alias="MINIO_BUCKET_EXPORTS"
    )

    model_config = {"env_prefix": "", "extra": "ignore"}


class ModelSettings(BaseSettings):
    """ML model configuration settings."""

    model_path: str = Field(default="runs/detect/runs/detect/max_accuracy/tealeaf_95/weights/best.pt", alias="MODEL_PATH")
    onnx_path: str = Field(
        default="models/yolov8n_tealeaf.onnx", alias="ONNX_MODEL_PATH"
    )
    confidence_threshold: float = Field(default=0.25, alias="CONFIDENCE_THRESHOLD")
    iou_threshold: float = Field(default=0.45, alias="IOU_THRESHOLD")
    image_size: int = Field(default=640, alias="IMAGE_SIZE")
    device: str = Field(default="cpu", alias="DEVICE")
    use_onnx: bool = Field(default=False, alias="USE_ONNX")
    use_int8: bool = Field(default=False, alias="USE_INT8")
    max_detections: int = Field(default=100, alias="MAX_DETECTIONS")

    class_names: List[str] = Field(
        default=["healthy", "red_rust", "blister_blight"], alias="CLASS_NAMES"
    )

    @field_validator("confidence_threshold", "iou_threshold")
    @classmethod
    def validate_threshold(cls, v: float) -> float:
        if not 0 <= v <= 1:
            raise ValueError("Threshold must be between 0 and 1")
        return v

    model_config = {"env_prefix": "", "extra": "ignore"}


class IoTSettings(BaseSettings):
    """IoT sensor configuration settings."""

    sensor_timeout: int = Field(default=30, alias="SENSOR_TIMEOUT")
    data_retention_days: int = Field(default=90, alias="DATA_RETENTION_DAYS")
    aggregation_interval: int = Field(default=300, alias="AGGREGATION_INTERVAL")

    temp_min: float = Field(default=10.0, alias="TEMP_MIN")
    temp_max: float = Field(default=35.0, alias="TEMP_MAX")
    humidity_min: float = Field(default=20.0, alias="HUMIDITY_MIN")
    humidity_max: float = Field(default=100.0, alias="HUMIDITY_MAX")
    soil_moisture_min: float = Field(default=0.0, alias="SOIL_MOISTURE_MIN")
    soil_moisture_max: float = Field(default=100.0, alias="SOIL_MOISTURE_MAX")
    light_min: float = Field(default=0.0, alias="LIGHT_MIN")
    light_max: float = Field(default=100000.0, alias="LIGHT_MAX")

    model_config = {"env_prefix": "", "extra": "ignore"}


class SyncSettings(BaseSettings):
    """Sync and storage configuration settings."""

    local_storage_path: str = Field(
        default="./storage/local", alias="LOCAL_STORAGE_PATH"
    )
    sync_interval: int = Field(default=300, alias="SYNC_INTERVAL")
    max_offline_days: int = Field(default=7, alias="MAX_OFFLINE_DAYS")
    encryption_key: Optional[str] = Field(default=None, alias="ENCRYPTION_KEY")
    compression_enabled: bool = Field(default=True, alias="COMPRESSION_ENABLED")
    max_queue_size: int = Field(default=10000, alias="MAX_QUEUE_SIZE")

    model_config = {"env_prefix": "", "extra": "ignore"}


class SecuritySettings(BaseSettings):
    """Security configuration settings."""

    secret_key: str = Field(
        default="change-this-in-production-use-strong-key", alias="SECRET_KEY"
    )
    algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    access_token_expire_minutes: int = Field(
        default=30, alias="ACCESS_TOKEN_EXPIRE_MINUTES"
    )
    api_key_header: str = Field(default="X-API-Key", alias="API_KEY_HEADER")
    cors_origins: List[str] = Field(
        default=["http://localhost:3000", "http://localhost:8000"], alias="CORS_ORIGINS"
    )
    rate_limit_requests: int = Field(default=100, alias="RATE_LIMIT_REQUESTS")
    rate_limit_window: int = Field(default=60, alias="RATE_LIMIT_WINDOW")

    model_config = {"env_prefix": "", "extra": "ignore"}


class AppSettings(BaseSettings):
    """Main application settings."""

    app_name: str = Field(default="Tea Leaf Disease Detection API", alias="APP_NAME")
    app_version: str = Field(default="1.0.0", alias="APP_VERSION")
    debug: bool = Field(default=True, alias="DEBUG")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    workers: int = Field(default=4, alias="WORKERS")
    host: str = Field(default="0.0.0.0", alias="HOST")
    port: int = Field(default=8000, alias="PORT")

    database: DatabaseSettings = Field(default_factory=DatabaseSettings)
    redis: RedisSettings = Field(default_factory=RedisSettings)
    minio: MinIOSettings = Field(default_factory=MinIOSettings)
    model: ModelSettings = Field(default_factory=ModelSettings)
    iot: IoTSettings = Field(default_factory=IoTSettings)
    sync: SyncSettings = Field(default_factory=SyncSettings)
    security: SecuritySettings = Field(default_factory=SecuritySettings)

    model_config = {"env_prefix": "", "extra": "ignore", "env_file": ".env"}


@lru_cache()
def get_settings() -> AppSettings:
    """Get cached application settings."""
    return AppSettings()


settings = get_settings()
