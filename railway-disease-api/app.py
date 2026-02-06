"""
Tea Leaf Disease Detection API - Hugging Face Spaces
Lightweight FastAPI backend for disease detection
"""

import os
import io
import uuid
from datetime import datetime
from typing import Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image
import numpy as np

# Use ultralytics for YOLO
from ultralytics import YOLO

# Global model reference
model = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load model on startup"""
    global model
    print("Loading YOLOv8 model...")

    # Model path - will be in the same directory on HF Spaces
    model_path = os.environ.get("MODEL_PATH", "best.pt")

    try:
        model = YOLO(model_path)
        print(f"Model loaded successfully from {model_path}")
    except Exception as e:
        print(f"Error loading model: {e}")
        # Try alternative path
        try:
            model = YOLO("./best.pt")
            print("Model loaded from ./best.pt")
        except Exception as e2:
            print(f"Failed to load model: {e2}")

    yield

    print("Shutting down...")

app = FastAPI(
    title="iTeaGrow Disease Detection API",
    description="Tea Leaf Disease Detection using YOLOv8",
    version="1.0.0",
    lifespan=lifespan
)

# CORS - allow all origins for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Disease class mapping
CLASS_NAMES = ["healthy", "red_rust", "blister_blight"]
CLASS_DISPLAY_NAMES = {
    "healthy": "Healthy",
    "red_rust": "Red Rust",
    "blister_blight": "Blister Blight"
}

RECOMMENDATIONS = {
    "healthy": [
        "Continue regular monitoring",
        "Maintain current agricultural practices",
        "Ensure proper drainage and ventilation"
    ],
    "red_rust": [
        "Apply copper-based fungicide (Bordeaux mixture)",
        "Prune affected branches and burn them",
        "Improve air circulation by thinning dense canopy",
        "Avoid overhead irrigation",
        "Monitor neighboring plants for spread"
    ],
    "blister_blight": [
        "Apply systemic fungicide (Hexaconazole or Propiconazole)",
        "Remove and destroy infected leaves",
        "Ensure proper spacing between plants",
        "Avoid harvesting during wet conditions",
        "Apply preventive sprays during monsoon season"
    ]
}


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "iTeaGrow Disease Detection API",
        "version": "1.0.0",
        "status": "operational",
        "model_loaded": model is not None
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "timestamp": datetime.utcnow().isoformat()
    }


@app.post("/api/v1/inference/detect")
async def detect_disease(
    image: UploadFile = File(...),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    air_quality: Optional[float] = Form(None),
    plantation_id: Optional[str] = Form(None),
    request_explainability: Optional[bool] = Form(False),
    skip_quality_check: Optional[bool] = Form(False),
):
    """
    Detect tea leaf disease from uploaded image
    """
    global model

    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        # Read and process image
        contents = await image.read()
        img = Image.open(io.BytesIO(contents))

        # Convert to RGB if necessary
        if img.mode != "RGB":
            img = img.convert("RGB")

        # Run inference
        results = model(img, conf=0.25, iou=0.45)

        # Process results
        detections = []
        disease_counts = {"healthy": 0, "red_rust": 0, "blister_blight": 0}

        for result in results:
            boxes = result.boxes
            if boxes is not None and len(boxes) > 0:
                for box in boxes:
                    cls_id = int(box.cls[0])
                    confidence = float(box.conf[0])
                    class_name = CLASS_NAMES[cls_id] if cls_id < len(CLASS_NAMES) else "unknown"

                    disease_counts[class_name] = disease_counts.get(class_name, 0) + 1

                    # Get bounding box coordinates
                    xyxy = box.xyxy[0].tolist()

                    detections.append({
                        "class": class_name,
                        "class_display": CLASS_DISPLAY_NAMES.get(class_name, class_name),
                        "confidence": round(confidence, 4),
                        "bbox": {
                            "x1": round(xyxy[0], 2),
                            "y1": round(xyxy[1], 2),
                            "x2": round(xyxy[2], 2),
                            "y2": round(xyxy[3], 2)
                        }
                    })

        # Determine primary disease (highest confidence or most common)
        if detections:
            # Sort by confidence
            detections.sort(key=lambda x: x["confidence"], reverse=True)
            primary_detection = detections[0]
            disease_type = primary_detection["class_display"]
            confidence = primary_detection["confidence"]
        else:
            # No detection - assume healthy or unknown
            disease_type = "Healthy"
            confidence = 0.5

        # Get severity based on confidence and count
        if confidence > 0.85:
            severity = "High"
        elif confidence > 0.6:
            severity = "Medium"
        else:
            severity = "Low"

        # Get recommendations
        disease_key = disease_type.lower().replace(" ", "_")
        recommendations = RECOMMENDATIONS.get(disease_key, RECOMMENDATIONS["healthy"])

        # Build response
        response = {
            "success": True,
            "request_id": str(uuid.uuid4()),
            "image_id": str(uuid.uuid4()),
            "timestamp": datetime.utcnow().isoformat(),
            "processing_time_ms": 0,  # Could add timing
            "disease_type": disease_type,
            "confidence": confidence,
            "severity": severity,
            "recommendations": recommendations,
            "detections": detections,
            "summary": {
                "total_detections": len(detections),
                "disease_counts": disease_counts,
                "healthy_count": disease_counts.get("healthy", 0),
                "infected_count": sum(v for k, v in disease_counts.items() if k != "healthy")
            },
            "environmental_data": {
                "temperature": temperature,
                "humidity": humidity,
                "air_quality": air_quality
            }
        }

        return JSONResponse(content=response)

    except Exception as e:
        print(f"Error during inference: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/inference/field-analysis")
async def field_analysis(
    image: UploadFile = File(...),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    block_id: Optional[str] = Form(None),
    detect_multiple: Optional[bool] = Form(True),
):
    """
    Analyze field image for multiple leaf detections
    """
    global model

    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        contents = await image.read()
        img = Image.open(io.BytesIO(contents))

        if img.mode != "RGB":
            img = img.convert("RGB")

        # Run inference with lower confidence for more detections
        results = model(img, conf=0.2, iou=0.4)

        detections = []
        disease_counts = {}
        healthy_count = 0
        infected_count = 0

        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    cls_id = int(box.cls[0])
                    confidence = float(box.conf[0])
                    class_name = CLASS_NAMES[cls_id] if cls_id < len(CLASS_NAMES) else "unknown"

                    if class_name == "healthy":
                        healthy_count += 1
                    else:
                        infected_count += 1
                        disease_counts[class_name] = disease_counts.get(class_name, 0) + 1

                    xyxy = box.xyxy[0].tolist()
                    detections.append({
                        "disease_type": CLASS_DISPLAY_NAMES.get(class_name, class_name),
                        "confidence": round(confidence, 4),
                        "x": round(xyxy[0], 2),
                        "y": round(xyxy[1], 2),
                        "width": round(xyxy[2] - xyxy[0], 2),
                        "height": round(xyxy[3] - xyxy[1], 2)
                    })

        total_count = healthy_count + infected_count
        health_percentage = (healthy_count / total_count * 100) if total_count > 0 else 100

        if health_percentage >= 70:
            overall_status = "Healthy Area"
        elif health_percentage >= 40:
            overall_status = "Moderate Risk"
        else:
            overall_status = "Critical Area"

        return {
            "detected_leaf_count": total_count,
            "healthy_count": healthy_count,
            "infected_count": infected_count,
            "health_percentage": round(health_percentage, 2),
            "overall_status": overall_status,
            "disease_counts": {CLASS_DISPLAY_NAMES.get(k, k): v for k, v in disease_counts.items()},
            "timestamp": datetime.utcnow().isoformat(),
            "temperature": temperature,
            "humidity": humidity,
            "recommendations": _get_field_recommendations(health_percentage, disease_counts),
            "bounding_boxes": detections
        }

    except Exception as e:
        print(f"Error during field analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _get_field_recommendations(health_percentage: float, disease_counts: dict) -> List[str]:
    """Generate recommendations based on field analysis"""
    recommendations = []

    if health_percentage >= 80:
        recommendations.append("Maintain current management practices")
        recommendations.append("Continue regular monitoring schedule")
    elif health_percentage >= 50:
        recommendations.append("Increase monitoring frequency")
        recommendations.append("Apply preventive fungicide treatment")
        if disease_counts:
            most_common = max(disease_counts.items(), key=lambda x: x[1])
            recommendations.append(f"Focus treatment on {CLASS_DISPLAY_NAMES.get(most_common[0], most_common[0])} ({most_common[1]} cases)")
    else:
        recommendations.append("Immediate intervention required")
        recommendations.append("Apply targeted fungicide treatment")
        recommendations.append("Isolate severely affected areas")
        recommendations.append("Review environmental conditions")

    return recommendations


@app.get("/api/v1/inference/model-info")
async def model_info():
    """Get model information"""
    return {
        "model_name": "YOLOv8n Tea Leaf Disease Detection",
        "model_version": "1.0.0",
        "classes": CLASS_DISPLAY_NAMES,
        "input_size": 640,
        "framework": "ultralytics",
        "model_loaded": model is not None
    }


# For Railway deployment
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
