"""
Image preprocessing and augmentation utilities for inference.
"""

import io
from typing import Tuple, Optional
import numpy as np
import cv2
from PIL import Image

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import ValidationError

logger = get_logger(__name__)


class ImageProcessor:
    """Handles image preprocessing for model inference."""

    SUPPORTED_FORMATS = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tiff"}
    MAX_FILE_SIZE = 20 * 1024 * 1024  # 20MB
    MIN_DIMENSION = 224
    MAX_DIMENSION = 4096

    def __init__(self, target_size: Optional[int] = None):
        """
        Initialize the image processor.

        Args:
            target_size: Target image size for model input
        """
        self.target_size = target_size or settings.model.image_size

    def load_image(self, image_bytes: bytes) -> np.ndarray:
        """
        Load image from bytes and convert to numpy array.

        Args:
            image_bytes: Raw image bytes

        Returns:
            Image as numpy array in BGR format

        Raises:
            ValidationError: If image cannot be loaded or is invalid
        """
        if len(image_bytes) > self.MAX_FILE_SIZE:
            raise ValidationError(
                f"Image size exceeds maximum allowed ({self.MAX_FILE_SIZE / 1024 / 1024:.1f}MB)",
                details={"size_bytes": len(image_bytes)},
            )

        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            if image is None:
                pil_image = Image.open(io.BytesIO(image_bytes))
                image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)

            if image is None:
                raise ValidationError("Failed to decode image")

            return image

        except Exception as e:
            logger.error(f"Failed to load image: {str(e)}")
            raise ValidationError(f"Invalid image format: {str(e)}")

    def validate_dimensions(self, image: np.ndarray) -> Tuple[bool, list[str]]:
        """
        Validate image dimensions.

        Args:
            image: Input image

        Returns:
            Tuple of (is_valid, list of issues)
        """
        issues = []
        height, width = image.shape[:2]

        if width < self.MIN_DIMENSION or height < self.MIN_DIMENSION:
            issues.append(
                f"Image too small: {width}x{height}. Minimum: {self.MIN_DIMENSION}x{self.MIN_DIMENSION}"
            )

        if width > self.MAX_DIMENSION or height > self.MAX_DIMENSION:
            issues.append(
                f"Image too large: {width}x{height}. Maximum: {self.MAX_DIMENSION}x{self.MAX_DIMENSION}"
            )

        return len(issues) == 0, issues

    def preprocess(
        self,
        image: np.ndarray,
        normalize: bool = True,
        to_rgb: bool = True,
    ) -> np.ndarray:
        """
        Preprocess image for model inference.

        Args:
            image: Input image in BGR format
            normalize: Whether to normalize pixel values to [0, 1]
            to_rgb: Whether to convert BGR to RGB

        Returns:
            Preprocessed image
        """
        processed = image.copy()

        if to_rgb:
            processed = cv2.cvtColor(processed, cv2.COLOR_BGR2RGB)

        processed = self.resize_with_padding(processed)

        if normalize:
            processed = processed.astype(np.float32) / 255.0

        return processed

    def resize_with_padding(
        self,
        image: np.ndarray,
        pad_color: Tuple[int, int, int] = (114, 114, 114),
    ) -> np.ndarray:
        """
        Resize image to target size while maintaining aspect ratio with padding.

        Args:
            image: Input image
            pad_color: Color for padding (gray by default)

        Returns:
            Resized and padded image
        """
        height, width = image.shape[:2]
        target = self.target_size

        scale = min(target / width, target / height)
        new_width = int(width * scale)
        new_height = int(height * scale)

        resized = cv2.resize(
            image,
            (new_width, new_height),
            interpolation=cv2.INTER_LINEAR,
        )

        canvas = np.full((target, target, 3), pad_color, dtype=np.uint8)

        x_offset = (target - new_width) // 2
        y_offset = (target - new_height) // 2

        canvas[y_offset:y_offset + new_height, x_offset:x_offset + new_width] = resized

        return canvas

    def resize_simple(self, image: np.ndarray) -> np.ndarray:
        """
        Simple resize to target size (may distort aspect ratio).

        Args:
            image: Input image

        Returns:
            Resized image
        """
        return cv2.resize(
            image,
            (self.target_size, self.target_size),
            interpolation=cv2.INTER_LINEAR,
        )

    def get_scale_factors(self, original_shape: Tuple[int, int]) -> Tuple[float, float, int, int]:
        """
        Calculate scale factors for mapping detections back to original coordinates.

        Args:
            original_shape: Original image (height, width)

        Returns:
            Tuple of (scale_x, scale_y, offset_x, offset_y)
        """
        orig_height, orig_width = original_shape[:2]
        target = self.target_size

        scale = min(target / orig_width, target / orig_height)
        new_width = int(orig_width * scale)
        new_height = int(orig_height * scale)

        offset_x = (target - new_width) // 2
        offset_y = (target - new_height) // 2

        return 1.0 / scale, 1.0 / scale, offset_x, offset_y

    def to_tensor_format(self, image: np.ndarray) -> np.ndarray:
        """
        Convert image to tensor format (NCHW).

        Args:
            image: Image in HWC format

        Returns:
            Image in NCHW format
        """
        transposed = np.transpose(image, (2, 0, 1))
        batched = np.expand_dims(transposed, axis=0)
        return batched.astype(np.float32)

    def denormalize(self, image: np.ndarray) -> np.ndarray:
        """
        Denormalize image from [0, 1] to [0, 255].

        Args:
            image: Normalized image

        Returns:
            Denormalized image as uint8
        """
        return (image * 255).clip(0, 255).astype(np.uint8)

    def draw_detections(
        self,
        image: np.ndarray,
        detections: list[dict],
        class_colors: Optional[dict[str, Tuple[int, int, int]]] = None,
    ) -> np.ndarray:
        """
        Draw bounding boxes and labels on image.

        Args:
            image: Input image
            detections: List of detection dictionaries
            class_colors: Color mapping for each class

        Returns:
            Image with drawn detections
        """
        if class_colors is None:
            class_colors = {
                "healthy": (0, 255, 0),       # Green
                "red_rust": (0, 0, 255),      # Red
                "blister_blight": (255, 0, 0), # Blue
            }

        result = image.copy()

        for det in detections:
            bbox = det.get("bounding_box", {})
            x_min = int(bbox.get("x_min", 0))
            y_min = int(bbox.get("y_min", 0))
            x_max = int(bbox.get("x_max", 0))
            y_max = int(bbox.get("y_max", 0))

            class_name = det.get("class_name", "unknown")
            confidence = det.get("confidence", 0)

            color = class_colors.get(class_name, (128, 128, 128))

            cv2.rectangle(result, (x_min, y_min), (x_max, y_max), color, 2)

            label = f"{class_name}: {confidence:.2f}"
            label_size, _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)

            cv2.rectangle(
                result,
                (x_min, y_min - label_size[1] - 10),
                (x_min + label_size[0], y_min),
                color,
                -1,
            )

            cv2.putText(
                result,
                label,
                (x_min, y_min - 5),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (255, 255, 255),
                1,
            )

        return result

    def encode_image(
        self,
        image: np.ndarray,
        format: str = "jpeg",
        quality: int = 95,
    ) -> bytes:
        """
        Encode image to bytes.

        Args:
            image: Image to encode
            format: Output format (jpeg, png)
            quality: JPEG quality (1-100)

        Returns:
            Encoded image bytes
        """
        if format.lower() == "jpeg":
            encode_params = [cv2.IMWRITE_JPEG_QUALITY, quality]
            ext = ".jpg"
        elif format.lower() == "png":
            encode_params = [cv2.IMWRITE_PNG_COMPRESSION, 9 - (quality // 11)]
            ext = ".png"
        else:
            raise ValueError(f"Unsupported format: {format}")

        success, buffer = cv2.imencode(ext, image, encode_params)

        if not success:
            raise RuntimeError("Failed to encode image")

        return buffer.tobytes()
