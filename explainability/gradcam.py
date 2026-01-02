"""
Grad-CAM Explainability Module for Tea Leaf Disease Detection
==============================================================
Provides visual explanations for disease predictions by highlighting
the regions that influence model decisions.
"""

import cv2
import numpy as np
import torch
import torch.nn.functional as F
from typing import List, Dict, Tuple, Optional, Union
from dataclasses import dataclass
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class ExplanationResult:
    """Result of Grad-CAM explanation."""
    heatmap: np.ndarray
    overlay: np.ndarray
    class_id: int
    class_name: str
    confidence: float
    attention_score: float

    def to_dict(self) -> Dict:
        """Convert to dictionary (without images)."""
        return {
            'class_id': self.class_id,
            'class_name': self.class_name,
            'confidence': self.confidence,
            'attention_score': self.attention_score
        }


class GradCAM:
    """
    Gradient-weighted Class Activation Mapping for YOLOv8.
    Highlights regions influencing disease classification.
    """

    def __init__(
        self,
        model,
        target_layer: str = None,
        device: str = None
    ):
        """
        Initialize Grad-CAM.

        Args:
            model: YOLOv8 model (Ultralytics YOLO object)
            target_layer: Name of target layer for CAM
            device: Computation device
        """
        self.model = model
        self.device = device or ('cuda' if torch.cuda.is_available() else 'cpu')

        # Get backbone from YOLO model
        self.backbone = self._get_backbone()

        # Default target layer (last conv layer of backbone)
        if target_layer is None:
            self.target_layer = self._find_target_layer()
        else:
            self.target_layer = self._get_layer_by_name(target_layer)

        # Storage for gradients and activations
        self.gradients = None
        self.activations = None

        # Register hooks
        self._register_hooks()

        logger.info(f"GradCAM initialized with target layer: {self.target_layer}")

    def _get_backbone(self):
        """Extract backbone from YOLO model."""
        if hasattr(self.model, 'model'):
            return self.model.model
        return self.model

    def _find_target_layer(self):
        """Find the last convolutional layer in backbone."""
        target = None

        def find_conv(module, prefix=''):
            nonlocal target
            for name, layer in module.named_children():
                layer_name = f"{prefix}.{name}" if prefix else name
                if isinstance(layer, torch.nn.Conv2d):
                    target = layer
                find_conv(layer, layer_name)

        find_conv(self.backbone)
        return target

    def _get_layer_by_name(self, name: str):
        """Get layer by name."""
        parts = name.split('.')
        layer = self.backbone
        for part in parts:
            layer = getattr(layer, part)
        return layer

    def _register_hooks(self):
        """Register forward and backward hooks."""
        def forward_hook(module, input, output):
            self.activations = output.detach()

        def backward_hook(module, grad_input, grad_output):
            self.gradients = grad_output[0].detach()

        self.target_layer.register_forward_hook(forward_hook)
        self.target_layer.register_full_backward_hook(backward_hook)

    def generate(
        self,
        image: np.ndarray,
        detection_idx: int = 0,
        target_class: int = None
    ) -> ExplanationResult:
        """
        Generate Grad-CAM explanation for a detection.

        Args:
            image: Input image (BGR format)
            detection_idx: Index of detection to explain
            target_class: Target class (uses predicted class if None)

        Returns:
            ExplanationResult with heatmap and overlay
        """
        # Preprocess image
        input_tensor = self._preprocess(image)
        input_tensor.requires_grad_(True)

        # Forward pass
        self.backbone.eval()
        outputs = self.backbone(input_tensor)

        # Get detection output
        if isinstance(outputs, (list, tuple)):
            output = outputs[0]
        else:
            output = outputs

        # Determine target class
        if target_class is None:
            # Use argmax of class scores
            if len(output.shape) == 3:  # [batch, channels, features]
                class_scores = output[0, 5:, :]  # Skip x, y, w, h, obj
                class_id = class_scores.max(dim=0)[0].argmax().item()
                target_score = class_scores[class_id].max()
            else:
                class_id = 0
                target_score = output.max()
        else:
            class_id = target_class
            if len(output.shape) == 3:
                target_score = output[0, 5 + class_id, :].max()
            else:
                target_score = output.max()

        # Backward pass
        self.backbone.zero_grad()
        target_score.backward()

        # Generate CAM
        gradients = self.gradients
        activations = self.activations

        # Global average pooling of gradients
        weights = torch.mean(gradients, dim=(2, 3), keepdim=True)

        # Weighted combination of activation maps
        cam = torch.sum(weights * activations, dim=1, keepdim=True)

        # ReLU and normalize
        cam = F.relu(cam)
        cam = cam.squeeze().cpu().numpy()

        # Normalize to [0, 1]
        cam = (cam - cam.min()) / (cam.max() - cam.min() + 1e-8)

        # Resize to original image size
        h, w = image.shape[:2]
        heatmap = cv2.resize(cam, (w, h))

        # Create overlay
        overlay = self._create_overlay(image, heatmap)

        # Calculate attention score
        attention_score = float(np.mean(heatmap[heatmap > 0.5]))

        class_names = ["healthy", "red_rust", "blister_blight"]
        class_name = class_names[class_id] if class_id < len(class_names) else "unknown"

        return ExplanationResult(
            heatmap=heatmap,
            overlay=overlay,
            class_id=class_id,
            class_name=class_name,
            confidence=float(target_score.item()),
            attention_score=attention_score
        )

    def _preprocess(self, image: np.ndarray) -> torch.Tensor:
        """Preprocess image for model input."""
        # Resize
        resized = cv2.resize(image, (640, 640))

        # Convert BGR to RGB
        rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)

        # Normalize
        normalized = rgb.astype(np.float32) / 255.0

        # To tensor [C, H, W]
        tensor = torch.from_numpy(normalized).permute(2, 0, 1)

        # Add batch dimension
        tensor = tensor.unsqueeze(0).to(self.device)

        return tensor

    def _create_overlay(
        self,
        image: np.ndarray,
        heatmap: np.ndarray,
        alpha: float = 0.5,
        colormap: int = cv2.COLORMAP_JET
    ) -> np.ndarray:
        """
        Create heatmap overlay on original image.

        Args:
            image: Original image (BGR)
            heatmap: Normalized heatmap [0, 1]
            alpha: Blend factor
            colormap: OpenCV colormap

        Returns:
            Overlay image (BGR)
        """
        # Convert heatmap to colormap
        heatmap_uint8 = (heatmap * 255).astype(np.uint8)
        heatmap_colored = cv2.applyColorMap(heatmap_uint8, colormap)

        # Blend with original image
        overlay = cv2.addWeighted(image, 1 - alpha, heatmap_colored, alpha, 0)

        return overlay

    def generate_batch(
        self,
        image: np.ndarray,
        detections: List[Dict]
    ) -> List[ExplanationResult]:
        """
        Generate explanations for multiple detections.

        Args:
            image: Input image
            detections: List of detection dictionaries

        Returns:
            List of ExplanationResults
        """
        results = []
        for i, det in enumerate(detections):
            class_id = det.get('class_id', 0)
            result = self.generate(
                image,
                detection_idx=i,
                target_class=class_id
            )
            results.append(result)
        return results


class YOLOv8GradCAM(GradCAM):
    """
    Specialized Grad-CAM for YOLOv8 architecture.
    """

    def __init__(
        self,
        model_path: str,
        device: str = None
    ):
        """
        Initialize with YOLOv8 model.

        Args:
            model_path: Path to YOLOv8 weights
            device: Computation device
        """
        from ultralytics import YOLO

        self.yolo_model = YOLO(model_path)
        device = device or ('cuda' if torch.cuda.is_available() else 'cpu')

        # Access the underlying PyTorch model
        pytorch_model = self.yolo_model.model

        super().__init__(
            model=pytorch_model,
            device=device
        )

    def explain_detection(
        self,
        image: np.ndarray,
        bbox: Tuple[int, int, int, int],
        class_id: int
    ) -> ExplanationResult:
        """
        Generate explanation for a specific detection.

        Args:
            image: Input image
            bbox: Bounding box (x1, y1, x2, y2)
            class_id: Detected class

        Returns:
            ExplanationResult
        """
        # Crop region around detection
        x1, y1, x2, y2 = bbox
        padding = 50
        x1 = max(0, x1 - padding)
        y1 = max(0, y1 - padding)
        x2 = min(image.shape[1], x2 + padding)
        y2 = min(image.shape[0], y2 + padding)

        crop = image[y1:y2, x1:x2]

        # Generate CAM on crop
        result = self.generate(crop, target_class=class_id)

        # Resize heatmap back to original bbox size
        full_heatmap = np.zeros((image.shape[0], image.shape[1]), dtype=np.float32)
        full_heatmap[y1:y2, x1:x2] = result.heatmap

        # Create full overlay
        full_overlay = self._create_overlay(image, full_heatmap)

        return ExplanationResult(
            heatmap=full_heatmap,
            overlay=full_overlay,
            class_id=result.class_id,
            class_name=result.class_name,
            confidence=result.confidence,
            attention_score=result.attention_score
        )


class ExplainabilityService:
    """
    Service layer for generating explanations on demand.
    Designed to not impact inference speed for field users.
    """

    def __init__(
        self,
        model_path: str,
        cache_size: int = 100,
        device: str = None
    ):
        """
        Initialize explainability service.

        Args:
            model_path: Path to YOLOv8 model
            cache_size: Number of explanations to cache
            device: Computation device
        """
        self.model_path = model_path
        self.device = device
        self.cache_size = cache_size

        # Lazy loading - only initialize when needed
        self._gradcam = None
        self._cache = {}

    @property
    def gradcam(self) -> YOLOv8GradCAM:
        """Lazy-load GradCAM model."""
        if self._gradcam is None:
            logger.info("Initializing GradCAM model (lazy load)...")
            self._gradcam = YOLOv8GradCAM(
                model_path=self.model_path,
                device=self.device
            )
        return self._gradcam

    def explain(
        self,
        image: np.ndarray,
        detection: Dict,
        cache_key: str = None
    ) -> ExplanationResult:
        """
        Generate explanation for a detection.
        Uses caching to avoid recomputation.

        Args:
            image: Input image
            detection: Detection dictionary with bbox and class_id
            cache_key: Optional cache key

        Returns:
            ExplanationResult
        """
        # Check cache
        if cache_key and cache_key in self._cache:
            return self._cache[cache_key]

        # Generate explanation
        bbox = tuple(detection.get('bbox', [0, 0, 100, 100]))
        class_id = detection.get('class_id', 0)

        result = self.gradcam.explain_detection(image, bbox, class_id)

        # Cache result
        if cache_key:
            if len(self._cache) >= self.cache_size:
                # Remove oldest entry
                oldest_key = next(iter(self._cache))
                del self._cache[oldest_key]
            self._cache[cache_key] = result

        return result

    def batch_explain(
        self,
        image: np.ndarray,
        detections: List[Dict]
    ) -> List[ExplanationResult]:
        """
        Generate explanations for multiple detections.

        Args:
            image: Input image
            detections: List of detection dictionaries

        Returns:
            List of ExplanationResults
        """
        return [
            self.explain(image, det, cache_key=f"{id(image)}_{i}")
            for i, det in enumerate(detections)
        ]

    def save_explanation(
        self,
        result: ExplanationResult,
        output_path: str,
        include_heatmap: bool = True
    ) -> Dict[str, str]:
        """
        Save explanation images to disk.

        Args:
            result: Explanation result
            output_path: Base path for output files
            include_heatmap: Whether to save raw heatmap

        Returns:
            Dictionary of saved file paths
        """
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        saved_paths = {}

        # Save overlay
        overlay_path = output_path.with_suffix('.overlay.jpg')
        cv2.imwrite(str(overlay_path), result.overlay)
        saved_paths['overlay'] = str(overlay_path)

        # Save heatmap
        if include_heatmap:
            heatmap_uint8 = (result.heatmap * 255).astype(np.uint8)
            heatmap_colored = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
            heatmap_path = output_path.with_suffix('.heatmap.jpg')
            cv2.imwrite(str(heatmap_path), heatmap_colored)
            saved_paths['heatmap'] = str(heatmap_path)

        return saved_paths

    def clear_cache(self):
        """Clear explanation cache."""
        self._cache.clear()

    def unload(self):
        """Unload model to free memory."""
        self._gradcam = None
        self._cache.clear()
        logger.info("GradCAM model unloaded")


def generate_explanation_report(
    image: np.ndarray,
    detections: List[Dict],
    explanations: List[ExplanationResult],
    output_path: str
) -> str:
    """
    Generate comprehensive explanation report.

    Args:
        image: Original image
        detections: List of detections
        explanations: List of explanations
        output_path: Output file path

    Returns:
        Path to generated report
    """
    # Create composite visualization
    h, w = image.shape[:2]
    report_width = w * 2
    report_height = h * (1 + len(detections))

    report = np.zeros((report_height, report_width, 3), dtype=np.uint8)

    # Original image
    report[:h, :w] = image

    # Add explanations
    for i, (det, exp) in enumerate(zip(detections, explanations)):
        y_offset = h * (i + 1)

        # Overlay
        report[y_offset:y_offset + h, :w] = exp.overlay

        # Detection info
        x1, y1, x2, y2 = det.get('bbox', [0, 0, 100, 100])
        cv2.rectangle(report, (x1, y_offset + y1), (x2, y_offset + y2), (0, 255, 0), 2)

        # Text info
        info_x = w + 20
        info_y = y_offset + 50
        cv2.putText(
            report,
            f"Class: {exp.class_name}",
            (info_x, info_y),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (255, 255, 255),
            2
        )
        cv2.putText(
            report,
            f"Confidence: {exp.confidence:.2f}",
            (info_x, info_y + 40),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (255, 255, 255),
            2
        )
        cv2.putText(
            report,
            f"Attention: {exp.attention_score:.2f}",
            (info_x, info_y + 80),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            (255, 255, 255),
            2
        )

    # Save report
    cv2.imwrite(output_path, report)
    return output_path
