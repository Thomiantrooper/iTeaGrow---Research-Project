"""
Disease detection storage routes — save and retrieve scan results from MongoDB.
"""

from fastapi import APIRouter, HTTPException, Header, Depends, UploadFile, File, Form
from typing import Optional, List
from datetime import datetime
import base64
import json

from src.services.database.mongo_db import get_database
from src.api.routes.users import get_current_user_id
from src.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/api/disease", tags=["Disease Storage"])


@router.post("/detections/with-image", status_code=201)
async def create_detection_with_image(
    image: UploadFile = File(...),
    disease_name: str = Form(...),
    confidence: float = Form(0.0),
    severity: str = Form(""),
    recommendations: Optional[str] = Form(None),
    detections: Optional[str] = Form(None),
    summary: Optional[str] = Form(None),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    air_quality: Optional[float] = Form(None),
    processing_time_ms: Optional[int] = Form(None),
    request_id: Optional[str] = Form(None),
    image_quality_score: Optional[float] = Form(None),
    validation_message: Optional[str] = Form(None),
    is_field_analysis: Optional[str] = Form(None),
    detected_leaf_count: Optional[int] = Form(None),
    healthy_count: Optional[int] = Form(None),
    infected_count: Optional[int] = Form(None),
    health_percentage: Optional[float] = Form(None),
    disease_counts: Optional[str] = Form(None),
    user_id: str = Depends(get_current_user_id),
):
    """Create a new disease detection record with image upload."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    # Read and encode image
    image_bytes = await image.read()
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")

    # Parse JSON fields
    recs = json.loads(recommendations) if recommendations else []
    dets = json.loads(detections) if detections else None
    summ = json.loads(summary) if summary else None
    dc = json.loads(disease_counts) if disease_counts else None

    detection_doc = {
        "user_id": user_id,
        "image_data": image_base64,
        "disease_name": disease_name,
        "confidence": confidence,
        "severity": severity,
        "recommendations": recs,
        "detections": dets,
        "summary": summ,
        "temperature": temperature,
        "humidity": humidity,
        "air_quality": air_quality,
        "processing_time_ms": processing_time_ms,
        "request_id": request_id,
        "image_quality_score": image_quality_score,
        "validation_message": validation_message,
        "is_field_analysis": is_field_analysis == "true" if is_field_analysis else False,
        "detected_leaf_count": detected_leaf_count,
        "healthy_count": healthy_count,
        "infected_count": infected_count,
        "health_percentage": health_percentage,
        "disease_counts": dc,
        "created_at": datetime.utcnow().isoformat(),
    }

    result = await db.disease_detections.insert_one(detection_doc)
    detection_doc["_id"] = str(result.inserted_id)

    logger.info(f"Saved detection: {disease_name} ({confidence:.1%}) for user {user_id}")

    return {
        "id": str(result.inserted_id),
        "disease_name": disease_name,
        "confidence": confidence,
        "severity": severity,
        "created_at": detection_doc["created_at"],
        "message": "Detection saved successfully",
    }


@router.post("/detections", status_code=201)
async def create_detection(
    body: dict,
    user_id: str = Depends(get_current_user_id),
):
    """Create a new disease detection record (JSON body)."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    detection_doc = {
        "user_id": user_id,
        "image_path": body.get("image_path"),
        "image_data": body.get("image_data"),
        "disease_name": body.get("disease_name", "Unknown"),
        "confidence": body.get("confidence", 0.0),
        "severity": body.get("severity", ""),
        "recommendations": body.get("recommendations", []),
        "detections": body.get("detections"),
        "summary": body.get("summary"),
        "temperature": body.get("temperature"),
        "humidity": body.get("humidity"),
        "air_quality": body.get("air_quality"),
        "processing_time_ms": body.get("processing_time_ms"),
        "request_id": body.get("request_id"),
        "image_quality_score": body.get("image_quality_score"),
        "validation_message": body.get("validation_message"),
        "created_at": datetime.utcnow().isoformat(),
    }

    result = await db.disease_detections.insert_one(detection_doc)

    return {
        "id": str(result.inserted_id),
        "disease_name": detection_doc["disease_name"],
        "confidence": detection_doc["confidence"],
        "created_at": detection_doc["created_at"],
        "message": "Detection saved successfully",
    }


@router.get("/detections")
async def get_detections(
    skip: int = 0,
    limit: int = 50,
    disease_name: Optional[str] = None,
    include_image: bool = False,
    user_id: str = Depends(get_current_user_id),
):
    """Get disease detection history for current user."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    query = {"user_id": user_id}
    if disease_name:
        query["disease_name"] = {"$regex": disease_name, "$options": "i"}

    projection = None if include_image else {"image_data": 0}

    cursor = db.disease_detections.find(query, projection).sort("created_at", -1).skip(skip).limit(limit)
    results = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        results.append(doc)

    return results


@router.get("/statistics")
async def get_statistics(user_id: str = Depends(get_current_user_id)):
    """Get disease detection statistics for current user."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {
            "_id": "$disease_name",
            "count": {"$sum": 1},
            "avg_confidence": {"$avg": "$confidence"},
        }},
    ]

    cursor = db.disease_detections.aggregate(pipeline)
    stats = []
    async for doc in cursor:
        stats.append({
            "disease_name": doc["_id"],
            "count": doc["count"],
            "avg_confidence": doc["avg_confidence"],
        })

    total = await db.disease_detections.count_documents({"user_id": user_id})

    return {
        "total_detections": total,
        "by_disease": stats,
    }


@router.get("/recent")
async def get_recent(
    limit: int = 10,
    user_id: str = Depends(get_current_user_id),
):
    """Get recent detections for current user."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    cursor = (
        db.disease_detections.find({"user_id": user_id}, {"image_data": 0})
        .sort("created_at", -1)
        .limit(limit)
    )
    results = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        results.append(doc)

    return {"recent": results, "count": len(results)}


@router.get("/statistics/detailed")
async def get_detailed_statistics(
    days: int = 30,
    user_id: str = Depends(get_current_user_id),
):
    """Get detailed statistics for charts."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=503, detail="Database not available")

    total = await db.disease_detections.count_documents({"user_id": user_id})

    pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {
            "_id": "$disease_name",
            "count": {"$sum": 1},
            "avg_confidence": {"$avg": "$confidence"},
        }},
    ]
    cursor = db.disease_detections.aggregate(pipeline)
    by_disease = []
    async for doc in cursor:
        by_disease.append({
            "disease_name": doc["_id"],
            "count": doc["count"],
            "avg_confidence": doc["avg_confidence"],
        })

    return {
        "total_detections": total,
        "by_disease": by_disease,
        "days": days,
    }
