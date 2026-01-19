from fastapi import APIRouter, HTTPException, status, Depends, Query, UploadFile, File, Form
from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from database import get_database
from models import DiseaseDetection, DiseaseDetectionCreate, DetectionItem, DetectionSummary, BoundingBoxModel
from auth import get_current_active_user
import base64
import uuid

router = APIRouter(prefix="/api/disease", tags=["disease"])

@router.post("/detections", response_model=DiseaseDetection, status_code=status.HTTP_201_CREATED)
async def create_detection(
    detection: DiseaseDetectionCreate,
    current_user: dict = Depends(get_current_active_user)
):
    """Create a new disease detection record"""
    db = get_database()

    detection_doc = {
        "user_id": str(current_user["_id"]),
        "image_path": detection.image_path,
        "image_data": detection.image_data,
        "disease_name": detection.disease_name,
        "confidence": detection.confidence,
        "severity": detection.severity,
        "recommendations": detection.recommendations,
        "detections": [d.model_dump() for d in detection.detections] if detection.detections else None,
        "summary": detection.summary.model_dump() if detection.summary else None,
        "temperature": detection.temperature,
        "humidity": detection.humidity,
        "air_quality": detection.air_quality,
        "processing_time_ms": detection.processing_time_ms,
        "model_version": detection.model_version,
        "request_id": detection.request_id,
        "created_at": datetime.utcnow()
    }

    result = await db.disease_detections.insert_one(detection_doc)
    detection_doc["_id"] = str(result.inserted_id)

    return DiseaseDetection(**detection_doc)

@router.post("/detections/with-image", response_model=DiseaseDetection, status_code=status.HTTP_201_CREATED)
async def create_detection_with_image(
    image: UploadFile = File(...),
    disease_name: str = Form(...),
    confidence: float = Form(...),
    severity: Optional[str] = Form(None),
    recommendations: Optional[str] = Form(None),  # JSON string
    detections: Optional[str] = Form(None),  # JSON string
    summary: Optional[str] = Form(None),  # JSON string
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    air_quality: Optional[float] = Form(None),
    processing_time_ms: Optional[float] = Form(None),
    model_version: Optional[str] = Form(None),
    request_id: Optional[str] = Form(None),
    # Field analysis fields
    is_field_analysis: Optional[str] = Form(None),  # "true" or "false"
    detected_leaf_count: Optional[int] = Form(None),
    healthy_count: Optional[int] = Form(None),
    infected_count: Optional[int] = Form(None),
    health_percentage: Optional[float] = Form(None),
    disease_counts: Optional[str] = Form(None),  # JSON string
    current_user: dict = Depends(get_current_active_user)
):
    """Create a new disease detection record with image upload"""
    import json
    db = get_database()

    # Read and encode image
    image_content = await image.read()
    image_base64 = base64.b64encode(image_content).decode('utf-8')

    # Parse JSON fields
    recommendations_list = json.loads(recommendations) if recommendations else None
    detections_list = json.loads(detections) if detections else None
    summary_dict = json.loads(summary) if summary else None
    disease_counts_dict = json.loads(disease_counts) if disease_counts else None

    detection_doc = {
        "user_id": str(current_user["_id"]),
        "image_path": image.filename,
        "image_data": image_base64,
        "disease_name": disease_name,
        "confidence": confidence,
        "severity": severity,
        "recommendations": recommendations_list,
        "detections": detections_list,
        "summary": summary_dict,
        "temperature": temperature,
        "humidity": humidity,
        "air_quality": air_quality,
        "processing_time_ms": processing_time_ms,
        "model_version": model_version,
        "request_id": request_id or str(uuid.uuid4()),
        "created_at": datetime.utcnow(),
        # Field analysis data
        "is_field_analysis": is_field_analysis == "true" if is_field_analysis else False,
        "detected_leaf_count": detected_leaf_count,
        "healthy_count": healthy_count,
        "infected_count": infected_count,
        "health_percentage": health_percentage,
        "disease_counts": disease_counts_dict,
    }

    result = await db.disease_detections.insert_one(detection_doc)
    detection_doc["_id"] = str(result.inserted_id)

    return DiseaseDetection(**detection_doc)

@router.get("/detections", response_model=List[DiseaseDetection])
async def get_detections(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    disease_name: Optional[str] = None,
    include_image: bool = Query(False, description="Include base64 image data in response"),
    current_user: dict = Depends(get_current_active_user)
):
    """Get disease detection history for current user"""
    db = get_database()

    query = {"user_id": str(current_user["_id"])}
    if disease_name:
        query["disease_name"] = {"$regex": disease_name, "$options": "i"}

    # Optionally exclude image_data for faster queries
    projection = None if include_image else {"image_data": 0}

    cursor = db.disease_detections.find(query, projection).sort("created_at", -1).skip(skip).limit(limit)

    detections = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        detections.append(DiseaseDetection(**doc))

    return detections

@router.get("/detections/{detection_id}", response_model=DiseaseDetection)
async def get_detection(
    detection_id: str,
    current_user: dict = Depends(get_current_active_user)
):
    """Get a specific disease detection record"""
    db = get_database()

    if not ObjectId.is_valid(detection_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid detection ID"
        )

    detection = await db.disease_detections.find_one({
        "_id": ObjectId(detection_id),
        "user_id": str(current_user["_id"])
    })

    if not detection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Detection not found"
        )

    detection["_id"] = str(detection["_id"])
    return DiseaseDetection(**detection)

@router.delete("/detections/{detection_id}")
async def delete_detection(
    detection_id: str,
    current_user: dict = Depends(get_current_active_user)
):
    """Delete a disease detection record"""
    db = get_database()

    if not ObjectId.is_valid(detection_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid detection ID"
        )

    result = await db.disease_detections.delete_one({
        "_id": ObjectId(detection_id),
        "user_id": str(current_user["_id"])
    })

    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Detection not found"
        )

    return {"message": "Detection deleted successfully"}

@router.get("/statistics")
async def get_statistics(
    current_user: dict = Depends(get_current_active_user)
):
    """Get disease detection statistics for current user"""
    db = get_database()

    pipeline = [
        {"$match": {"user_id": str(current_user["_id"])}},
        {
            "$group": {
                "_id": "$disease_name",
                "count": {"$sum": 1},
                "avg_confidence": {"$avg": "$confidence"},
                "last_detection": {"$max": "$created_at"}
            }
        },
        {"$sort": {"count": -1}}
    ]

    cursor = db.disease_detections.aggregate(pipeline)

    stats = []
    total = 0
    async for doc in cursor:
        stats.append({
            "disease_name": doc["_id"],
            "count": doc["count"],
            "avg_confidence": round(doc["avg_confidence"], 2),
            "last_detection": doc["last_detection"]
        })
        total += doc["count"]

    return {
        "total_detections": total,
        "by_disease": stats
    }

@router.get("/statistics/detailed")
async def get_detailed_statistics(
    days: int = Query(30, ge=1, le=365, description="Number of days to include in statistics"),
    current_user: dict = Depends(get_current_active_user)
):
    """Get detailed disease detection statistics with trends for charts"""
    db = get_database()
    user_id = str(current_user["_id"])
    cutoff_date = datetime.utcnow() - timedelta(days=days)

    # Disease distribution
    disease_pipeline = [
        {"$match": {"user_id": user_id, "created_at": {"$gte": cutoff_date}}},
        {
            "$group": {
                "_id": "$disease_name",
                "count": {"$sum": 1},
                "avg_confidence": {"$avg": "$confidence"},
                "avg_severity_score": {
                    "$avg": {
                        "$switch": {
                            "branches": [
                                {"case": {"$eq": ["$severity", "Low"]}, "then": 1},
                                {"case": {"$eq": ["$severity", "Medium"]}, "then": 2},
                                {"case": {"$eq": ["$severity", "High"]}, "then": 3}
                            ],
                            "default": 0
                        }
                    }
                }
            }
        },
        {"$sort": {"count": -1}}
    ]

    # Daily trend
    daily_pipeline = [
        {"$match": {"user_id": user_id, "created_at": {"$gte": cutoff_date}}},
        {
            "$group": {
                "_id": {
                    "$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}
                },
                "total": {"$sum": 1},
                "healthy": {
                    "$sum": {"$cond": [{"$eq": ["$disease_name", "Healthy"]}, 1, 0]}
                },
                "infected": {
                    "$sum": {"$cond": [{"$ne": ["$disease_name", "Healthy"]}, 1, 0]}
                }
            }
        },
        {"$sort": {"_id": 1}}
    ]

    # Severity distribution
    severity_pipeline = [
        {"$match": {"user_id": user_id, "created_at": {"$gte": cutoff_date}}},
        {
            "$group": {
                "_id": "$severity",
                "count": {"$sum": 1}
            }
        }
    ]

    # Environmental correlation
    env_pipeline = [
        {"$match": {
            "user_id": user_id,
            "created_at": {"$gte": cutoff_date},
            "temperature": {"$exists": True, "$ne": None}
        }},
        {
            "$group": {
                "_id": "$disease_name",
                "avg_temp": {"$avg": "$temperature"},
                "avg_humidity": {"$avg": "$humidity"},
                "avg_air_quality": {"$avg": "$air_quality"},
                "count": {"$sum": 1}
            }
        }
    ]

    # Execute all pipelines
    disease_cursor = db.disease_detections.aggregate(disease_pipeline)
    daily_cursor = db.disease_detections.aggregate(daily_pipeline)
    severity_cursor = db.disease_detections.aggregate(severity_pipeline)
    env_cursor = db.disease_detections.aggregate(env_pipeline)

    disease_stats = []
    async for doc in disease_cursor:
        disease_stats.append({
            "disease_name": doc["_id"],
            "count": doc["count"],
            "avg_confidence": round(doc["avg_confidence"], 2),
            "avg_severity_score": round(doc["avg_severity_score"], 2) if doc["avg_severity_score"] else 0
        })

    daily_trend = []
    async for doc in daily_cursor:
        daily_trend.append({
            "date": doc["_id"],
            "total": doc["total"],
            "healthy": doc["healthy"],
            "infected": doc["infected"]
        })

    severity_stats = {}
    async for doc in severity_cursor:
        if doc["_id"]:
            severity_stats[doc["_id"]] = doc["count"]

    env_stats = []
    async for doc in env_cursor:
        env_stats.append({
            "disease_name": doc["_id"],
            "avg_temperature": round(doc["avg_temp"], 1) if doc["avg_temp"] else None,
            "avg_humidity": round(doc["avg_humidity"], 1) if doc["avg_humidity"] else None,
            "avg_air_quality": round(doc["avg_air_quality"], 1) if doc["avg_air_quality"] else None,
            "count": doc["count"]
        })

    # Calculate totals
    total_scans = sum(d["count"] for d in disease_stats)
    healthy_count = next((d["count"] for d in disease_stats if d["disease_name"] == "Healthy"), 0)
    infected_count = total_scans - healthy_count

    return {
        "period_days": days,
        "total_scans": total_scans,
        "healthy_count": healthy_count,
        "infected_count": infected_count,
        "health_rate": round((healthy_count / total_scans * 100), 1) if total_scans > 0 else 0,
        "disease_distribution": disease_stats,
        "daily_trend": daily_trend,
        "severity_distribution": severity_stats,
        "environmental_correlation": env_stats
    }

@router.get("/recent")
async def get_recent_detections(
    limit: int = Query(10, ge=1, le=50),
    current_user: dict = Depends(get_current_active_user)
):
    """Get recent detection results with summary"""
    db = get_database()

    cursor = db.disease_detections.find(
        {"user_id": str(current_user["_id"])},
        {"image_data": 0}  # Exclude large image data
    ).sort("created_at", -1).limit(limit)

    detections = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        detections.append({
            "id": doc["_id"],
            "disease_name": doc.get("disease_name"),
            "confidence": doc.get("confidence"),
            "severity": doc.get("severity"),
            "temperature": doc.get("temperature"),
            "humidity": doc.get("humidity"),
            "created_at": doc.get("created_at")
        })

    return {
        "count": len(detections),
        "detections": detections
    }
