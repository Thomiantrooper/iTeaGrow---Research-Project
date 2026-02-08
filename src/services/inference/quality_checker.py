"""
Image quality assessment for reliable disease detection.
"""

from typing import Tuple
import numpy as np
import cv2

from src.core.logging import get_logger
from src.api.schemas import ImageQualityMetrics

logger = get_logger(__name__)


class ImageQualityChecker:
    """Assesses image quality for reliable inference."""

    def __init__(
        self,
        min_blur_score: float = 0.5,  # Stricter: increased from 0.3 to 0.5
        min_brightness: float = 0.20,  # Stricter: increased from 0.15 to 0.20
        max_brightness: float = 0.80,  # Stricter: decreased from 0.85 to 0.80
        min_contrast: float = 0.25,  # Stricter: increased from 0.2 to 0.25
    ):
        """
        Initialize quality checker with STRICTER production-grade thresholds.

        Production-ready thresholds for real-world tea leaf detection:
        - Higher blur threshold ensures sharp, detailed images
        - Tighter brightness range for consistent lighting
        - Higher contrast for better disease feature visibility

        Args:
            min_blur_score: Minimum acceptable blur score (higher = sharper)
            min_brightness: Minimum acceptable brightness (0-1)
            max_brightness: Maximum acceptable brightness (0-1)
            min_contrast: Minimum acceptable contrast (0-1)
        """
        self.min_blur_score = min_blur_score
        self.min_brightness = min_brightness
        self.max_brightness = max_brightness
        self.min_contrast = min_contrast

    def check_quality(self, image: np.ndarray) -> ImageQualityMetrics:
        """
        Perform comprehensive image quality assessment.

        Args:
            image: Input image in BGR format

        Returns:
            ImageQualityMetrics with detailed quality information
        """
        blur_score = self._calculate_blur_score(image)
        brightness_score = self._calculate_brightness_score(image)
        contrast_score = self._calculate_contrast_score(image)

        issues = []

        if blur_score < self.min_blur_score:
            issues.append(f"Image is too blurry (score: {blur_score:.2f})")

        if brightness_score < self.min_brightness:
            issues.append(f"Image is too dark (brightness: {brightness_score:.2f})")
        elif brightness_score > self.max_brightness:
            issues.append(f"Image is overexposed (brightness: {brightness_score:.2f})")

        if contrast_score < self.min_contrast:
            issues.append(f"Image has low contrast (score: {contrast_score:.2f})")

        dim_issues = self._check_dimensions(image)
        issues.extend(dim_issues)

        color_issues = self._check_color_distribution(image)
        issues.extend(color_issues)

        overall_score = self._calculate_overall_score(
            blur_score, brightness_score, contrast_score, len(issues)
        )

        is_acceptable = len(issues) == 0 or (
            len(issues) <= 1 and overall_score >= 0.5
        )

        return ImageQualityMetrics(
            overall_score=overall_score,
            blur_score=blur_score,
            brightness_score=brightness_score,
            contrast_score=contrast_score,
            is_acceptable=is_acceptable,
            issues=issues,
        )

    def _calculate_blur_score(self, image: np.ndarray) -> float:
        """
        Calculate blur score using Laplacian variance.

        Args:
            image: Input image

        Returns:
            Blur score normalized to 0-1 (higher = sharper)
        """
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()

        score = min(laplacian_var / 500.0, 1.0)

        return score

    def _calculate_brightness_score(self, image: np.ndarray) -> float:
        """
        Calculate brightness score.

        Args:
            image: Input image

        Returns:
            Brightness score (0-1)
        """
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        brightness = hsv[:, :, 2].mean() / 255.0

        return brightness

    def _calculate_contrast_score(self, image: np.ndarray) -> float:
        """
        Calculate contrast score using standard deviation of luminance.

        Args:
            image: Input image

        Returns:
            Contrast score normalized to 0-1
        """
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        contrast = gray.std() / 128.0

        return min(contrast, 1.0)

    def _check_dimensions(self, image: np.ndarray) -> list[str]:
        """
        Check image dimensions for potential issues.

        Args:
            image: Input image

        Returns:
            List of dimension-related issues
        """
        issues = []
        height, width = image.shape[:2]

        if width < 320 or height < 320:
            issues.append(f"Image resolution too low: {width}x{height}")

        aspect_ratio = max(width, height) / min(width, height)
        if aspect_ratio > 3.0:
            issues.append(f"Unusual aspect ratio: {aspect_ratio:.1f}:1")

        return issues

    def _check_color_distribution(self, image: np.ndarray) -> list[str]:
        """
        Check for abnormal color distribution.

        Args:
            image: Input image

        Returns:
            List of color-related issues
        """
        issues = []

        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        saturation_mean = hsv[:, :, 1].mean()

        if saturation_mean < 20:
            issues.append("Image appears grayscale or very desaturated")

        b, g, r = cv2.split(image)
        total_pixels = image.shape[0] * image.shape[1]

        if np.sum(r > 240) > total_pixels * 0.3:
            issues.append("Possible red color cast or overexposure in red channel")
        if np.sum(b > 240) > total_pixels * 0.3:
            issues.append("Possible blue color cast")

        green_ratio = np.mean(g) / (np.mean(r) + np.mean(b) + 1)
        if green_ratio < 0.3:
            issues.append("Low green content - may not contain tea leaves")

        return issues

    def _calculate_overall_score(
        self,
        blur_score: float,
        brightness_score: float,
        contrast_score: float,
        issue_count: int,
    ) -> float:
        """
        Calculate overall quality score.

        Args:
            blur_score: Blur assessment score
            brightness_score: Brightness assessment score
            contrast_score: Contrast assessment score
            issue_count: Number of detected issues

        Returns:
            Overall quality score (0-1)
        """
        brightness_normalized = 1.0 - abs(brightness_score - 0.5) * 2

        weighted_score = (
            blur_score * 0.4
            + brightness_normalized * 0.3
            + contrast_score * 0.3
        )

        penalty = issue_count * 0.1
        final_score = max(0.0, weighted_score - penalty)

        return min(final_score, 1.0)

    def get_enhancement_suggestions(
        self,
        metrics: ImageQualityMetrics,
    ) -> list[str]:
        """
        Generate suggestions for improving image quality.

        Args:
            metrics: Quality assessment results

        Returns:
            List of improvement suggestions
        """
        suggestions = []

        if metrics.blur_score < self.min_blur_score:
            suggestions.append(
                "Hold the camera steady or use a tripod to reduce blur"
            )
            suggestions.append("Ensure the lens is clean and properly focused")

        if metrics.brightness_score < self.min_brightness:
            suggestions.append(
                "Increase lighting or move to a brighter area"
            )
            suggestions.append("Avoid shadows falling on the leaves")
        elif metrics.brightness_score > self.max_brightness:
            suggestions.append(
                "Reduce direct sunlight or use shade"
            )
            suggestions.append("Avoid flash photography if possible")

        if metrics.contrast_score < self.min_contrast:
            suggestions.append(
                "Ensure leaves are clearly visible against the background"
            )
            suggestions.append("Avoid uniform lighting conditions")

        return suggestions

    def auto_enhance(self, image: np.ndarray) -> Tuple[np.ndarray, bool]:
        """
        Attempt automatic image enhancement for better detection.

        Args:
            image: Input image

        Returns:
            Tuple of (enhanced_image, was_enhanced)
        """
        enhanced = image.copy()
        was_enhanced = False

        metrics = self.check_quality(image)

        if metrics.brightness_score < self.min_brightness:
            lab = cv2.cvtColor(enhanced, cv2.COLOR_BGR2LAB)
            l, a, b = cv2.split(lab)

            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            l = clahe.apply(l)

            lab = cv2.merge((l, a, b))
            enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
            was_enhanced = True

        elif metrics.brightness_score > self.max_brightness:
            enhanced = cv2.convertScaleAbs(enhanced, alpha=0.8, beta=-20)
            was_enhanced = True

        if metrics.contrast_score < self.min_contrast:
            lab = cv2.cvtColor(enhanced, cv2.COLOR_BGR2LAB)
            l, a, b = cv2.split(lab)

            clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
            l = clahe.apply(l)

            lab = cv2.merge((l, a, b))
            enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
            was_enhanced = True

        if metrics.blur_score < self.min_blur_score:
            kernel = np.array([[-1, -1, -1],
                               [-1,  9, -1],
                               [-1, -1, -1]])
            enhanced = cv2.filter2D(enhanced, -1, kernel)
            was_enhanced = True

        return enhanced, was_enhanced
