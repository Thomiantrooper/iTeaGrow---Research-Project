"""
Inference Router - Disease Detection using YOLOv8 trained model.
Production-grade with robust validation, quality checks, and tea leaf verification.
"""
from fastapi import APIRouter, HTTPException, status, UploadFile, File, Form
from fastapi.responses import JSONResponse
from typing import Optional, List
from datetime import datetime
import uuid
import time
import numpy as np
import cv2
from pathlib import Path
import os
import logging

logger = logging.getLogger("inference")

router = APIRouter(prefix="/api/v1/inference", tags=["inference"])

# ============================================================================
# MODEL CONFIGURATION
# ============================================================================
# Primary model path: models/best.pt (relative to project root)
_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_PATH = os.path.join(_PROJECT_ROOT, "models", "best.pt")

# Fallback paths in case model is elsewhere
_FALLBACK_PATHS = [
    os.path.join(_PROJECT_ROOT, "runs", "detect", "runs", "detect", "max_accuracy", "tealeaf_95", "weights", "best.pt"),
    os.path.join(_PROJECT_ROOT, "runs", "detect", "tea_leaf_gpu", "weights", "best.pt"),
]

# Class names for tea leaf disease detection (matching trained model)
# Model has: {0: 'blister_blight', 1: 'healthy', 2: 'red_rust'}
CLASS_NAMES = ["blister_blight", "healthy", "red_rust"]

# ============================================================================
# VALIDATION CONSTANTS
# ============================================================================
MAX_IMAGE_SIZE_BYTES = 20 * 1024 * 1024  # 20 MB max upload
MIN_IMAGE_SIZE_BYTES = 5 * 1024           # 5 KB min (reject empty/corrupt)
MIN_IMAGE_DIMENSION = 64                  # Min width/height in pixels
MAX_IMAGE_DIMENSION = 8192                # Max width/height in pixels
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/bmp", "image/tiff"}
MIN_GREEN_RATIO_TEA_LEAF = 0.10           # Min green pixel ratio for tea leaf
BLUR_THRESHOLD = 50.0                     # Laplacian variance below this = blurry
MIN_CONFIDENCE_VALID = 0.30               # Min confidence to consider a detection valid
MIN_CONFIDENCE_RELIABLE = 0.50            # Min confidence for reliable detection

# Global model instance
_model = None
_model_loaded = False


def _resolve_model_path() -> str:
    """Find the best available model file path."""
    if Path(MODEL_PATH).exists():
        return MODEL_PATH
    for fallback in _FALLBACK_PATHS:
        if Path(fallback).exists():
            logger.info(f"Using fallback model path: {fallback}")
            return fallback
    return MODEL_PATH  # Return primary even if missing, let get_model() handle error


def get_model():
    """Load and cache the YOLO model."""
    global _model, _model_loaded

    if _model_loaded:
        return _model

    resolved_path = _resolve_model_path()

    try:
        from ultralytics import YOLO

        if not Path(resolved_path).exists():
            logger.error(f"Model not found at: {resolved_path}")
            logger.error(f"Also checked fallbacks: {_FALLBACK_PATHS}")
            _model = None
            _model_loaded = True
            return None

        logger.info(f"Loading YOLOv8 model from: {resolved_path}")
        _model = YOLO(resolved_path)
        _model_loaded = True
        logger.info(f"Model loaded successfully from: {resolved_path}")
        return _model
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        _model = None
        _model_loaded = True
        return None


# ==========================================================================
# IMAGE VALIDATION & QUALITY ASSESSMENT
# ==========================================================================

def validate_image_upload(image: UploadFile, image_bytes: bytes) -> dict:
    """
    Comprehensive image upload validation.
    Returns a dict with 'valid', 'issues', and 'warnings' keys.
    Raises HTTPException for hard failures.
    """
    issues = []
    warnings = []

    # 1. Check file size
    size = len(image_bytes)
    if size < MIN_IMAGE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Image too small ({size} bytes). Minimum is {MIN_IMAGE_SIZE_BYTES} bytes. The file may be corrupt."
        )
    if size > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Image too large ({size / 1024 / 1024:.1f} MB). Maximum is {MAX_IMAGE_SIZE_BYTES / 1024 / 1024:.0f} MB."
        )

    # 2. Check content type
    if image.content_type and image.content_type not in ALLOWED_CONTENT_TYPES:
        warnings.append(f"Unusual content type: {image.content_type}. Expected JPEG, PNG, or WebP.")

    # 3. Decode and check image validity
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot decode image. Please upload a valid JPEG, PNG, or WebP image."
        )

    # 4. Check dimensions
    h, w = img.shape[:2]
    if h < MIN_IMAGE_DIMENSION or w < MIN_IMAGE_DIMENSION:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Image too small ({w}x{h}). Minimum dimension is {MIN_IMAGE_DIMENSION}px."
        )
    if h > MAX_IMAGE_DIMENSION or w > MAX_IMAGE_DIMENSION:
        warnings.append(f"Very large image ({w}x{h}). Will be resized for inference.")

    return {"valid": True, "issues": issues, "warnings": warnings, "image": img}


def assess_image_quality(img: np.ndarray) -> dict:
    """
    Assess image quality with real scoring (not hardcoded).
    Returns quality metrics dict.
    """
    issues = []
    scores = []

    h, w = img.shape[:2]

    # 1. Blur detection (Laplacian variance)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if laplacian_var < BLUR_THRESHOLD:
        issues.append(f"Image appears blurry (sharpness: {laplacian_var:.1f}, threshold: {BLUR_THRESHOLD})")
        blur_score = max(0.0, laplacian_var / BLUR_THRESHOLD)
    else:
        blur_score = min(1.0, laplacian_var / (BLUR_THRESHOLD * 4))
    scores.append(blur_score)

    # 2. Brightness check
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    brightness = np.mean(hsv[:, :, 2])
    if brightness < 40:
        issues.append(f"Image is too dark (brightness: {brightness:.0f}/255)")
        brightness_score = brightness / 40 * 0.5
    elif brightness > 240:
        issues.append(f"Image is overexposed (brightness: {brightness:.0f}/255)")
        brightness_score = max(0.3, 1.0 - (brightness - 240) / 15)
    else:
        brightness_score = 1.0 - abs(brightness - 140) / 200
    scores.append(max(0.0, brightness_score))

    # 3. Contrast check
    contrast = np.std(gray)
    if contrast < 20:
        issues.append("Very low contrast - image may be washed out")
        contrast_score = contrast / 20 * 0.5
    else:
        contrast_score = min(1.0, contrast / 60)
    scores.append(contrast_score)

    # 4. Resolution adequacy
    min_dim = min(h, w)
    if min_dim >= 640:
        resolution_score = 1.0
    elif min_dim >= 320:
        resolution_score = 0.7
    elif min_dim >= 128:
        resolution_score = 0.4
        issues.append("Low resolution may affect detection accuracy")
    else:
        resolution_score = 0.2
        issues.append("Very low resolution - results may be unreliable")
    scores.append(resolution_score)

    overall = sum(scores) / len(scores)
    is_acceptable = overall >= 0.35 and len([s for s in scores if s < 0.2]) == 0

    return {
        "overall_score": round(float(overall), 3),
        "is_acceptable": is_acceptable,
        "sharpness": round(float(laplacian_var), 1),
        "brightness": round(float(brightness), 1),
        "contrast": round(float(contrast), 1),
        "resolution": f"{w}x{h}",
        "issues": issues,
    }


def is_tea_leaf_image(img: np.ndarray, detections: list) -> bool:
    """
    Determine if the image contains a valid tea leaf using multi-signal validation.
    Returns True if at least one strong signal indicates a tea leaf.
    """
    # Signal 1: Model detected leaf-related classes with sufficient confidence
    if detections:
        reliable_detections = [d for d in detections if d.get("confidence", 0) >= MIN_CONFIDENCE_RELIABLE]
        if reliable_detections:
            return True
        # Even weaker detections + green content = likely valid
        weak_detections = [d for d in detections if d.get("confidence", 0) >= MIN_CONFIDENCE_VALID]
        if weak_detections:
            # Require green content as secondary confirmation
            hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
            green_mask = cv2.inRange(hsv, np.array([35, 30, 30]), np.array([85, 255, 255]))
            green_ratio = np.count_nonzero(green_mask) / (img.shape[0] * img.shape[1])
            if green_ratio >= MIN_GREEN_RATIO_TEA_LEAF:
                return True

    # Signal 2: Strong green content alone (even without model detections)
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    green_mask = cv2.inRange(hsv, np.array([35, 40, 40]), np.array([85, 255, 255]))
    green_ratio = np.count_nonzero(green_mask) / (img.shape[0] * img.shape[1])

    # Very high green but no detections = might be grass/forest, not tea leaf
    if green_ratio >= 0.25 and detections:
        return True

    return False


def refine_detections(img: np.ndarray, detections: list, quality: dict) -> list:
    """
    Refine detections to reduce false positives from reflections, overexposure, and noise.
    Especially useful for 'Blister Blight' which often triggers on white reflections.
    """
    if not detections:
        return []

    refined = []
    h, w = img.shape[:2]
    brightness = quality.get("brightness", 128)

    for det in detections:
        name = det["class_name"]
        conf = det["confidence"]
        box = det["bounding_box"]

        # Only refine disease classes
        if name == "healthy":
            refined.append(det)
            continue

        # Strategy 1: Specular Reflection Filter (Common for 'Blister Blight')
        # If image is very bright and detection is at a white peak, it might be a reflection
        if name == "blister_blight" and brightness > 180:
            # Crop the box area to check colors
            x1, y1 = int(box["x_min"]), int(box["y_min"])
            x2, y2 = int(box["x_max"]), int(box["y_max"])
            # Ensure within bounds
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)

            if x2 > x1 and y2 > y1:
                roi = img[y1:y2, x1:x2]
                avg_val = np.mean(roi)
                
                # Check for Specular Highlights using HSV Value channel
                roi_hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)
                v_channel = roi_hsv[:, :, 2]
                peak_pixels = np.count_nonzero(v_channel > 245)
                peak_ratio = peak_pixels / (roi.shape[0] * roi.shape[1]) if roi.size > 0 else 0

                # If area is nearly pure white or has large peak-white clusters, it's likely a reflection
                if avg_val > 235 or peak_ratio > 0.3:
                    penalty = 0.5 if peak_ratio > 0.5 else 0.7
                    det["confidence"] *= penalty
                    det["validation_note"] = "Suppressed: Specular reflection / glare detected"
                    det["is_potential_fp"] = True

        # Strategy 2: Small Isolation Filter (skepticism for single spots in perfect leaves)
        # If model is mostly seeing 'Healthy' elsewhere, be harder on tiny diseased spots
        healthy_count = sum(1 for d in detections if d["class_name"] == "healthy")
        if name != "healthy" and healthy_count > 2 and det["area_percentage"] < 0.3:
            det["confidence"] *= 0.85
            det["is_isolated_spot"] = True

        refined.append(det)

    return refined


def get_severity(confidence: float, disease_name: str) -> str:
    """
    Determine severity based on confidence and disease type.
    PRODUCTION-GRADE: Stricter thresholds for real-world accuracy.
    """
    if disease_name.lower() == "healthy":
        return "None"

    # Stricter thresholds for production use
    if confidence >= 0.80:  # Increased from 0.85 to 0.80
        return "Critical" if confidence >= 0.90 else "High"
    elif confidence >= 0.65:  # Increased from 0.6 to 0.65
        return "Medium"
    elif confidence >= 0.45:  # New tier for low confidence
        return "Low"
    else:
        return "Uncertain"  # Below 0.45 is too uncertain for action


def get_recommendations(disease_name: str, severity: str) -> List[str]:
    """Generate recommendations based on disease and severity."""
    recommendations = {
        "healthy": [
            "Continue regular monitoring of tea plantation",
            "Maintain current agricultural practices",
            "Keep optimal humidity levels (60-80%)",
            "Ensure proper nutrition and fertilization schedule",
            "Document healthy status for plantation records"
        ],
        "red_rust": {
            "Uncertain": [
                "Re-scan with a clearer, well-lit photo for better accuracy",
                "Monitor the affected area closely over the next 3-5 days",
                "Compare with nearby healthy leaves for visual differences"
            ],
            "Low": [
                "Monitor closely for spread to adjacent bushes",
                "Improve air circulation by pruning dense canopy",
                "Apply preventive copper-based fungicide (Bordeaux mixture 0.5%)",
                "Reduce overhead irrigation to minimize leaf wetness"
            ],
            "Medium": [
                "Apply copper-based fungicide (Bordeaux mixture 1%) immediately",
                "Remove and destroy severely affected leaves",
                "Increase monitoring frequency to every 3 days",
                "Check drainage and reduce humidity around bushes",
                "Document spread pattern for agricultural records"
            ],
            "High": [
                "URGENT: Apply systemic fungicide (e.g., Hexaconazole 5% EC)",
                "Remove and destroy all infected leaves - do not compost",
                "Isolate affected plants from healthy stock",
                "Review and improve irrigation practices immediately",
                "Consult agricultural extension officer"
            ],
            "Critical": [
                "CRITICAL: Immediate professional intervention required",
                "Apply intensive systemic fungicide treatment",
                "Remove and burn all infected plant material",
                "Quarantine the entire affected block",
                "Contact Tea Research Institute (TRI) for expert guidance",
                "Document all symptoms with photographs for expert review"
            ]
        },
        "blister_blight": {
            "Uncertain": [
                "Re-scan with a clearer photo - ensure leaf surface is visible",
                "Check for characteristic blister-like swellings on young leaves",
                "Monitor for 2-3 days and re-assess"
            ],
            "Low": [
                "Monitor weather conditions - high humidity promotes spread",
                "Apply preventive copper oxychloride spray",
                "Maintain plant hygiene and remove fallen infected leaves",
                "Increase plucking frequency to remove young infected shoots"
            ],
            "Medium": [
                "Apply copper oxychloride spray at recommended concentration",
                "Prune affected areas to improve air circulation",
                "Improve drainage around tea bushes",
                "Reduce shade if excessive (maintain 40-60%)",
                "Schedule follow-up inspection after 10 days"
            ],
            "High": [
                "URGENT: Apply systemic fungicide (Hexaconazole 5% EC at 2ml/L)",
                "Remove and burn infected material - do not leave on ground",
                "Stop overhead irrigation immediately",
                "Apply multiple treatments at 7-day intervals",
                "Seek expert consultation from TRI"
            ],
            "Critical": [
                "CRITICAL: Emergency treatment required",
                "Apply intensive systemic + contact fungicide combination",
                "Harvest and destroy all affected shoots immediately",
                "Quarantine block and prevent cross-contamination",
                "Contact Tea Research Institute for emergency guidance",
                "Suspend harvesting from affected area until cleared"
            ]
        },
        "not_a_leaf": [
            "The uploaded image does not appear to contain a tea leaf",
            "Please capture a clear, close-up photo of the tea leaf",
            "Ensure the leaf fills most of the frame with good lighting",
            "Avoid blurry images - hold the camera steady"
        ]
    }

    disease_key = disease_name.lower().replace(" ", "_")

    if disease_key == "healthy":
        return recommendations["healthy"]

    if disease_key == "not_a_leaf" or disease_key == "no_detection":
        return recommendations["not_a_leaf"]

    if disease_key in recommendations:
        disease_recs = recommendations[disease_key]
        if isinstance(disease_recs, dict):
            return disease_recs.get(severity, disease_recs.get("Medium", ["Monitor closely"]))
        return disease_recs

    return ["Monitor the plant closely for any changes", "Consult a qualified agricultural expert for diagnosis"]


@router.post("/detect")
async def detect_disease(
    image: UploadFile = File(...),
    plantation_id: Optional[str] = Form(None),
    location_lat: Optional[float] = Form(None),
    location_lng: Optional[float] = Form(None),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    air_quality: Optional[float] = Form(None),
    request_explainability: Optional[bool] = Form(False),
    skip_quality_check: Optional[bool] = Form(False),
):
    """
    Detect disease in tea leaf image using trained YOLOv8 model.

    Includes robust validation:
    - Image format, size, and dimension checks
    - Real image quality assessment (blur, brightness, contrast)
    - Tea leaf verification (green content + model confidence)
    - "Not A Leaf" detection for non-leaf images
    """
    request_id = str(uuid.uuid4())
    image_id = str(uuid.uuid4())
    start_time = time.perf_counter()

    try:
        # ── Step 1: Read & validate image upload ──────────────────────────
        image_bytes = await image.read()
        validation = validate_image_upload(image, image_bytes)
        img = validation["image"]
        upload_warnings = validation.get("warnings", [])

        # ── Step 2: Assess image quality ──────────────────────────────────
        quality_metrics = assess_image_quality(img)

        if not skip_quality_check and not quality_metrics["is_acceptable"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "message": "Image quality is too low for reliable detection",
                    "quality_score": quality_metrics["overall_score"],
                    "issues": quality_metrics["issues"],
                    "suggestion": "Please retake the photo with better lighting and focus."
                }
            )

        # ── Step 3: Load model & run inference ────────────────────────────
        model = get_model()
        if model is None:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Disease detection model not loaded. Please contact support."
            )

        results = model(img, conf=0.25, iou=0.45, verbose=False)

        img_height, img_width = img.shape[:2]
        detections = []

        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for i in range(len(boxes)):
                    box = boxes.xyxy[i].cpu().numpy()
                    conf = float(boxes.conf[i].cpu().numpy())
                    cls_id = int(boxes.cls[i].cpu().numpy())

                    if cls_id < len(CLASS_NAMES):
                        class_name = CLASS_NAMES[cls_id]
                    else:
                        class_name = "unknown"

                    box_width = float(box[2] - box[0])
                    box_height = float(box[3] - box[1])
                    area_percentage = float((box_width * box_height) / (img_width * img_height) * 100)

                    detections.append({
                        "class_name": class_name,
                        "class_id": int(cls_id),
                        "confidence": float(conf),
                        "bounding_box": {
                            "x_min": float(box[0]),
                            "y_min": float(box[1]),
                            "x_max": float(box[2]),
                            "y_max": float(box[3]),
                            "confidence": float(conf)
                        },
                        "area_percentage": float(area_percentage)
                    })

        # ── Step 3.5: Refine detections (False Positive Suppression) ──────
        detections = refine_detections(img, detections, quality_metrics)

        # ── Step 4: Tea leaf verification ──────────────────────────────
        is_leaf = is_tea_leaf_image(img, detections)

        if not is_leaf:
            # Not a tea leaf image
            processing_time_ms = (time.perf_counter() - start_time) * 1000
            response = {
                "request_id": request_id,
                "image_id": image_id,
                "timestamp": datetime.utcnow().isoformat(),
                "processing_time_ms": float(processing_time_ms),
                "model_version": "yolov8n-tealeaf-95",
                "disease_type": "Not A Leaf",
                "confidence": 0.0,
                "severity": "None",
                "recommendations": get_recommendations("not_a_leaf", "None"),
                "detections": [],
                "summary": {
                    "total_leaves_detected": 0,
                    "healthy_count": 0,
                    "red_rust_count": 0,
                    "blister_blight_count": 0,
                    "overall_health_score": 0.0,
                    "dominant_disease": "not_a_leaf",
                    "severity_level": "none",
                    "requires_immediate_action": False
                },
                "image_quality": quality_metrics,
                "validation": {
                    "is_tea_leaf": False,
                    "message": "The uploaded image does not appear to contain a tea leaf. Please capture a clear, close-up photo of the tea leaf."
                }
            }
            if temperature is not None:
                response["temperature"] = temperature
            if humidity is not None:
                response["humidity"] = humidity
            if air_quality is not None:
                response["air_quality"] = air_quality
            return JSONResponse(content=response)

        # ── Step 5: Build summary from valid detections ───────────────
        # Filter out very low confidence detections for more accurate summary
        reliable_detections = [d for d in detections if d["confidence"] >= MIN_CONFIDENCE_VALID]
        if not reliable_detections and detections:
            reliable_detections = detections  # Fallback to all if none pass threshold

        if reliable_detections:
            healthy_count = sum(1 for d in reliable_detections if d["class_name"] == "healthy")
            red_rust_count = sum(1 for d in reliable_detections if d["class_name"] == "red_rust")
            blister_blight_count = sum(1 for d in reliable_detections if d["class_name"] == "blister_blight")
            total = len(reliable_detections)

            disease_counts = {
                "healthy": healthy_count,
                "red_rust": red_rust_count,
                "blister_blight": blister_blight_count
            }
            dominant = max(disease_counts, key=disease_counts.get)

            health_score = (healthy_count / total * 100) if total > 0 else 0

            disease_ratio = (red_rust_count + blister_blight_count) / total if total > 0 else 0
            if disease_ratio == 0:
                severity_level = "none"
            elif disease_ratio < 0.2:
                severity_level = "low"
            elif disease_ratio < 0.4:
                severity_level = "moderate"
            elif disease_ratio < 0.6:
                severity_level = "high"
            else:
                severity_level = "critical"

            # Average confidence for reliability indicator
            avg_confidence = sum(d["confidence"] for d in reliable_detections) / total

            summary = {
                "total_leaves_detected": int(total),
                "healthy_count": int(healthy_count),
                "red_rust_count": int(red_rust_count),
                "blister_blight_count": int(blister_blight_count),
                "overall_health_score": round(float(health_score), 1),
                "dominant_disease": dominant if dominant != "healthy" else None,
                "severity_level": severity_level,
                "requires_immediate_action": severity_level in ["high", "critical"],
                "average_confidence": round(float(avg_confidence), 3),
                "detection_reliability": "high" if avg_confidence >= 0.7 else ("medium" if avg_confidence >= 0.5 else "low"),
                "potential_lighting_interference": any(d.get("is_potential_fp", False) for d in detections)
            }
        else:
            summary = {
                "total_leaves_detected": 0,
                "healthy_count": 0,
                "red_rust_count": 0,
                "blister_blight_count": 0,
                "overall_health_score": 0.0,
                "dominant_disease": None,
                "severity_level": "none",
                "requires_immediate_action": False,
                "average_confidence": 0.0,
                "detection_reliability": "none"
            }

        # ── Step 6: Build final response ──────────────────────────────
        processing_time_ms = (time.perf_counter() - start_time) * 1000

        if reliable_detections:
            primary_detection = max(reliable_detections, key=lambda x: x["confidence"])
            disease_type = primary_detection["class_name"].replace("_", " ").title()
            confidence = primary_detection["confidence"]
        else:
            disease_type = "Healthy"  # Default if leaf verified but no disease
            confidence = 0.5

        severity = get_severity(confidence, disease_type)
        recommendations = get_recommendations(disease_type.lower().replace(" ", "_"), severity)

        response = {
            "request_id": request_id,
            "image_id": image_id,
            "timestamp": datetime.utcnow().isoformat(),
            "processing_time_ms": round(float(processing_time_ms), 2),
            "model_version": "yolov8n-tealeaf-95",
            "disease_type": disease_type,
            "confidence": round(float(confidence), 4),
            "severity": severity,
            "recommendations": recommendations,
            "detections": detections,
            "summary": summary,
            "image_quality": quality_metrics,
            "validation": {
                "is_tea_leaf": True,
                "reliable_detection_count": len(reliable_detections),
                "total_detection_count": len(detections),
                "warnings": upload_warnings,
                "message": ""
            }
        }

        if summary.get("potential_lighting_interference"):
            response["validation"]["message"] += "Lighting artifacts (glare/reflections) detected which may affect accuracy. "
            if disease_type != "Healthy" and confidence < 0.75:
                # If we suspect FP and confidence isn't dominant, suggest the leaf might actually be healthy
                response["validation"]["message"] += "This detection may be a false positive caused by light reflections. "
                response["recommendations"].insert(0, "QUALITY ALERT: The detected disease might be a false positive due to lighting artifacts. Please retake the photo in diffused light.")

        if not response["validation"]["message"]:
             response["validation"]["message"] = "Analysis complete. Tea leaf verified and scanned."

        if temperature is not None:
            response["temperature"] = temperature
        if humidity is not None:
            response["humidity"] = humidity
        if air_quality is not None:
            response["air_quality"] = air_quality

        return JSONResponse(content=response)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Detection error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Detection failed: {str(e)}"
        )


@router.get("/model-info")
async def get_model_info():
    """Get information about the loaded model"""
    model = get_model()

    if model is None:
        return {
            "status": "not_loaded",
            "model_path": MODEL_PATH,
            "exists": Path(MODEL_PATH).exists(),
            "message": "Model not loaded"
        }

    return {
        "status": "loaded",
        "model_name": "YOLOv8n-TeaLeaf-95",
        "model_version": "tealeaf_95",
        "model_path": MODEL_PATH,
        "classes": CLASS_NAMES,
        "input_size": 640,
        "device": "cpu"
    }


@router.post("/batch-detect")
async def batch_detect(
    images: List[UploadFile] = File(...),
    block_id: Optional[str] = Form(None),
    field_id: Optional[str] = Form(None),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
):
    """Batch detect diseases in multiple images"""
    results = []
    healthy_count = 0
    infected_count = 0
    disease_counts = {}

    model = get_model()
    if model is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Model not loaded"
        )

    for idx, img_file in enumerate(images):
        try:
            image_bytes = await img_file.read()
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            if img is None:
                continue

            # Run inference
            model_results = model(img, conf=0.25, iou=0.45, verbose=False)

            # Get best detection
            best_conf = 0
            best_class = "healthy"

            for result in model_results:
                boxes = result.boxes
                if boxes is not None:
                    for i in range(len(boxes)):
                        conf = float(boxes.conf[i].cpu().numpy())
                        cls_id = int(boxes.cls[i].cpu().numpy())
                        if conf > best_conf:
                            best_conf = conf
                            best_class = CLASS_NAMES[cls_id] if cls_id < len(CLASS_NAMES) else "unknown"

            if best_class == "healthy":
                healthy_count += 1
            else:
                infected_count += 1
                disease_counts[best_class] = disease_counts.get(best_class, 0) + 1

            severity = get_severity(best_conf, best_class)

            results.append({
                "image_index": int(idx),
                "disease_type": best_class.replace("_", " ").title(),
                "confidence": float(best_conf) if best_conf > 0 else 0.5,
                "severity": severity
            })

        except Exception as e:
            print(f"Error processing image {idx}: {e}")
            continue

    total = len(results)
    health_percentage = (healthy_count / total * 100) if total > 0 else 0

    if health_percentage >= 70:
        overall_status = "Healthy Block"
    elif health_percentage >= 40:
        overall_status = "Moderate Risk"
    else:
        overall_status = "High Risk Block"

    return {
        "total_images": int(total),
        "healthy_count": int(healthy_count),
        "infected_count": int(infected_count),
        "health_percentage": float(health_percentage),
        "overall_status": overall_status,
        "disease_counts": disease_counts,
        "results": results,
        "timestamp": datetime.utcnow().isoformat(),
        "temperature": temperature,
        "humidity": humidity,
        "recommendations": get_recommendations(
            "red_rust" if "red_rust" in disease_counts else "healthy",
            "Medium" if infected_count > healthy_count else "Low"
        )
    }


@router.post("/field-analysis")
async def field_analysis(
    image: UploadFile = File(...),
    block_id: Optional[str] = Form(None),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    detect_multiple: Optional[bool] = Form(True),
):
    """Analyze a field image for multiple leaf detections with robust validation."""
    try:
        # ── Step 1: Validate upload ───────────────────────────────────
        image_bytes = await image.read()
        validation = validate_image_upload(image, image_bytes)
        img = validation["image"]

        # ── Step 2: Quality check ─────────────────────────────────────
        quality_metrics = assess_image_quality(img)

        # ── Step 3: Load model ────────────────────────────────────────
        model = get_model()
        if model is None:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Disease detection model not loaded. Please contact support."
            )

        # ── Step 4: Run inference ─────────────────────────────────────
        results = model(img, conf=0.25, iou=0.45, verbose=False)

        healthy_count = 0
        infected_count = 0
        disease_counts = {}
        bounding_boxes = []
        all_confidences = []

        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for i in range(len(boxes)):
                    box = boxes.xyxy[i].cpu().numpy()
                    conf = float(boxes.conf[i].cpu().numpy())
                    cls_id = int(boxes.cls[i].cpu().numpy())

                    # Skip very low confidence detections for field analysis
                    if conf < MIN_CONFIDENCE_VALID:
                        continue

                    class_name = CLASS_NAMES[cls_id] if cls_id < len(CLASS_NAMES) else "unknown"
                    all_confidences.append(conf)

                    if class_name == "healthy":
                        healthy_count += 1
                    else:
                        infected_count += 1
                        display_name = class_name.replace("_", " ").title()
                        disease_counts[display_name] = disease_counts.get(display_name, 0) + 1

                    bounding_boxes.append({
                        "x": float(box[0]),
                        "y": float(box[1]),
                        "width": float(box[2] - box[0]),
                        "height": float(box[3] - box[1]),
                        "disease_type": class_name.replace("_", " ").title(),
                        "confidence": round(float(conf), 4)
                    })

        total = healthy_count + infected_count
        health_percentage = round((healthy_count / total * 100), 1) if total > 0 else 0.0
        avg_confidence = round(sum(all_confidences) / len(all_confidences), 3) if all_confidences else 0.0

        if health_percentage >= 70:
            overall_status = "Healthy Area"
        elif health_percentage >= 40:
            overall_status = "Moderate Risk"
        else:
            overall_status = "Critical Area"

        # Build recommendations based on most prevalent disease
        if disease_counts:
            primary_disease_key = max(disease_counts, key=disease_counts.get).lower().replace(" ", "_")
            rec_severity = "High" if infected_count > healthy_count else ("Medium" if infected_count > 0 else "Low")
        else:
            primary_disease_key = "healthy"
            rec_severity = "Low"

        return {
            "detected_leaf_count": int(total),
            "healthy_count": int(healthy_count),
            "infected_count": int(infected_count),
            "health_percentage": float(health_percentage),
            "overall_status": overall_status,
            "disease_counts": disease_counts,
            "timestamp": datetime.utcnow().isoformat(),
            "temperature": temperature,
            "humidity": humidity,
            "average_confidence": avg_confidence,
            "detection_reliability": "high" if avg_confidence >= 0.7 else ("medium" if avg_confidence >= 0.5 else "low"),
            "image_quality": quality_metrics,
            "recommendations": get_recommendations(primary_disease_key, rec_severity),
            "bounding_boxes": bounding_boxes
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Field analysis error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Field analysis failed: {str(e)}"
        )
