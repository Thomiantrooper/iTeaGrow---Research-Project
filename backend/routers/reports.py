"""
Reports API Routes for disease detection report data.
Provides structured data for client-side PDF generation in Flutter.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from datetime import datetime, timedelta
from typing import Optional
from bson import ObjectId
from database import get_database
from auth import get_current_active_user

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/{detection_id}")
async def get_report_data(
    detection_id: str,
    include_image: bool = Query(True, description="Include base64 image data"),
    current_user: dict = Depends(get_current_active_user)
):
    """Get full report data for a detection record, structured for PDF generation."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    if not ObjectId.is_valid(detection_id):
        raise HTTPException(status_code=400, detail="Invalid detection ID")

    detection = await db.disease_detections.find_one({"_id": ObjectId(detection_id)})
    if not detection:
        raise HTTPException(status_code=404, detail="Detection not found")

    # Fetch user info
    user = None
    try:
        user = await db.users.find_one({"_id": ObjectId(detection["user_id"])})
    except Exception:
        pass

    # Fetch latest IoT data for weather context
    weather_data = None
    try:
        iot_record = await db.iot_data.find_one(
            {"user_id": detection["user_id"]},
            sort=[("timestamp", -1)]
        )
        if iot_record:
            weather_data = {
                "temperature": iot_record.get("temperature"),
                "humidity": iot_record.get("humidity"),
                "soil_moisture": iot_record.get("soil_moisture"),
                "light_level": iot_record.get("light_level"),
                "recorded_at": iot_record.get("timestamp", "").isoformat() if isinstance(iot_record.get("timestamp"), datetime) else str(iot_record.get("timestamp", "")),
            }
    except Exception:
        pass

    # Build treatment recommendations based on disease
    disease_name = detection.get("disease_name", "Unknown")
    recommendations = detection.get("recommendations") or _get_default_recommendations(disease_name)
    precautions = _get_precautions(disease_name)

    report_data = {
        "report_id": f"RPT-{detection_id[-8:].upper()}",
        "generated_at": datetime.utcnow().isoformat(),
        "detection": {
            "id": str(detection["_id"]),
            "disease_name": disease_name,
            "confidence": detection.get("confidence", 0),
            "severity": detection.get("severity", "Unknown"),
            "created_at": detection.get("created_at", "").isoformat() if isinstance(detection.get("created_at"), datetime) else str(detection.get("created_at", "")),
            "image_data": detection.get("image_data") if include_image else None,
            "image_path": detection.get("image_path"),
            "processing_time_ms": detection.get("processing_time_ms"),
            "model_version": detection.get("model_version"),
        },
        "farmer": {
            "name": user["full_name"] if user else "Unknown",
            "username": user["username"] if user else "Unknown",
            "role": user.get("role", "farmer") if user else "farmer",
            "location": "Talawakelle, Sri Lanka",
        },
        "weather": weather_data,
        "recommendations": recommendations,
        "precautions": precautions,
        "summary": detection.get("summary"),
        "detections": detection.get("detections"),
        "organization": {
            "name": "iTeaGrow",
            "tagline": "AI-Powered Tea Leaf Disease Detection",
            "description": "iTeaGrow Research Project - Tea Plantation Management System",
        },
    }

    return report_data


@router.get("/user/history")
async def get_user_report_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    disease_name: Optional[str] = None,
    days: int = Query(90, ge=1, le=365),
    current_user: dict = Depends(get_current_active_user)
):
    """Get user's detection history for reports list."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    cutoff = datetime.utcnow() - timedelta(days=days)
    query = {
        "user_id": str(current_user["_id"]),
        "created_at": {"$gte": cutoff}
    }
    if disease_name:
        query["disease_name"] = {"$regex": disease_name, "$options": "i"}

    cursor = db.disease_detections.find(
        query, {"image_data": 0}
    ).sort("created_at", -1).skip(skip).limit(limit)

    total = await db.disease_detections.count_documents(query)

    records = []
    async for doc in cursor:
        records.append({
            "id": str(doc["_id"]),
            "disease_name": doc.get("disease_name"),
            "confidence": doc.get("confidence"),
            "severity": doc.get("severity"),
            "created_at": doc.get("created_at", "").isoformat() if isinstance(doc.get("created_at"), datetime) else str(doc.get("created_at", "")),
            "image_path": doc.get("image_path"),
            "has_image": doc.get("image_data") is not None,
        })

    return {"total": total, "skip": skip, "limit": limit, "records": records}


@router.get("/summary/range")
async def get_summary_report(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_active_user)
):
    """Get a summary report for a date range."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    if start_date and end_date:
        start = datetime.fromisoformat(start_date)
        end = datetime.fromisoformat(end_date)
    else:
        end = datetime.utcnow()
        start = end - timedelta(days=days)

    query = {
        "user_id": str(current_user["_id"]),
        "created_at": {"$gte": start, "$lte": end}
    }

    total_scans = await db.disease_detections.count_documents(query)

    # Disease breakdown
    pipeline = [
        {"$match": query},
        {
            "$group": {
                "_id": "$disease_name",
                "count": {"$sum": 1},
                "avg_confidence": {"$avg": "$confidence"},
            }
        },
        {"$sort": {"count": -1}}
    ]

    cursor = db.disease_detections.aggregate(pipeline)
    disease_summary = []
    async for doc in cursor:
        disease_summary.append({
            "disease_name": doc["_id"],
            "count": doc["count"],
            "avg_confidence": round(doc["avg_confidence"], 2) if doc["avg_confidence"] else 0,
        })

    # Fetch user info
    user = current_user

    return {
        "report_id": f"SUM-{datetime.utcnow().strftime('%Y%m%d%H%M')}",
        "generated_at": datetime.utcnow().isoformat(),
        "period": {
            "start": start.isoformat(),
            "end": end.isoformat(),
            "days": (end - start).days,
        },
        "farmer": {
            "name": user.get("full_name", "Unknown"),
            "username": user.get("username", "Unknown"),
        },
        "total_scans": total_scans,
        "disease_summary": disease_summary,
    }


def _get_default_recommendations(disease_name: str) -> list:
    """Get default treatment recommendations based on disease."""
    recommendations = {
        "Red Rust": [
            "Apply copper-based fungicide (Bordeaux mixture 1%) immediately",
            "Prune and remove heavily infected leaves",
            "Improve air circulation by thinning dense canopy",
            "Avoid overhead irrigation to reduce leaf wetness",
            "Monitor neighboring plots for spread",
            "Re-inspect in 7-14 days to assess treatment effectiveness",
        ],
        "Blister Blight": [
            "Apply systemic fungicide (Hexaconazole 5% EC at 2ml/L)",
            "Spray preventive copper oxychloride during wet weather",
            "Harvest infected leaves to prevent spore spread",
            "Ensure proper drainage around tea bushes",
            "Increase plucking frequency to remove young infected shoots",
            "Schedule follow-up inspection after 10 days",
        ],
        "Healthy": [
            "Continue regular monitoring schedule",
            "Maintain current fertilization and irrigation practices",
            "Apply preventive fungicide spray during monsoon season",
            "Document healthy status for plantation records",
        ],
    }
    return recommendations.get(disease_name, [
        "Consult with a tea plantation pathologist for accurate diagnosis",
        "Collect affected leaf samples for laboratory analysis",
        "Isolate affected area to prevent potential spread",
        "Monitor daily for changes in symptoms",
    ])


def _get_precautions(disease_name: str) -> list:
    """Get precautionary measures based on disease."""
    precautions = {
        "Red Rust": [
            "Wear protective gloves when handling infected leaves",
            "Sanitize pruning tools between plants to prevent cross-contamination",
            "Do not compost infected plant material - destroy by burning",
            "Avoid working in wet conditions as spores spread more easily",
        ],
        "Blister Blight": [
            "Avoid harvesting during heavy rain or early morning dew",
            "Clean and disinfect harvesting equipment regularly",
            "Maintain recommended shade tree density (40-60%)",
            "Keep records of weather conditions for correlation analysis",
        ],
        "Healthy": [
            "Maintain regular inspection schedule (weekly during monsoon)",
            "Ensure balanced NPK fertilization as per TRI guidelines",
            "Keep plantation area clean and free of debris",
        ],
    }
    return precautions.get(disease_name, [
        "Isolate affected plants from healthy ones",
        "Consult agricultural extension officer",
        "Document all symptoms with photographs for expert review",
    ])
