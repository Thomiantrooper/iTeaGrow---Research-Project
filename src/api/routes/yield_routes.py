"""
Yield Prediction Record API routes.
"""

from datetime import datetime, timezone
from typing import Dict, Any

from fastapi import APIRouter, HTTPException, Depends, Body
from src.services.database.mongo_db import get_database
from src.api.routes.users import get_current_user_id
from src.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1/yield", tags=["Yield Prediction"])

@router.post("/records")
async def save_yield_record(
    record_data: Dict[str, Any] = Body(...),
    user_id: str = Depends(get_current_user_id)
):
    """
    Save yield prediction record to tea_yield_mobile collection.
    
    Stores the full request and response payload from the yield prediction service,
    along with user metadata.
    """
    try:
        db = get_database()
        collection = db.tea_yield_mobile
        
        # Enrich with metadata
        document = {
            "user_id": user_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
            **record_data
        }
        
        result = await collection.insert_one(document)
        
        logger.info(f"Saved yield prediction record for user {user_id}: {result.inserted_id}")
        
        return {
            "success": True, 
            "id": str(result.inserted_id),
            "message": "Yield prediction saved successfully"
        }
    except Exception as e:
        logger.error(f"Failed to save yield record: {e}")
        raise HTTPException(status_code=500, detail="Failed to save yield record")
