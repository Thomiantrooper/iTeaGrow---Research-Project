"""
Smart Tea Leaf Disease Detection AI Engine
==========================================
YOLOv8n-based detection system for Red Rust and Blister Blight diseases.
"""

__version__ = "1.0.0"
__author__ = "Tea Disease Detection System"

from .inference.detector import TeaLeafDetector
from .inference.preprocessor import ImagePreprocessor

__all__ = ["TeaLeafDetector", "ImagePreprocessor"]
