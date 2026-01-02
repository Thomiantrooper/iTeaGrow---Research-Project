"""
Tea Leaf Disease Detector
==========================
Main inference engine supporting multiple backends (PyTorch, ONNX, TFLite).
"""

import os
import cv2
import numpy as np
import time
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Union
from dataclasses import dataclass
from enum import Enum
import logging

from .preprocessor import ImagePreprocessor, QualityReport

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class InferenceBackend(Enum):
    """Supported inference backends."""
    PYTORCH = "pytorch"
    ONNX = "onnx"
    TFLITE = "tflite"
    COREML = "coreml"


@dataclass
class Detection:
    """Single detection result."""
    bbox: Tuple[int, int, int, int]  # x1, y1, x2, y2
    confidence: float
    class_id: int
    class_name: str


@dataclass
class DetectionResult:
    """Complete detection result for an image."""
    detections: List[Detection]
    inference_time_ms: float
    image_quality: Optional[QualityReport]
    image_size: Tuple[int, int]
    model_version: str

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization."""
        return {
            'detections': [
                {
                    'bbox': list(d.bbox),
                    'confidence': d.confidence,
                    'class_id': d.class_id,
                    'class_name': d.class_name
                }
                for d in self.detections
            ],
            'inference_time_ms': self.inference_time_ms,
            'image_quality': self.image_quality.quality.value if self.image_quality else None,
            'image_size': list(self.image_size),
            'model_version': self.model_version,
            'disease_summary': self.get_disease_summary()
        }

    def get_disease_summary(self) -> Dict:
        """Get summary of detected diseases."""
        summary = {
            'healthy': 0,
            'red_rust': 0,
            'blister_blight': 0,
            'total': len(self.detections)
        }
        for det in self.detections:
            if det.class_name in summary:
                summary[det.class_name] += 1
        return summary


class TeaLeafDetector:
    """
    Multi-backend detector for tea leaf diseases.
    Supports PyTorch, ONNX, and TFLite models for flexible deployment.
    """

    CLASS_NAMES = ["healthy", "red_rust", "blister_blight"]

    def __init__(
        self,
        model_path: str,
        backend: InferenceBackend = None,
        confidence_threshold: float = 0.5,
        iou_threshold: float = 0.45,
        device: str = "cpu",
        enable_quality_check: bool = True
    ):
        """
        Initialize detector.

        Args:
            model_path: Path to model file
            backend: Inference backend (auto-detected if None)
            confidence_threshold: Minimum detection confidence
            iou_threshold: NMS IoU threshold
            device: Inference device ('cpu', 'cuda', 'cuda:0')
            enable_quality_check: Whether to validate image quality
        """
        self.model_path = Path(model_path)
        self.confidence_threshold = confidence_threshold
        self.iou_threshold = iou_threshold
        self.device = device
        self.enable_quality_check = enable_quality_check

        # Auto-detect backend
        if backend is None:
            backend = self._detect_backend()
        self.backend = backend

        # Initialize preprocessor
        self.preprocessor = ImagePreprocessor(target_size=(640, 640))

        # Load model
        self.model = None
        self.model_version = "1.0.0"
        self._load_model()

        logger.info(f"Detector initialized with {backend.value} backend")

    def _detect_backend(self) -> InferenceBackend:
        """Detect backend from model file extension."""
        suffix = self.model_path.suffix.lower()
        if suffix == '.pt' or suffix == '.pth':
            return InferenceBackend.PYTORCH
        elif suffix == '.onnx':
            return InferenceBackend.ONNX
        elif suffix == '.tflite':
            return InferenceBackend.TFLITE
        elif suffix == '.mlmodel':
            return InferenceBackend.COREML
        else:
            raise ValueError(f"Unknown model format: {suffix}")

    def _load_model(self):
        """Load model based on backend."""
        if self.backend == InferenceBackend.PYTORCH:
            self._load_pytorch_model()
        elif self.backend == InferenceBackend.ONNX:
            self._load_onnx_model()
        elif self.backend == InferenceBackend.TFLITE:
            self._load_tflite_model()
        else:
            raise ValueError(f"Unsupported backend: {self.backend}")

    def _load_pytorch_model(self):
        """Load PyTorch/Ultralytics model."""
        try:
            from ultralytics import YOLO
            self.model = YOLO(str(self.model_path))
            if 'cuda' in self.device:
                import torch
                if torch.cuda.is_available():
                    self.model.to(self.device)
            logger.info("PyTorch model loaded successfully")
        except ImportError:
            raise ImportError("ultralytics package required for PyTorch inference")

    def _load_onnx_model(self):
        """Load ONNX model."""
        try:
            import onnxruntime as ort

            # Configure session options
            sess_options = ort.SessionOptions()
            sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

            # Select providers
            if 'cuda' in self.device and 'CUDAExecutionProvider' in ort.get_available_providers():
                providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']
            else:
                providers = ['CPUExecutionProvider']

            self.model = ort.InferenceSession(
                str(self.model_path),
                sess_options=sess_options,
                providers=providers
            )

            self.input_name = self.model.get_inputs()[0].name
            self.output_names = [o.name for o in self.model.get_outputs()]

            logger.info(f"ONNX model loaded with providers: {providers}")
        except ImportError:
            raise ImportError("onnxruntime package required for ONNX inference")

    def _load_tflite_model(self):
        """Load TFLite model."""
        try:
            import tensorflow as tf

            self.model = tf.lite.Interpreter(model_path=str(self.model_path))
            self.model.allocate_tensors()

            self.input_details = self.model.get_input_details()
            self.output_details = self.model.get_output_details()

            logger.info("TFLite model loaded successfully")
        except ImportError:
            raise ImportError("tensorflow package required for TFLite inference")

    def detect(
        self,
        image: Union[str, np.ndarray],
        validate_quality: bool = None
    ) -> DetectionResult:
        """
        Detect diseases in tea leaf image.

        Args:
            image: Image path or numpy array (BGR format)
            validate_quality: Override quality check setting

        Returns:
            DetectionResult with all detections
        """
        if validate_quality is None:
            validate_quality = self.enable_quality_check

        # Load image if path provided
        if isinstance(image, str):
            image = cv2.imread(image)
            if image is None:
                raise ValueError(f"Failed to load image: {image}")

        original_size = image.shape[:2]  # (height, width)

        # Preprocess
        try:
            preprocessed, quality_report = self.preprocessor.preprocess(
                image,
                validate_quality=validate_quality,
                enhance=True
            )
        except ValueError as e:
            return DetectionResult(
                detections=[],
                inference_time_ms=0,
                image_quality=None,
                image_size=original_size,
                model_version=self.model_version
            )

        # Run inference
        start_time = time.time()
        raw_output = self._run_inference(preprocessed)
        inference_time = (time.time() - start_time) * 1000

        # Post-process
        detections = self._postprocess(raw_output, original_size)

        return DetectionResult(
            detections=detections,
            inference_time_ms=inference_time,
            image_quality=quality_report,
            image_size=original_size,
            model_version=self.model_version
        )

    def _run_inference(self, image: np.ndarray) -> np.ndarray:
        """Run inference on preprocessed image."""
        if self.backend == InferenceBackend.PYTORCH:
            return self._infer_pytorch(image)
        elif self.backend == InferenceBackend.ONNX:
            return self._infer_onnx(image)
        elif self.backend == InferenceBackend.TFLITE:
            return self._infer_tflite(image)

    def _infer_pytorch(self, image: np.ndarray) -> np.ndarray:
        """PyTorch inference."""
        import torch

        # Convert to tensor
        with torch.no_grad():
            results = self.model.predict(
                image,
                conf=self.confidence_threshold,
                iou=self.iou_threshold,
                verbose=False
            )

        # Extract detections
        if len(results) > 0 and results[0].boxes is not None:
            boxes = results[0].boxes
            return np.concatenate([
                boxes.xyxy.cpu().numpy(),
                boxes.conf.cpu().numpy().reshape(-1, 1),
                boxes.cls.cpu().numpy().reshape(-1, 1)
            ], axis=1)

        return np.array([])

    def _infer_onnx(self, image: np.ndarray) -> np.ndarray:
        """ONNX inference."""
        # Run model
        outputs = self.model.run(
            self.output_names,
            {self.input_name: image.astype(np.float32)}
        )

        # Process output (YOLO format: [batch, num_boxes, 5+num_classes])
        predictions = outputs[0]

        if predictions.shape[-1] >= 8:  # x, y, w, h, conf, class_scores...
            return self._process_yolo_output(predictions[0])

        return np.array([])

    def _infer_tflite(self, image: np.ndarray) -> np.ndarray:
        """TFLite inference."""
        # Set input
        input_data = image.astype(np.float32)
        self.model.set_tensor(self.input_details[0]['index'], input_data)

        # Run inference
        self.model.invoke()

        # Get output
        output_data = self.model.get_tensor(self.output_details[0]['index'])

        return self._process_yolo_output(output_data[0])

    def _process_yolo_output(
        self,
        output: np.ndarray
    ) -> np.ndarray:
        """
        Process YOLO model output to detection format.

        Args:
            output: Raw model output [num_boxes, 5+num_classes]

        Returns:
            Array of [x1, y1, x2, y2, confidence, class_id]
        """
        # Output format: [x, y, w, h, obj_conf, class1_conf, class2_conf, ...]
        boxes = output[:, :4]
        obj_conf = output[:, 4]
        class_probs = output[:, 5:]

        # Get class with highest probability
        class_ids = np.argmax(class_probs, axis=1)
        class_conf = np.max(class_probs, axis=1)

        # Combined confidence
        confidences = obj_conf * class_conf

        # Filter by confidence
        mask = confidences > self.confidence_threshold
        boxes = boxes[mask]
        confidences = confidences[mask]
        class_ids = class_ids[mask]

        if len(boxes) == 0:
            return np.array([])

        # Convert xywh to xyxy
        x, y, w, h = boxes[:, 0], boxes[:, 1], boxes[:, 2], boxes[:, 3]
        x1 = x - w / 2
        y1 = y - h / 2
        x2 = x + w / 2
        y2 = y + h / 2

        boxes_xyxy = np.stack([x1, y1, x2, y2], axis=1)

        # Apply NMS
        indices = self._nms(boxes_xyxy, confidences, self.iou_threshold)

        # Format output
        result = np.concatenate([
            boxes_xyxy[indices],
            confidences[indices].reshape(-1, 1),
            class_ids[indices].reshape(-1, 1)
        ], axis=1)

        return result

    def _nms(
        self,
        boxes: np.ndarray,
        scores: np.ndarray,
        iou_threshold: float
    ) -> List[int]:
        """Non-maximum suppression."""
        x1 = boxes[:, 0]
        y1 = boxes[:, 1]
        x2 = boxes[:, 2]
        y2 = boxes[:, 3]

        areas = (x2 - x1) * (y2 - y1)
        order = scores.argsort()[::-1]

        keep = []
        while order.size > 0:
            i = order[0]
            keep.append(i)

            xx1 = np.maximum(x1[i], x1[order[1:]])
            yy1 = np.maximum(y1[i], y1[order[1:]])
            xx2 = np.minimum(x2[i], x2[order[1:]])
            yy2 = np.minimum(y2[i], y2[order[1:]])

            w = np.maximum(0.0, xx2 - xx1)
            h = np.maximum(0.0, yy2 - yy1)

            inter = w * h
            iou = inter / (areas[i] + areas[order[1:]] - inter)

            inds = np.where(iou <= iou_threshold)[0]
            order = order[inds + 1]

        return keep

    def _postprocess(
        self,
        raw_output: np.ndarray,
        original_size: Tuple[int, int]
    ) -> List[Detection]:
        """
        Convert raw output to Detection objects with original coordinates.

        Args:
            raw_output: Model output [N, 6] (x1, y1, x2, y2, conf, class)
            original_size: Original image size (height, width)

        Returns:
            List of Detection objects
        """
        if len(raw_output) == 0:
            return []

        detections = []
        orig_h, orig_w = original_size

        # Scale factor from 640 to original
        scale = max(orig_h, orig_w) / 640
        pad_w = (640 - orig_w / scale) / 2
        pad_h = (640 - orig_h / scale) / 2

        for det in raw_output:
            x1, y1, x2, y2, conf, class_id = det

            # Scale back to original size
            x1 = int((x1 - pad_w) * scale)
            y1 = int((y1 - pad_h) * scale)
            x2 = int((x2 - pad_w) * scale)
            y2 = int((y2 - pad_h) * scale)

            # Clip to image bounds
            x1 = max(0, min(x1, orig_w))
            y1 = max(0, min(y1, orig_h))
            x2 = max(0, min(x2, orig_w))
            y2 = max(0, min(y2, orig_h))

            class_id = int(class_id)
            class_name = self.CLASS_NAMES[class_id] if class_id < len(self.CLASS_NAMES) else "unknown"

            detections.append(Detection(
                bbox=(x1, y1, x2, y2),
                confidence=float(conf),
                class_id=class_id,
                class_name=class_name
            ))

        return detections

    def draw_detections(
        self,
        image: np.ndarray,
        result: DetectionResult,
        show_confidence: bool = True
    ) -> np.ndarray:
        """
        Draw detection boxes on image.

        Args:
            image: Input image (BGR)
            result: Detection result
            show_confidence: Whether to show confidence scores

        Returns:
            Image with drawn detections
        """
        output = image.copy()

        # Color mapping
        colors = {
            'healthy': (0, 255, 0),       # Green
            'red_rust': (0, 0, 255),      # Red
            'blister_blight': (255, 0, 0)  # Blue
        }

        for det in result.detections:
            x1, y1, x2, y2 = det.bbox
            color = colors.get(det.class_name, (128, 128, 128))

            # Draw box
            cv2.rectangle(output, (x1, y1), (x2, y2), color, 2)

            # Draw label
            label = det.class_name
            if show_confidence:
                label += f" {det.confidence:.2f}"

            # Label background
            (label_w, label_h), _ = cv2.getTextSize(
                label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1
            )
            cv2.rectangle(
                output,
                (x1, y1 - label_h - 10),
                (x1 + label_w + 10, y1),
                color,
                -1
            )

            # Label text
            cv2.putText(
                output,
                label,
                (x1 + 5, y1 - 5),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (255, 255, 255),
                1
            )

        return output

    def benchmark(
        self,
        image: np.ndarray,
        num_runs: int = 100,
        warmup: int = 10
    ) -> Dict:
        """
        Benchmark inference performance.

        Args:
            image: Test image
            num_runs: Number of inference runs
            warmup: Number of warmup runs

        Returns:
            Performance metrics dictionary
        """
        # Warmup
        for _ in range(warmup):
            self.detect(image, validate_quality=False)

        # Benchmark
        times = []
        for _ in range(num_runs):
            result = self.detect(image, validate_quality=False)
            times.append(result.inference_time_ms)

        return {
            'mean_ms': np.mean(times),
            'std_ms': np.std(times),
            'min_ms': np.min(times),
            'max_ms': np.max(times),
            'fps': 1000 / np.mean(times),
            'num_runs': num_runs
        }


def create_detector(
    model_path: str,
    backend: str = None,
    confidence: float = 0.5
) -> TeaLeafDetector:
    """
    Factory function to create detector.

    Args:
        model_path: Path to model file
        backend: Backend name ('pytorch', 'onnx', 'tflite')
        confidence: Confidence threshold

    Returns:
        Configured TeaLeafDetector instance
    """
    if backend:
        backend = InferenceBackend(backend)

    return TeaLeafDetector(
        model_path=model_path,
        backend=backend,
        confidence_threshold=confidence
    )
