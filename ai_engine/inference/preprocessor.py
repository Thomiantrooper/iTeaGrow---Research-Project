"""
Image Preprocessor for Tea Leaf Disease Detection
==================================================
Handles image preprocessing, quality validation, and format conversion.
"""

import cv2
import numpy as np
from typing import Tuple, List, Optional, Dict, Union
from dataclasses import dataclass
from enum import Enum
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ImageQuality(Enum):
    """Image quality assessment categories."""
    GOOD = "good"
    ACCEPTABLE = "acceptable"
    POOR = "poor"
    INVALID = "invalid"


@dataclass
class QualityReport:
    """Image quality assessment report."""
    quality: ImageQuality
    brightness_score: float
    contrast_score: float
    blur_score: float
    is_valid: bool
    issues: List[str]


class ImagePreprocessor:
    """
    Preprocessor for tea leaf disease detection images.
    Handles validation, enhancement, and normalization.
    """

    def __init__(
        self,
        target_size: Tuple[int, int] = (640, 640),
        normalize: bool = True,
        mean: Tuple[float, ...] = (0.485, 0.456, 0.406),
        std: Tuple[float, ...] = (0.229, 0.224, 0.225)
    ):
        """
        Initialize preprocessor.

        Args:
            target_size: Target image size (width, height)
            normalize: Whether to normalize pixel values
            mean: Normalization mean (ImageNet)
            std: Normalization std (ImageNet)
        """
        self.target_size = target_size
        self.normalize = normalize
        self.mean = np.array(mean, dtype=np.float32)
        self.std = np.array(std, dtype=np.float32)

        # Quality thresholds
        self.brightness_range = (30, 220)
        self.contrast_threshold = 40
        self.blur_threshold = 100

    def preprocess(
        self,
        image: np.ndarray,
        validate_quality: bool = True,
        enhance: bool = False
    ) -> Tuple[np.ndarray, Optional[QualityReport]]:
        """
        Preprocess image for inference.

        Args:
            image: Input image (BGR format from camera/cv2)
            validate_quality: Whether to check image quality
            enhance: Whether to apply enhancement for poor quality images

        Returns:
            Tuple of (preprocessed_image, quality_report)
        """
        quality_report = None

        # Validate image
        if image is None or image.size == 0:
            raise ValueError("Invalid image: empty or None")

        # Quality assessment
        if validate_quality:
            quality_report = self.assess_quality(image)

            if quality_report.quality == ImageQuality.INVALID:
                raise ValueError(f"Image quality too poor: {quality_report.issues}")

            if enhance and quality_report.quality == ImageQuality.POOR:
                image = self.enhance_image(image, quality_report)

        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Resize with letterboxing
        image_resized, scale, padding = self.letterbox(
            image_rgb,
            self.target_size
        )

        # Convert to float32 and scale to [0, 1]
        image_float = image_resized.astype(np.float32) / 255.0

        # Normalize if required
        if self.normalize:
            image_float = (image_float - self.mean) / self.std

        # Convert to CHW format for model input
        image_chw = np.transpose(image_float, (2, 0, 1))

        # Add batch dimension
        image_batch = np.expand_dims(image_chw, axis=0)

        return image_batch, quality_report

    def letterbox(
        self,
        image: np.ndarray,
        target_size: Tuple[int, int],
        color: Tuple[int, int, int] = (114, 114, 114)
    ) -> Tuple[np.ndarray, float, Tuple[int, int]]:
        """
        Resize image with letterboxing (maintain aspect ratio).

        Args:
            image: Input image
            target_size: Target size (width, height)
            color: Padding color

        Returns:
            Tuple of (resized_image, scale, padding)
        """
        h, w = image.shape[:2]
        target_w, target_h = target_size

        # Calculate scale
        scale = min(target_w / w, target_h / h)
        new_w, new_h = int(w * scale), int(h * scale)

        # Resize
        resized = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_LINEAR)

        # Calculate padding
        pad_w = (target_w - new_w) // 2
        pad_h = (target_h - new_h) // 2

        # Apply padding
        padded = cv2.copyMakeBorder(
            resized,
            pad_h, target_h - new_h - pad_h,
            pad_w, target_w - new_w - pad_w,
            cv2.BORDER_CONSTANT,
            value=color
        )

        return padded, scale, (pad_w, pad_h)

    def assess_quality(self, image: np.ndarray) -> QualityReport:
        """
        Assess image quality for disease detection.

        Args:
            image: Input image (BGR)

        Returns:
            QualityReport with scores and issues
        """
        issues = []

        # Convert to grayscale for analysis
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Brightness analysis
        brightness = np.mean(gray)
        brightness_score = self._score_brightness(brightness)

        if brightness < self.brightness_range[0]:
            issues.append("Image too dark")
        elif brightness > self.brightness_range[1]:
            issues.append("Image too bright/overexposed")

        # Contrast analysis
        contrast = np.std(gray)
        contrast_score = min(contrast / 80, 1.0)

        if contrast < self.contrast_threshold:
            issues.append("Low contrast")

        # Blur detection (Laplacian variance)
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        blur_score = min(laplacian_var / 500, 1.0)

        if laplacian_var < self.blur_threshold:
            issues.append("Image is blurry")

        # Size check
        h, w = image.shape[:2]
        if h < 224 or w < 224:
            issues.append("Image resolution too low")

        # Determine overall quality
        avg_score = (brightness_score + contrast_score + blur_score) / 3

        if len(issues) >= 3 or "Image resolution too low" in issues:
            quality = ImageQuality.INVALID
        elif len(issues) >= 2 or avg_score < 0.4:
            quality = ImageQuality.POOR
        elif len(issues) >= 1 or avg_score < 0.7:
            quality = ImageQuality.ACCEPTABLE
        else:
            quality = ImageQuality.GOOD

        return QualityReport(
            quality=quality,
            brightness_score=brightness_score,
            contrast_score=contrast_score,
            blur_score=blur_score,
            is_valid=quality != ImageQuality.INVALID,
            issues=issues
        )

    def _score_brightness(self, brightness: float) -> float:
        """Score brightness on 0-1 scale."""
        optimal = 128
        if brightness < self.brightness_range[0]:
            return brightness / self.brightness_range[0] * 0.5
        elif brightness > self.brightness_range[1]:
            return (255 - brightness) / (255 - self.brightness_range[1]) * 0.5
        else:
            # Within acceptable range
            distance = abs(brightness - optimal)
            max_distance = max(
                optimal - self.brightness_range[0],
                self.brightness_range[1] - optimal
            )
            return 1.0 - (distance / max_distance) * 0.3

    def enhance_image(
        self,
        image: np.ndarray,
        quality_report: QualityReport
    ) -> np.ndarray:
        """
        Enhance image based on quality issues.

        Args:
            image: Input image
            quality_report: Quality assessment report

        Returns:
            Enhanced image
        """
        enhanced = image.copy()

        for issue in quality_report.issues:
            if "too dark" in issue:
                # Apply gamma correction
                enhanced = self._adjust_gamma(enhanced, 1.5)

            elif "too bright" in issue:
                enhanced = self._adjust_gamma(enhanced, 0.7)

            elif "Low contrast" in issue:
                # Apply CLAHE
                lab = cv2.cvtColor(enhanced, cv2.COLOR_BGR2LAB)
                l, a, b = cv2.split(lab)
                clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
                l = clahe.apply(l)
                enhanced = cv2.merge([l, a, b])
                enhanced = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)

            elif "blurry" in issue:
                # Apply unsharp masking
                gaussian = cv2.GaussianBlur(enhanced, (0, 0), 2.0)
                enhanced = cv2.addWeighted(enhanced, 1.5, gaussian, -0.5, 0)

        return enhanced

    def _adjust_gamma(self, image: np.ndarray, gamma: float) -> np.ndarray:
        """Apply gamma correction."""
        inv_gamma = 1.0 / gamma
        table = np.array([
            ((i / 255.0) ** inv_gamma) * 255
            for i in np.arange(0, 256)
        ]).astype("uint8")
        return cv2.LUT(image, table)

    def postprocess_detections(
        self,
        detections: np.ndarray,
        original_size: Tuple[int, int],
        scale: float,
        padding: Tuple[int, int]
    ) -> List[Dict]:
        """
        Convert model output to original image coordinates.

        Args:
            detections: Model output detections [x1, y1, x2, y2, conf, class]
            original_size: Original image size (height, width)
            scale: Scale factor used during preprocessing
            padding: Padding applied during letterboxing

        Returns:
            List of detection dictionaries
        """
        results = []
        pad_w, pad_h = padding
        orig_h, orig_w = original_size

        for det in detections:
            x1, y1, x2, y2, conf, class_id = det

            # Remove padding
            x1 = (x1 - pad_w) / scale
            y1 = (y1 - pad_h) / scale
            x2 = (x2 - pad_w) / scale
            y2 = (y2 - pad_h) / scale

            # Clip to image bounds
            x1 = max(0, min(x1, orig_w))
            y1 = max(0, min(y1, orig_h))
            x2 = max(0, min(x2, orig_w))
            y2 = max(0, min(y2, orig_h))

            results.append({
                'bbox': [int(x1), int(y1), int(x2), int(y2)],
                'confidence': float(conf),
                'class_id': int(class_id),
                'class_name': self._get_class_name(int(class_id))
            })

        return results

    def _get_class_name(self, class_id: int) -> str:
        """Get class name from ID."""
        class_names = ["healthy", "red_rust", "blister_blight"]
        if 0 <= class_id < len(class_names):
            return class_names[class_id]
        return "unknown"


def preprocess_for_inference(
    image_path: str,
    target_size: Tuple[int, int] = (640, 640)
) -> Tuple[np.ndarray, Dict]:
    """
    Convenience function to preprocess image from file.

    Args:
        image_path: Path to image file
        target_size: Target size for model

    Returns:
        Tuple of (preprocessed_image, metadata)
    """
    # Load image
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError(f"Failed to load image: {image_path}")

    preprocessor = ImagePreprocessor(target_size=target_size)

    # Preprocess
    processed, quality = preprocessor.preprocess(
        image,
        validate_quality=True,
        enhance=True
    )

    metadata = {
        'original_size': image.shape[:2],
        'quality': quality.quality.value if quality else None,
        'issues': quality.issues if quality else []
    }

    return processed, metadata
