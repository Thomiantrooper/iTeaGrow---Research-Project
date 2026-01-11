"""
Tests for the inference service.
"""

import pytest
import numpy as np
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent.parent))

from src.services.inference.image_processor import ImageProcessor
from src.services.inference.quality_checker import ImageQualityChecker


class TestImageProcessor:
    """Tests for ImageProcessor class."""

    def setup_method(self):
        """Set up test fixtures."""
        self.processor = ImageProcessor(target_size=640)

    def test_resize_with_padding(self):
        """Test image resizing with padding."""
        image = np.zeros((480, 640, 3), dtype=np.uint8)

        resized = self.processor.resize_with_padding(image)

        assert resized.shape == (640, 640, 3)

    def test_get_scale_factors(self):
        """Test scale factor calculation."""
        original_shape = (480, 640)

        scale_x, scale_y, offset_x, offset_y = self.processor.get_scale_factors(
            original_shape
        )

        assert scale_x > 0
        assert scale_y > 0

    def test_to_tensor_format(self):
        """Test conversion to tensor format."""
        image = np.zeros((640, 640, 3), dtype=np.float32)

        tensor = self.processor.to_tensor_format(image)

        assert tensor.shape == (1, 3, 640, 640)
        assert tensor.dtype == np.float32


class TestImageQualityChecker:
    """Tests for ImageQualityChecker class."""

    def setup_method(self):
        """Set up test fixtures."""
        self.checker = ImageQualityChecker()

    def test_check_quality_good_image(self):
        """Test quality check on a good image."""
        image = np.random.randint(50, 200, (640, 640, 3), dtype=np.uint8)

        metrics = self.checker.check_quality(image)

        assert hasattr(metrics, 'overall_score')
        assert hasattr(metrics, 'blur_score')
        assert hasattr(metrics, 'brightness_score')
        assert hasattr(metrics, 'contrast_score')
        assert 0 <= metrics.overall_score <= 1

    def test_detect_dark_image(self):
        """Test detection of dark image."""
        dark_image = np.zeros((640, 640, 3), dtype=np.uint8) + 20

        metrics = self.checker.check_quality(dark_image)

        assert metrics.brightness_score < 0.2
        assert not metrics.is_acceptable or len(metrics.issues) > 0

    def test_detect_bright_image(self):
        """Test detection of overexposed image."""
        bright_image = np.ones((640, 640, 3), dtype=np.uint8) * 250

        metrics = self.checker.check_quality(bright_image)

        assert metrics.brightness_score > 0.9

    def test_auto_enhance(self):
        """Test automatic image enhancement."""
        dark_image = np.zeros((640, 640, 3), dtype=np.uint8) + 30

        enhanced, was_enhanced = self.checker.auto_enhance(dark_image)

        assert enhanced.shape == dark_image.shape


class TestDetector:
    """Tests for TeaLeafDetector class."""

    def test_detector_initialization(self):
        """Test detector can be initialized."""
        from src.services.inference.detector import TeaLeafDetector

        detector = TeaLeafDetector()

        assert detector.confidence_threshold > 0
        assert detector.iou_threshold > 0

    def test_demo_detections(self):
        """Test demo detection generation."""
        from src.services.inference.detector import TeaLeafDetector

        detector = TeaLeafDetector()

        detections = detector._generate_demo_detections((640, 640))

        assert isinstance(detections, list)
        for det in detections:
            assert 'bbox' in det
            assert 'confidence' in det
            assert 'class_id' in det

    def test_create_summary(self):
        """Test detection summary creation."""
        from src.services.inference.detector import TeaLeafDetector
        from src.api.schemas import Detection, BoundingBox, DiseaseClass

        detector = TeaLeafDetector()

        detections = [
            Detection(
                class_name=DiseaseClass.HEALTHY,
                class_id=0,
                confidence=0.9,
                bounding_box=BoundingBox(
                    x_min=10, y_min=10, x_max=100, y_max=100, confidence=0.9
                ),
                area_percentage=5.0,
            ),
            Detection(
                class_name=DiseaseClass.RED_RUST,
                class_id=1,
                confidence=0.85,
                bounding_box=BoundingBox(
                    x_min=200, y_min=200, x_max=300, y_max=300, confidence=0.85
                ),
                area_percentage=5.0,
            ),
        ]

        summary = detector._create_summary(detections)

        assert summary.total_leaves_detected == 2
        assert summary.healthy_count == 1
        assert summary.red_rust_count == 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
