"""
Global Configuration Settings for Tea Leaf Disease Detection System
====================================================================
"""

import os
from pathlib import Path
from dataclasses import dataclass, field
from typing import Dict, List, Tuple
from enum import Enum


class DiseaseClass(Enum):
    """Tea leaf disease classification classes."""
    HEALTHY = 0
    RED_RUST = 1
    BLISTER_BLIGHT = 2


@dataclass
class ModelConfig:
    """YOLOv8n model configuration."""
    model_name: str = "yolov8n"
    input_size: Tuple[int, int] = (640, 640)
    num_classes: int = 3
    class_names: List[str] = field(default_factory=lambda: ["healthy", "red_rust", "blister_blight"])
    confidence_threshold: float = 0.5
    iou_threshold: float = 0.45
    max_detections: int = 100

    # Training hyperparameters
    epochs: int = 100
    batch_size: int = 16
    learning_rate: float = 0.01
    weight_decay: float = 0.0005
    warmup_epochs: int = 3
    patience: int = 20

    # Export formats
    export_formats: List[str] = field(default_factory=lambda: ["onnx", "tflite", "coreml"])


@dataclass
class AugmentationConfig:
    """Data augmentation configuration for field conditions."""
    # Geometric transforms
    horizontal_flip: float = 0.5
    vertical_flip: float = 0.1
    rotation_range: Tuple[int, int] = (-15, 15)
    scale_range: Tuple[float, float] = (0.8, 1.2)

    # Color/lighting transforms (for variable field lighting)
    brightness_range: Tuple[float, float] = (0.7, 1.3)
    contrast_range: Tuple[float, float] = (0.8, 1.2)
    saturation_range: Tuple[float, float] = (0.8, 1.2)
    hue_range: float = 0.02

    # Noise and blur (for camera quality variation)
    gaussian_noise_var: Tuple[float, float] = (0.0, 0.02)
    motion_blur_prob: float = 0.1

    # Occlusion simulation (for overlapping leaves)
    random_erasing_prob: float = 0.2
    mosaic_prob: float = 0.5
    mixup_prob: float = 0.1


@dataclass
class EnvironmentalThresholds:
    """Environmental thresholds for disease-favorable conditions."""

    # Red Rust favorable conditions
    red_rust_temp_min: float = 25.0
    red_rust_temp_max: float = 30.0
    red_rust_humidity_min: float = 70.0
    red_rust_humidity_max: float = 90.0
    red_rust_soil_moisture_min: float = 60.0
    red_rust_light_max: float = 500.0  # lux (shaded conditions)

    # Blister Blight favorable conditions
    blister_blight_temp_min: float = 15.0
    blister_blight_temp_max: float = 25.0
    blister_blight_humidity_min: float = 85.0
    blister_blight_soil_moisture_min: float = 50.0
    blister_blight_soil_moisture_max: float = 70.0
    blister_blight_light_max: float = 300.0  # lux (overcast/low light)


@dataclass
class IoTConfig:
    """IoT sensor configuration."""
    sampling_interval_seconds: int = 300  # 5 minutes
    sensor_timeout_seconds: int = 10
    ble_service_uuid: str = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    mqtt_broker: str = "mqtt.example.com"
    mqtt_port: int = 1883
    mqtt_topic_prefix: str = "tea/sensors"

    # Sensor calibration offsets
    temp_offset: float = 0.0
    humidity_offset: float = 0.0
    soil_moisture_offset: float = 0.0


@dataclass
class MobileConfig:
    """Mobile application configuration."""
    database_name: str = "tea_disease_db.sqlite"
    max_offline_images: int = 1000
    image_quality: int = 85  # JPEG quality
    sync_batch_size: int = 50
    retry_attempts: int = 3
    cache_duration_hours: int = 24


@dataclass
class CloudConfig:
    """Cloud backend configuration."""
    api_base_url: str = "https://api.teadisease.example.com"
    api_version: str = "v1"
    storage_bucket: str = "tea-disease-images"
    model_registry_bucket: str = "tea-disease-models"
    jwt_expiry_hours: int = 24
    rate_limit_per_minute: int = 60


# Path configurations
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / "data"
MODEL_DIR = BASE_DIR / "ai_engine" / "models"
EXPORT_DIR = BASE_DIR / "exports"

# Create directories if they don't exist
for dir_path in [DATA_DIR, MODEL_DIR, EXPORT_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)


# Disease-specific recommendation templates
DISEASE_RECOMMENDATIONS = {
    DiseaseClass.RED_RUST: {
        "preventive": [
            "Maintain proper shade management with adequate pruning",
            "Ensure good air circulation by proper spacing",
            "Apply copper-based fungicide spray preventively during high-risk periods",
            "Remove and destroy heavily infected leaves",
            "Avoid excessive nitrogen fertilization"
        ],
        "corrective": [
            "Apply copper oxychloride spray (0.5% concentration) immediately",
            "Remove severely infected branches and dispose away from plantation",
            "Increase monitoring frequency to every 3 days",
            "Reduce shade intensity to decrease humidity",
            "Apply lime sulphur spray as alternative treatment"
        ]
    },
    DiseaseClass.BLISTER_BLIGHT: {
        "preventive": [
            "Maintain proper drainage to avoid waterlogging",
            "Apply protective copper fungicide before monsoon season",
            "Avoid plucking during wet conditions",
            "Ensure adequate spacing between bushes",
            "Monitor young leaves especially during cool, humid weather"
        ],
        "corrective": [
            "Apply hexaconazole or propiconazole fungicide spray",
            "Remove and destroy infected young shoots immediately",
            "Suspend plucking for 7-10 days if infection is severe",
            "Apply systemic fungicide for internal protection",
            "Increase plucking frequency to remove infected flush"
        ]
    },
    DiseaseClass.HEALTHY: {
        "preventive": [
            "Continue regular monitoring schedule",
            "Maintain optimal fertilization program",
            "Ensure proper shade management",
            "Follow integrated pest management practices",
            "Keep records of environmental conditions"
        ],
        "corrective": []
    }
}


# Localization strings
SUPPORTED_LANGUAGES = ["en", "si", "ta"]

DISEASE_NAMES = {
    "en": {
        DiseaseClass.HEALTHY: "Healthy",
        DiseaseClass.RED_RUST: "Red Rust",
        DiseaseClass.BLISTER_BLIGHT: "Blister Blight"
    },
    "si": {
        DiseaseClass.HEALTHY: "සෞඛ්‍ය සම්පන්න",
        DiseaseClass.RED_RUST: "රතු මලකඩ",
        DiseaseClass.BLISTER_BLIGHT: "බ්ලිස්ටර් බ්ලයිට්"
    },
    "ta": {
        DiseaseClass.HEALTHY: "ஆரோக்கியமான",
        DiseaseClass.RED_RUST: "சிவப்பு துரு",
        DiseaseClass.BLISTER_BLIGHT: "கொப்புள நோய்"
    }
}
