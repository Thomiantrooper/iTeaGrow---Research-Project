from fastapi import APIRouter, HTTPException, status, Depends, Query
from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from database import get_database
from models import DiseaseDetection, DiseaseDetectionCreate
from auth import get_current_active_user

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
        "disease_name": detection.disease_name,
        "confidence": detection.confidence,
        "severity": detection.severity,
        "recommendations": detection.recommendations,
        "created_at": datetime.utcnow()
    }

    result = await db.disease_detections.insert_one(detection_doc)
    detection_doc["_id"] = str(result.inserted_id)

    return DiseaseDetection(**detection_doc)

@router.get("/detections", response_model=List[DiseaseDetection])
async def get_detections(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    disease_name: Optional[str] = None,
    current_user: dict = Depends(get_current_active_user)
):
    """Get disease detection history for current user"""
    db = get_database()

    query = {"user_id": str(current_user["_id"])}
    if disease_name:
        query["disease_name"] = {"$regex": disease_name, "$options": "i"}

    cursor = db.disease_detections.find(query).sort("created_at", -1).skip(skip).limit(limit)

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
