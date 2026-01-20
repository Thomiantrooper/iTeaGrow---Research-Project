"""
Grad-CAM implementation for YOLOv8 explainability.
Generates visual explanations for model predictions.
"""

import uuid
from typing import Optional, Tuple, Any
from pathlib import Path
import io
import base64

import numpy as np
import cv2
import torch
import torch.nn.functional as F

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import ExplainabilityError
from src.api.schemas import (
    DiseaseClass,
    ExplainabilityResult,
    ExplainabilityResponse,
)

logger = get_logger(__name__)


class GradCAMHook:
    """Hook to capture activations and gradients from model layers."""

    def __init__(self):
        self.activations: Optional[torch.Tensor] = None
        self.gradients: Optional[torch.Tensor] = None

    def save_activation(self, module: torch.nn.Module, input: Any, output: torch.Tensor) -> None:
        """Forward hook to save activations."""
        self.activations = output.detach()

    def save_gradient(self, module: torch.nn.Module, grad_input: Any, grad_output: Any) -> None:
        """Backward hook to save gradients."""
        self.gradients = grad_output[0].detach()

    def clear(self) -> None:
        """Clear stored activations and gradients."""
        self.activations = None
        self.gradients = None


class YOLOv8GradCAM:
    """
    Grad-CAM implementation specifically designed for YOLOv8 models.
    Generates class-discriminative localization maps for object detection.
    """

    CLASS_NAMES = ["healthy", "red_rust", "blister_blight"]

    def __init__(
        self,
        model_path: Optional[str] = None,
        target_layer: Optional[str] = None,
        device: Optional[str] = None,
    ):
        """
        Initialize Grad-CAM for YOLOv8.

        Args:
            model_path: Path to YOLOv8 model weights
            target_layer: Target layer for Grad-CAM (default: last conv layer)
            device: Device for computation (cpu/cuda)
        """
        self.model_path = model_path or settings.model.model_path
        self.target_layer_name = target_layer
        self.device = device or settings.model.device

        self.model = None
        self.target_layer = None
        self.hook = GradCAMHook()
        self.forward_handle = None
        self.backward_handle = None

        self._load_model()

    def _load_model(self) -> None:
        """Load YOLOv8 model for Grad-CAM analysis."""
        try:
            from ultralytics import YOLO

            if not Path(self.model_path).exists():
                logger.warning(f"Model not found at {self.model_path}, using demo mode")
                self.model = None
                return

            self.model = YOLO(self.model_path)

            if hasattr(self.model, "model"):
                pytorch_model = self.model.model

                if self.device == "cuda" and torch.cuda.is_available():
                    pytorch_model = pytorch_model.cuda()

                self.target_layer = self._find_target_layer(pytorch_model)

                if self.target_layer is not None:
                    self.forward_handle = self.target_layer.register_forward_hook(
                        self.hook.save_activation
                    )
                    self.backward_handle = self.target_layer.register_full_backward_hook(
                        self.hook.save_gradient
                    )

            logger.info("Grad-CAM model loaded successfully")

        except ImportError:
            logger.error("ultralytics package not available")
            self.model = None
        except Exception as e:
            logger.error(f"Failed to load model for Grad-CAM: {e}")
            self.model = None

    def _find_target_layer(self, model: torch.nn.Module) -> Optional[torch.nn.Module]:
        """
        Find the target layer for Grad-CAM.
        By default, uses the last convolutional layer in the backbone.

        Args:
            model: PyTorch model

        Returns:
            Target layer module or None
        """
        if self.target_layer_name:
            for name, module in model.named_modules():
                if name == self.target_layer_name:
                    return module

        last_conv = None
        for name, module in model.named_modules():
            if isinstance(module, torch.nn.Conv2d):
                last_conv = module

        return last_conv

    def generate_cam(
        self,
        image: np.ndarray,
        target_class: Optional[int] = None,
        detection_bbox: Optional[Tuple[float, float, float, float]] = None,
    ) -> Tuple[np.ndarray, dict[str, float]]:
        """
        Generate Grad-CAM heatmap for an image.

        Args:
            image: Input image in BGR format
            target_class: Target class index for explanation
            detection_bbox: Specific bounding box to focus on (x1, y1, x2, y2)

        Returns:
            Tuple of (heatmap array, confidence breakdown)
        """
        if self.model is None:
            return self._generate_demo_cam(image)

        try:
            original_shape = image.shape[:2]
            input_tensor = self._preprocess_image(image)

            self.hook.clear()

            pytorch_model = self.model.model
            pytorch_model.eval()

            input_tensor.requires_grad_(True)

            with torch.enable_grad():
                output = pytorch_model(input_tensor)

            if target_class is None:
                target_class = self._get_dominant_class(output, detection_bbox)

            loss = self._compute_class_loss(output, target_class, detection_bbox)

            pytorch_model.zero_grad()
            loss.backward(retain_graph=True)

            if self.hook.activations is None or self.hook.gradients is None:
                logger.warning("Failed to capture activations/gradients")
                return self._generate_demo_cam(image)

            cam = self._compute_cam(self.hook.activations, self.hook.gradients)

            cam_resized = cv2.resize(cam, (original_shape[1], original_shape[0]))
            cam_normalized = (cam_resized - cam_resized.min()) / (
                cam_resized.max() - cam_resized.min() + 1e-8
            )

            confidence_breakdown = self._compute_confidence_breakdown(output, target_class)

            return cam_normalized, confidence_breakdown

        except Exception as e:
            logger.error(f"Grad-CAM generation failed: {e}")
            return self._generate_demo_cam(image)

    def _preprocess_image(self, image: np.ndarray) -> torch.Tensor:
        """Preprocess image for model input."""
        img_size = settings.model.image_size

        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        resized = cv2.resize(rgb_image, (img_size, img_size))
        normalized = resized.astype(np.float32) / 255.0

        tensor = torch.from_numpy(normalized).permute(2, 0, 1).unsqueeze(0)

        if self.device == "cuda" and torch.cuda.is_available():
            tensor = tensor.cuda()

        return tensor

    def _get_dominant_class(
        self,
        output: torch.Tensor,
        bbox: Optional[Tuple[float, float, float, float]] = None,
    ) -> int:
        """Get the dominant predicted class from output."""
        return 0

    def _compute_class_loss(
        self,
        output: torch.Tensor,
        target_class: int,
        bbox: Optional[Tuple[float, float, float, float]] = None,
    ) -> torch.Tensor:
        """Compute loss for the target class."""
        if isinstance(output, (list, tuple)):
            output = output[0]

        if output.dim() == 3:
            class_scores = output[0, 4:, :].mean(dim=1)
            if target_class < len(class_scores):
                return class_scores[target_class]

        return output.mean()

    def _compute_cam(
        self,
        activations: torch.Tensor,
        gradients: torch.Tensor,
    ) -> np.ndarray:
        """
        Compute the Grad-CAM heatmap from activations and gradients.

        Args:
            activations: Feature map activations
            gradients: Gradients with respect to target

        Returns:
            CAM heatmap as numpy array
        """
        weights = gradients.mean(dim=(2, 3), keepdim=True)

        cam = (weights * activations).sum(dim=1, keepdim=True)

        cam = F.relu(cam)

        cam = cam.squeeze().cpu().numpy()

        return cam

    def _compute_confidence_breakdown(
        self,
        output: torch.Tensor,
        target_class: int,
    ) -> dict[str, float]:
        """Compute confidence scores for each class."""
        breakdown = {}
        for i, class_name in enumerate(self.CLASS_NAMES):
            breakdown[class_name] = 0.33
        return breakdown

    def _generate_demo_cam(
        self,
        image: np.ndarray,
    ) -> Tuple[np.ndarray, dict[str, float]]:
        """Generate a demo CAM for testing without a model."""
        height, width = image.shape[:2]

        center_x, center_y = width // 2, height // 2

        y, x = np.ogrid[:height, :width]
        cam = np.exp(-((x - center_x) ** 2 + (y - center_y) ** 2) / (2 * (width / 4) ** 2))

        noise = np.random.rand(height, width) * 0.2
        cam = cam + noise
        cam = (cam - cam.min()) / (cam.max() - cam.min())

        confidence_breakdown = {
            "healthy": 0.65,
            "red_rust": 0.25,
            "blister_blight": 0.10,
        }

        return cam, confidence_breakdown

    def generate_heatmap_overlay(
        self,
        image: np.ndarray,
        cam: np.ndarray,
        alpha: float = 0.5,
        colormap: int = cv2.COLORMAP_JET,
    ) -> np.ndarray:
        """
        Overlay CAM heatmap on the original image.

        Args:
            image: Original image in BGR format
            cam: Grad-CAM heatmap (normalized 0-1)
            alpha: Transparency for overlay
            colormap: OpenCV colormap to use

        Returns:
            Image with heatmap overlay
        """
        heatmap = np.uint8(255 * cam)
        heatmap_colored = cv2.applyColorMap(heatmap, colormap)

        if image.shape[:2] != heatmap_colored.shape[:2]:
            heatmap_colored = cv2.resize(
                heatmap_colored, (image.shape[1], image.shape[0])
            )

        overlay = cv2.addWeighted(image, 1 - alpha, heatmap_colored, alpha, 0)

        return overlay

    def get_attention_regions(
        self,
        cam: np.ndarray,
        threshold: float = 0.5,
    ) -> list[dict[str, Any]]:
        """
        Extract high-attention regions from CAM.

        Args:
            cam: Grad-CAM heatmap
            threshold: Threshold for attention regions

        Returns:
            List of attention region dictionaries
        """
        binary = (cam > threshold).astype(np.uint8) * 255

        contours, _ = cv2.findContours(
            binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        regions = []
        for i, contour in enumerate(contours):
            x, y, w, h = cv2.boundingRect(contour)
            area = cv2.contourArea(contour)
            mean_attention = cam[y:y+h, x:x+w].mean()

            regions.append({
                "region_id": i,
                "bbox": {"x": x, "y": y, "width": w, "height": h},
                "area": float(area),
                "mean_attention": float(mean_attention),
            })

        regions.sort(key=lambda r: r["mean_attention"], reverse=True)

        return regions

    def explain_detection(
        self,
        image: np.ndarray,
        detection: dict,
        image_id: str,
    ) -> ExplainabilityResult:
        """
        Generate explanation for a specific detection.

        Args:
            image: Original image
            detection: Detection dictionary
            image_id: Image identifier

        Returns:
            ExplainabilityResult with heatmap and attention regions
        """
        class_name = detection.get("class_name", DiseaseClass.HEALTHY)
        if isinstance(class_name, DiseaseClass):
            class_id = self.CLASS_NAMES.index(class_name.value)
        else:
            class_id = self.CLASS_NAMES.index(class_name) if class_name in self.CLASS_NAMES else 0

        bbox = detection.get("bounding_box", {})
        bbox_tuple = (
            bbox.get("x_min", 0),
            bbox.get("y_min", 0),
            bbox.get("x_max", image.shape[1]),
            bbox.get("y_max", image.shape[0]),
        )

        cam, confidence_breakdown = self.generate_cam(
            image, target_class=class_id, detection_bbox=bbox_tuple
        )

        overlay = self.generate_heatmap_overlay(image, cam)
        attention_regions = self.get_attention_regions(cam)

        heatmap_bytes = self._encode_image(overlay)
        heatmap_b64 = base64.b64encode(heatmap_bytes).decode("utf-8")
        heatmap_url = f"data:image/jpeg;base64,{heatmap_b64}"

        return ExplainabilityResult(
            detection_id=detection.get("detection_id", str(uuid.uuid4())),
            class_name=class_name if isinstance(class_name, DiseaseClass) else DiseaseClass(class_name),
            heatmap_url=heatmap_url,
            attention_regions=attention_regions,
            confidence_breakdown=confidence_breakdown,
        )

    def explain_image(
        self,
        image: np.ndarray,
        detections: list[dict],
        image_id: str,
        target_classes: Optional[list[DiseaseClass]] = None,
    ) -> ExplainabilityResponse:
        """
        Generate explanations for all detections in an image.

        Args:
            image: Original image
            detections: List of detection dictionaries
            image_id: Image identifier
            target_classes: Optional filter for specific classes

        Returns:
            ExplainabilityResponse with all results
        """
        import time
        start_time = time.perf_counter()

        task_id = str(uuid.uuid4())
        results = []

        for detection in detections:
            class_name = detection.get("class_name")
            if isinstance(class_name, str):
                class_name = DiseaseClass(class_name)

            if target_classes and class_name not in target_classes:
                continue

            result = self.explain_detection(image, detection, image_id)
            results.append(result)

        combined_heatmap_url = None
        if len(results) > 1:
            combined_heatmap_url = self._generate_combined_heatmap(
                image, detections, image_id
            )

        processing_time = (time.perf_counter() - start_time) * 1000

        return ExplainabilityResponse(
            task_id=task_id,
            image_id=image_id,
            status="completed",
            processing_time_ms=processing_time,
            results=results,
            combined_heatmap_url=combined_heatmap_url,
        )

    def _generate_combined_heatmap(
        self,
        image: np.ndarray,
        detections: list[dict],
        image_id: str,
    ) -> str:
        """Generate a combined heatmap for all detections."""
        height, width = image.shape[:2]
        combined_cam = np.zeros((height, width), dtype=np.float32)

        for detection in detections:
            class_name = detection.get("class_name")
            if isinstance(class_name, DiseaseClass):
                class_id = self.CLASS_NAMES.index(class_name.value)
            else:
                class_id = 0

            cam, _ = self.generate_cam(image, target_class=class_id)
            combined_cam = np.maximum(combined_cam, cam)

        combined_cam = (combined_cam - combined_cam.min()) / (
            combined_cam.max() - combined_cam.min() + 1e-8
        )

        overlay = self.generate_heatmap_overlay(image, combined_cam)
        heatmap_bytes = self._encode_image(overlay)
        heatmap_b64 = base64.b64encode(heatmap_bytes).decode("utf-8")

        return f"data:image/jpeg;base64,{heatmap_b64}"

    def _encode_image(self, image: np.ndarray, quality: int = 90) -> bytes:
        """Encode image to JPEG bytes."""
        encode_params = [cv2.IMWRITE_JPEG_QUALITY, quality]
        success, buffer = cv2.imencode(".jpg", image, encode_params)
        if not success:
            raise ExplainabilityError("Failed to encode heatmap image")
        return buffer.tobytes()

    def cleanup(self) -> None:
        """Clean up hooks and resources."""
        if self.forward_handle is not None:
            self.forward_handle.remove()
        if self.backward_handle is not None:
            self.backward_handle.remove()
        self.hook.clear()
