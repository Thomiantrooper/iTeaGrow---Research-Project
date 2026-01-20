from fastapi import APIRouter, HTTPException, status, Depends, Query
from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
from database import get_database
from models import IoTDataPoint, IoTDataCreate
from auth import get_current_active_user

router = APIRouter(prefix="/api/iot", tags=["iot"])

@router.post("/data", response_model=IoTDataPoint, status_code=status.HTTP_201_CREATED)
async def create_iot_data(
    data: IoTDataCreate,
    current_user: dict = Depends(get_current_active_user)
):
    """Store IoT data point"""
    db = get_database()

    data_doc = {
        "user_id": str(current_user["_id"]),
        "device_id": data.device_id,
        "temperature": data.temperature,
        "humidity": data.humidity,
        "soil_moisture": data.soil_moisture,
        "air_quality": data.air_quality,
        "light_level": data.light_level,
        "timestamp": datetime.utcnow()
    }

    result = await db.iot_data.insert_one(data_doc)
    data_doc["_id"] = str(result.inserted_id)

    return IoTDataPoint(**data_doc)

@router.get("/data", response_model=List[IoTDataPoint])
async def get_iot_data(
    device_id: Optional[str] = None,
    hours: int = Query(24, ge=1, le=720),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: dict = Depends(get_current_active_user)
):
    """Get IoT data for current user"""
    db = get_database()

    since = datetime.utcnow() - timedelta(hours=hours)

    query = {
        "user_id": str(current_user["_id"]),
        "timestamp": {"$gte": since}
    }

    if device_id:
        query["device_id"] = device_id

    cursor = db.iot_data.find(query).sort("timestamp", -1).skip(skip).limit(limit)

    data_points = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        data_points.append(IoTDataPoint(**doc))

    return data_points

@router.get("/data/latest")
async def get_latest_data(
    device_id: Optional[str] = None,
    current_user: dict = Depends(get_current_active_user)
):
    """Get latest IoT data for each device or specific device"""
    db = get_database()

    if device_id:
        data = await db.iot_data.find_one(
            {"user_id": str(current_user["_id"]), "device_id": device_id},
            sort=[("timestamp", -1)]
        )
        if data:
            data["_id"] = str(data["_id"])
            return IoTDataPoint(**data)
        return None

    # Get latest data for all devices
    pipeline = [
        {"$match": {"user_id": str(current_user["_id"])}},
        {"$sort": {"timestamp": -1}},
        {
            "$group": {
                "_id": "$device_id",
                "latest": {"$first": "$$ROOT"}
            }
        }
    ]

    cursor = db.iot_data.aggregate(pipeline)

    latest_data = {}
    async for doc in cursor:
        data = doc["latest"]
        data["_id"] = str(data["_id"])
        latest_data[doc["_id"]] = IoTDataPoint(**data)

    return latest_data

@router.get("/devices")
async def get_devices(current_user: dict = Depends(get_current_active_user)):
    """Get list of IoT devices for current user"""
    db = get_database()

    pipeline = [
        {"$match": {"user_id": str(current_user["_id"])}},
        {
            "$group": {
                "_id": "$device_id",
                "last_seen": {"$max": "$timestamp"},
                "data_points": {"$sum": 1}
            }
        },
        {"$sort": {"last_seen": -1}}
    ]

    cursor = db.iot_data.aggregate(pipeline)

    devices = []
    async for doc in cursor:
        devices.append({
            "device_id": doc["_id"],
            "last_seen": doc["last_seen"],
            "data_points": doc["data_points"]
        })

    return devices

@router.get("/statistics")
async def get_iot_statistics(
    device_id: Optional[str] = None,
    hours: int = Query(24, ge=1, le=720),
    current_user: dict = Depends(get_current_active_user)
):
    """Get IoT data statistics"""
    db = get_database()

    since = datetime.utcnow() - timedelta(hours=hours)

    match_query = {
        "user_id": str(current_user["_id"]),
        "timestamp": {"$gte": since}
    }

    if device_id:
        match_query["device_id"] = device_id

    pipeline = [
        {"$match": match_query},
        {
            "$group": {
                "_id": None,
                "avg_temperature": {"$avg": "$temperature"},
                "min_temperature": {"$min": "$temperature"},
                "max_temperature": {"$max": "$temperature"},
                "avg_humidity": {"$avg": "$humidity"},
                "min_humidity": {"$min": "$humidity"},
                "max_humidity": {"$max": "$humidity"},
                "avg_soil_moisture": {"$avg": "$soil_moisture"},
                "avg_air_quality": {"$avg": "$air_quality"},
                "avg_light_level": {"$avg": "$light_level"},
                "data_points": {"$sum": 1}
            }
        }
    ]

    cursor = db.iot_data.aggregate(pipeline)

    async for doc in cursor:
        return {
            "period_hours": hours,
            "data_points": doc["data_points"],
            "temperature": {
                "avg": round(doc["avg_temperature"], 2) if doc["avg_temperature"] else None,
                "min": doc["min_temperature"],
                "max": doc["max_temperature"]
            },
            "humidity": {
                "avg": round(doc["avg_humidity"], 2) if doc["avg_humidity"] else None,
                "min": doc["min_humidity"],
                "max": doc["max_humidity"]
            },
            "soil_moisture": {
                "avg": round(doc["avg_soil_moisture"], 2) if doc["avg_soil_moisture"] else None
            },
            "air_quality": {
                "avg": round(doc["avg_air_quality"], 2) if doc["avg_air_quality"] else None
            },
            "light_level": {
                "avg": round(doc["avg_light_level"], 2) if doc["avg_light_level"] else None
            }
        }

    return {
        "period_hours": hours,
        "data_points": 0,
        "temperature": None,
        "humidity": None,
        "soil_moisture": None,
        "air_quality": None,
        "light_level": None
    }

@router.delete("/data")
async def delete_old_data(
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_active_user)
):
    """Delete IoT data older than specified days"""
    db = get_database()

    before = datetime.utcnow() - timedelta(days=days)

    result = await db.iot_data.delete_many({
        "user_id": str(current_user["_id"]),
        "timestamp": {"$lt": before}
    })

    return {
        "message": f"Deleted {result.deleted_count} records older than {days} days"
    }
