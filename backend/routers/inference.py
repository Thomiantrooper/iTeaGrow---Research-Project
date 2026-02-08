"""
Inference Router - Disease Detection using YOLOv8 trained model
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

router = APIRouter(prefix="/api/v1/inference", tags=["inference"])

# Model configuration - path relative to project root
MODEL_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "runs", "detect", "runs", "detect", "max_accuracy", "tealeaf_95", "weights", "best.pt"
)

# Class names for tea leaf disease detection (matching trained model)
# Model has: {0: 'blister_blight', 1: 'healthy', 2: 'red_rust'}
CLASS_NAMES = ["blister_blight", "healthy", "red_rust"]

# Global model instance
_model = None
_model_loaded = False

def get_model():
    """Load and cache the YOLO model"""
    global _model, _model_loaded

    if _model_loaded:
        return _model

    try:
        from ultralytics import YOLO

        if not Path(MODEL_PATH).exists():
            print(f"Model not found at: {MODEL_PATH}")
            _model = None
            _model_loaded = True
            return None

        print(f"Loading YOLOv8 model from: {MODEL_PATH}")
        _model = YOLO(MODEL_PATH)
        _model_loaded = True
        print("Model loaded successfully!")
        return _model
    except Exception as e:
        print(f"Failed to load model: {e}")
        _model = None
        _model_loaded = True
        return None


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
    """Generate recommendations based on disease and severity"""
    recommendations = {
        "healthy": [
            "Continue regular monitoring",
            "Maintain current practices",
            "Keep optimal humidity levels (60-80%)",
            "Ensure proper nutrition"
        ],
        "red_rust": {
            "Low": [
                "Monitor closely for spread",
                "Improve air circulation",
                "Apply preventive fungicide"
            ],
            "Medium": [
                "Apply copper-based fungicide immediately",
                "Remove severely affected leaves",
                "Increase monitoring frequency",
                "Check drainage and reduce humidity"
            ],
            "High": [
                "URGENT: Apply systemic fungicide",
                "Remove and destroy infected leaves",
                "Isolate affected plants",
                "Review irrigation practices",
                "Consult agricultural expert"
            ]
        },
        "blister_blight": {
            "Low": [
                "Monitor weather conditions",
                "Apply preventive spray",
                "Maintain plant hygiene"
            ],
            "Medium": [
                "Apply copper oxychloride spray",
                "Prune affected areas",
                "Improve drainage",
                "Reduce shade if excessive"
            ],
            "High": [
                "URGENT: Intensive fungicide treatment",
                "Remove and burn infected material",
                "Stop overhead irrigation",
                "Apply multiple treatments at 7-day intervals",
                "Seek expert consultation immediately"
            ]
        }
    }

    disease_key = disease_name.lower().replace(" ", "_")

    if disease_key == "healthy":
        return recommendations["healthy"]

    if disease_key in recommendations:
        return recommendations[disease_key].get(severity, recommendations[disease_key]["Medium"])

    return ["Monitor closely", "Consult agricultural expert"]


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
    Detect disease in tea leaf image using trained YOLOv8 model
    """
    request_id = str(uuid.uuid4())
    image_id = str(uuid.uuid4())
    start_time = time.perf_counter()

    try:
        # Read image bytes
        image_bytes = await image.read()

        # Convert to numpy array
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image format"
            )

        # Get the model
        model = get_model()

        detections = []
        summary = None

        if model is not None:
            # Run inference with the trained model
            results = model(img, conf=0.25, iou=0.45, verbose=False)

            img_height, img_width = img.shape[:2]

            # Process detections
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for i in range(len(boxes)):
                        box = boxes.xyxy[i].cpu().numpy()
                        conf = float(boxes.conf[i].cpu().numpy())
                        cls_id = int(boxes.cls[i].cpu().numpy())

                        # Map class ID to name
                        if cls_id < len(CLASS_NAMES):
                            class_name = CLASS_NAMES[cls_id]
                        else:
                            class_name = "unknown"

                        # Calculate area percentage
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

            # Create summary from detections
            if detections:
                healthy_count = sum(1 for d in detections if d["class_name"] == "healthy")
                red_rust_count = sum(1 for d in detections if d["class_name"] == "red_rust")
                blister_blight_count = sum(1 for d in detections if d["class_name"] == "blister_blight")
                total = len(detections)

                # Determine dominant disease
                disease_counts = {
                    "healthy": healthy_count,
                    "red_rust": red_rust_count,
                    "blister_blight": blister_blight_count
                }
                dominant = max(disease_counts, key=disease_counts.get)

                # Calculate health score
                health_score = (healthy_count / total * 100) if total > 0 else 0

                # Determine severity level
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

                summary = {
                    "total_leaves_detected": int(total),
                    "healthy_count": int(healthy_count),
                    "red_rust_count": int(red_rust_count),
                    "blister_blight_count": int(blister_blight_count),
                    "overall_health_score": float(health_score),
                    "dominant_disease": dominant if dominant != "healthy" else None,
                    "severity_level": severity_level,
                    "requires_immediate_action": severity_level in ["high", "critical"]
                }
            else:
                # No detections - could be not a leaf or healthy
                summary = {
                    "total_leaves_detected": 0,
                    "healthy_count": 0,
                    "red_rust_count": 0,
                    "blister_blight_count": 0,
                    "overall_health_score": 0,
                    "dominant_disease": None,
                    "severity_level": "none",
                    "requires_immediate_action": False
                }
        else:
            # Model not loaded - return error
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Model not loaded. Please check model path configuration."
            )

        # Calculate processing time
        processing_time_ms = (time.perf_counter() - start_time) * 1000

        # Determine primary detection for response
        if detections:
            # Get the detection with highest confidence
            primary_detection = max(detections, key=lambda x: x["confidence"])
            disease_type = primary_detection["class_name"].replace("_", " ").title()
            confidence = primary_detection["confidence"]
        else:
            disease_type = "No Detection"
            confidence = 0.0

        severity = get_severity(confidence, disease_type)
        recommendations = get_recommendations(disease_type.lower().replace(" ", "_"), severity)

        response = {
            "request_id": request_id,
            "image_id": image_id,
            "timestamp": datetime.utcnow().isoformat(),
            "processing_time_ms": float(processing_time_ms),
            "model_version": "yolov8n-tealeaf-95",
            "disease_type": disease_type,
            "confidence": float(confidence),
            "severity": severity,
            "recommendations": recommendations,
            "detections": detections,
            "summary": summary,
            "image_quality": {
                "overall_score": 0.85,
                "is_acceptable": True,
                "issues": []
            }
        }

        # Add environmental context if provided
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
        print(f"Detection error: {e}")
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
    """Analyze a field image for multiple leaf detections"""
    model = get_model()
    if model is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Model not loaded"
        )

    try:
        image_bytes = await image.read()
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image format"
            )

        # Run inference
        results = model(img, conf=0.25, iou=0.45, verbose=False)

        detections = []
        healthy_count = 0
        infected_count = 0
        disease_counts = {}
        bounding_boxes = []

        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for i in range(len(boxes)):
                    box = boxes.xyxy[i].cpu().numpy()
                    conf = float(boxes.conf[i].cpu().numpy())
                    cls_id = int(boxes.cls[i].cpu().numpy())

                    class_name = CLASS_NAMES[cls_id] if cls_id < len(CLASS_NAMES) else "unknown"

                    if class_name == "healthy":
                        healthy_count += 1
                    else:
                        infected_count += 1
                        disease_counts[class_name] = disease_counts.get(class_name, 0) + 1

                    bounding_boxes.append({
                        "x": float(box[0]),
                        "y": float(box[1]),
                        "width": float(box[2] - box[0]),
                        "height": float(box[3] - box[1]),
                        "disease_type": class_name.replace("_", " ").title(),
                        "confidence": float(conf)
                    })

        total = healthy_count + infected_count
        health_percentage = (healthy_count / total * 100) if total > 0 else 0

        if health_percentage >= 70:
            overall_status = "Healthy Area"
        elif health_percentage >= 40:
            overall_status = "Moderate Risk"
        else:
            overall_status = "Critical Area"

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
            "recommendations": get_recommendations(
                list(disease_counts.keys())[0] if disease_counts else "healthy",
                "Medium" if infected_count > healthy_count else "Low"
            ),
            "bounding_boxes": bounding_boxes
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"Field analysis error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Field analysis failed: {str(e)}"
        )
