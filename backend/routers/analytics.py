"""
Analytics API Routes for admin dashboard statistics and charts.
Provides real-time analytics from MongoDB for disease trends, user stats, and device monitoring.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from datetime import datetime, timedelta
from typing import Optional
from database import get_database
from auth import get_current_active_user

router = APIRouter(prefix="/api/analytics", tags=["analytics"])


def require_admin_or_manager(current_user: dict = Depends(get_current_active_user)):
    """Dependency to check if user is admin or manager."""
    if current_user.get("role") not in ("admin", "manager"):
        raise HTTPException(status_code=403, detail="Admin or Manager access required")
    return current_user


@router.get("/overview")
async def get_analytics_overview(
    current_user: dict = Depends(require_admin_or_manager)
):
    """Get system-wide analytics overview for dashboard cards."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    total_users = await db.users.count_documents({})
    active_users = await db.users.count_documents({"is_active": True})
    total_scans = await db.disease_detections.count_documents({})
    total_devices = await db.bluetooth_devices.count_documents({"is_active": True})
    total_iot_readings = await db.iot_data.count_documents({})

    # Disease breakdown
    disease_pipeline = [
        {"$group": {"_id": "$disease_name", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}
    ]
    disease_cursor = db.disease_detections.aggregate(disease_pipeline)
    disease_counts = {}
    healthy_count = 0
    async for doc in disease_cursor:
        disease_counts[doc["_id"]] = doc["count"]
        if doc["_id"] == "Healthy":
            healthy_count = doc["count"]

    infected_count = total_scans - healthy_count

    # Scans in last 7 days
    week_ago = datetime.utcnow() - timedelta(days=7)
    recent_scans = await db.disease_detections.count_documents(
        {"created_at": {"$gte": week_ago}}
    )

    # Scans in last 30 days
    month_ago = datetime.utcnow() - timedelta(days=30)
    monthly_scans = await db.disease_detections.count_documents(
        {"created_at": {"$gte": month_ago}}
    )

    return {
        "total_users": total_users,
        "active_users": active_users,
        "total_scans": total_scans,
        "healthy_count": healthy_count,
        "infected_count": infected_count,
        "health_rate": round((healthy_count / total_scans * 100), 1) if total_scans > 0 else 0,
        "total_devices": total_devices,
        "total_iot_readings": total_iot_readings,
        "recent_scans_7d": recent_scans,
        "monthly_scans_30d": monthly_scans,
        "disease_counts": disease_counts,
    }


@router.get("/disease-trends")
async def get_disease_trends(
    days: int = Query(90, ge=7, le=365),
    interval: str = Query("daily", regex="^(daily|weekly|monthly)$"),
    current_user: dict = Depends(require_admin_or_manager)
):
    """Get disease detection trends over time for line/bar charts."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    cutoff = datetime.utcnow() - timedelta(days=days)

    if interval == "daily":
        date_format = "%Y-%m-%d"
    elif interval == "weekly":
        date_format = "%Y-W%V"
    else:
        date_format = "%Y-%m"

    pipeline = [
        {"$match": {"created_at": {"$gte": cutoff}}},
        {
            "$group": {
                "_id": {
                    "period": {"$dateToString": {"format": date_format, "date": "$created_at"}},
                    "disease": "$disease_name"
                },
                "count": {"$sum": 1}
            }
        },
        {"$sort": {"_id.period": 1}}
    ]

    cursor = db.disease_detections.aggregate(pipeline)

    # Organize by period
    trends = {}
    async for doc in cursor:
        period = doc["_id"]["period"]
        disease = doc["_id"]["disease"]
        if period not in trends:
            trends[period] = {"period": period, "total": 0}
        trends[period][disease] = doc["count"]
        trends[period]["total"] += doc["count"]

    return {
        "interval": interval,
        "days": days,
        "trends": list(trends.values())
    }


@router.get("/disease-distribution")
async def get_disease_distribution(
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(require_admin_or_manager)
):
    """Get disease distribution for pie chart."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    cutoff = datetime.utcnow() - timedelta(days=days)

    pipeline = [
        {"$match": {"created_at": {"$gte": cutoff}}},
        {
            "$group": {
                "_id": "$disease_name",
                "count": {"$sum": 1},
                "avg_confidence": {"$avg": "$confidence"}
            }
        },
        {"$sort": {"count": -1}}
    ]

    cursor = db.disease_detections.aggregate(pipeline)
    distribution = []
    total = 0
    async for doc in cursor:
        distribution.append({
            "disease_name": doc["_id"],
            "count": doc["count"],
            "avg_confidence": round(doc["avg_confidence"], 2) if doc["avg_confidence"] else 0,
        })
        total += doc["count"]

    # Add percentage
    for item in distribution:
        item["percentage"] = round((item["count"] / total * 100), 1) if total > 0 else 0

    return {"period_days": days, "total": total, "distribution": distribution}


@router.get("/recovery-tracking")
async def get_recovery_tracking(
    days: int = Query(90, ge=7, le=365),
    current_user: dict = Depends(require_admin_or_manager)
):
    """Track disease recovery based on follow-up scans per user."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    cutoff = datetime.utcnow() - timedelta(days=days)

    # Find users who had infected scans followed by healthy scans
    pipeline = [
        {"$match": {"created_at": {"$gte": cutoff}}},
        {"$sort": {"created_at": 1}},
        {
            "$group": {
                "_id": "$user_id",
                "scans": {
                    "$push": {
                        "disease": "$disease_name",
                        "date": "$created_at",
                        "confidence": "$confidence"
                    }
                },
                "total_scans": {"$sum": 1},
                "healthy_scans": {
                    "$sum": {"$cond": [{"$eq": ["$disease_name", "Healthy"]}, 1, 0]}
                },
                "infected_scans": {
                    "$sum": {"$cond": [{"$ne": ["$disease_name", "Healthy"]}, 1, 0]}
                }
            }
        },
        {"$match": {"total_scans": {"$gte": 2}}}
    ]

    cursor = db.disease_detections.aggregate(pipeline)

    recovered = 0
    still_infected = 0
    improving = 0

    async for doc in cursor:
        scans = doc["scans"]
        if len(scans) < 2:
            continue

        last_scan = scans[-1]
        first_infected = next((s for s in scans if s["disease"] != "Healthy"), None)

        if first_infected and last_scan["disease"] == "Healthy":
            recovered += 1
        elif first_infected and last_scan["disease"] != "Healthy":
            # Check if confidence is decreasing (improving)
            infected_scans = [s for s in scans if s["disease"] != "Healthy"]
            if len(infected_scans) >= 2 and infected_scans[-1]["confidence"] < infected_scans[0]["confidence"]:
                improving += 1
            else:
                still_infected += 1

    total_tracked = recovered + still_infected + improving

    return {
        "period_days": days,
        "total_tracked_users": total_tracked,
        "recovered": recovered,
        "improving": improving,
        "still_infected": still_infected,
        "recovery_rate": round((recovered / total_tracked * 100), 1) if total_tracked > 0 else 0,
    }


@router.get("/user-stats")
async def get_user_statistics(
    current_user: dict = Depends(require_admin_or_manager)
):
    """Get user activity statistics."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    # Users by role
    role_pipeline = [
        {"$group": {"_id": "$role", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}
    ]
    role_cursor = db.users.aggregate(role_pipeline)
    users_by_role = {}
    async for doc in role_cursor:
        users_by_role[doc["_id"] or "farmer"] = doc["count"]

    # Top scanners
    scanner_pipeline = [
        {"$group": {"_id": "$user_id", "scan_count": {"$sum": 1}}},
        {"$sort": {"scan_count": -1}},
        {"$limit": 10}
    ]
    scanner_cursor = db.disease_detections.aggregate(scanner_pipeline)
    top_scanners = []
    async for doc in scanner_cursor:
        # Fetch user info
        from bson import ObjectId
        user = None
        try:
            user = await db.users.find_one({"_id": ObjectId(doc["_id"])})
        except Exception:
            pass
        top_scanners.append({
            "user_id": doc["_id"],
            "username": user["username"] if user else "Unknown",
            "full_name": user["full_name"] if user else "Unknown",
            "scan_count": doc["scan_count"]
        })

    # Recent registrations (last 30 days)
    month_ago = datetime.utcnow() - timedelta(days=30)
    new_users = await db.users.count_documents({"created_at": {"$gte": month_ago}})

    return {
        "users_by_role": users_by_role,
        "top_scanners": top_scanners,
        "new_users_30d": new_users,
    }


@router.get("/yearly-analysis")
async def get_yearly_analysis(
    year: Optional[int] = None,
    current_user: dict = Depends(require_admin_or_manager)
):
    """Get yearly disease analysis with monthly breakdown."""
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database not available")

    target_year = year or datetime.utcnow().year
    start = datetime(target_year, 1, 1)
    end = datetime(target_year, 12, 31, 23, 59, 59)

    pipeline = [
        {"$match": {"created_at": {"$gte": start, "$lte": end}}},
        {
            "$group": {
                "_id": {
                    "month": {"$month": "$created_at"},
                    "disease": "$disease_name"
                },
                "count": {"$sum": 1},
                "avg_confidence": {"$avg": "$confidence"}
            }
        },
        {"$sort": {"_id.month": 1}}
    ]

    cursor = db.disease_detections.aggregate(pipeline)

    # Organize by month
    months = {i: {"month": i, "total": 0} for i in range(1, 13)}
    async for doc in cursor:
        month = doc["_id"]["month"]
        disease = doc["_id"]["disease"]
        months[month][disease] = doc["count"]
        months[month]["total"] += doc["count"]

    return {
        "year": target_year,
        "monthly_data": list(months.values())
    }
