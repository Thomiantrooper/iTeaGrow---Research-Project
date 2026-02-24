from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.database import mongodb
from app.models.schemas import PredictionResponse
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/hectare/{hectare_id}", response_model=List[PredictionResponse])
async def get_hectare_data(
    hectare_id: int,
    limit: int = Query(100, ge=1, le=1000)
):
    """
    Get all predictions for a specific hectare
    """
    try:
        results = list(
            mongodb.predictions.find(
                {"hectare_id": hectare_id},
                {"_id": 0}
            ).sort("timestamp", -1).limit(limit)
        )
        
        if not results:
            logger.info(f"No data found for hectare {hectare_id}")
            return []
        
        logger.info(f"Retrieved {len(results)} records for hectare {hectare_id}")
        return results
        
    except Exception as e:
        logger.error(f"Error fetching hectare data: {e}")
        raise HTTPException(status_code=500, detail="Database error")

@router.get("/farm/latest", response_model=List[PredictionResponse])
async def get_latest_predictions(
    limit: int = Query(25, ge=1, le=100)
):
    """
    Get the latest predictions from all hectares
    """
    try:
        results = list(
            mongodb.predictions.find({}, {"_id": 0})
            .sort("timestamp", -1)
            .limit(limit)
        )
        
        logger.info(f"Retrieved {len(results)} latest records")
        return results
        
    except Exception as e:
        logger.error(f"Error fetching latest predictions: {e}")
        raise HTTPException(status_code=500, detail="Database error")

@router.get("/health")
async def health_check():
    """
    Health check endpoint
    """
    return {
        "status": "healthy",
        "database": "connected" if mongodb.client else "disconnected",
        "mqtt": "running" if hasattr(mqtt_client, 'is_running') and mqtt_client.is_running else "stopped"
    }