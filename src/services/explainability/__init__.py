"""Explainability service for visual explanation of model predictions."""

from src.services.explainability.gradcam import YOLOv8GradCAM

__all__ = ["YOLOv8GradCAM"]
