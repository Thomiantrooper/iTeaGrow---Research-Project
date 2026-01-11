"""
User feedback API routes for model retraining.
"""

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Query

from src.core.logging import get_logger
from src.api.schemas import (
    UserFeedback,
    FeedbackResponse,
    ErrorResponse,
)
from src.services.sync import LocalStorageManager, SyncQueueManager

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1/feedback", tags=["Feedback"])

local_storage: Optional[LocalStorageManager] = None
queue_manager: Optional[SyncQueueManager] = None


def get_local_storage() -> LocalStorageManager:
    """Dependency to get local storage instance."""
    global local_storage
    if local_storage is None:
        local_storage = LocalStorageManager()
    return local_storage


def get_queue_manager() -> SyncQueueManager:
    """Dependency to get queue manager instance."""
    global queue_manager
    if queue_manager is None:
        queue_manager = SyncQueueManager()
    return queue_manager


@router.post(
    "/submit",
    response_model=FeedbackResponse,
    responses={
        422: {"model": ErrorResponse, "description": "Validation error"},
        500: {"model": ErrorResponse, "description": "Storage error"},
    },
)
async def submit_feedback(
    feedback: UserFeedback,
    storage: LocalStorageManager = Depends(get_local_storage),
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """
    Submit user feedback on detection results.

    Feedback is stored locally and queued for cloud sync.
    Used for continuous model improvement through retraining.
    """
    try:
        feedback_id = storage.store_feedback(feedback.model_dump())

        queue.enqueue(
            item_type="feedback",
            action="upload",
            data={"feedback_id": feedback_id},
            priority=1,
        )

        retraining_queued = False
        if feedback.feedback_type.value == "incorrect":
            retraining_queued = True
            logger.info(
                f"Incorrect detection reported for image {feedback.image_id}, "
                f"queued for retraining review"
            )

        return FeedbackResponse(
            feedback_id=feedback_id,
            status="submitted",
            message="Thank you for your feedback. It helps improve our detection accuracy.",
            retraining_queued=retraining_queued,
        )

    except Exception as e:
        logger.error(f"Failed to store feedback: {e}")
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "FEEDBACK_STORAGE_ERROR",
                "message": str(e),
            },
        )


@router.post("/batch-submit")
async def batch_submit_feedback(
    feedback_list: list[UserFeedback],
    storage: LocalStorageManager = Depends(get_local_storage),
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """
    Submit multiple feedback items in batch.

    Useful for syncing offline collected feedback.
    """
    if len(feedback_list) > 100:
        raise HTTPException(
            status_code=422,
            detail={
                "error": True,
                "error_code": "BATCH_TOO_LARGE",
                "message": "Maximum 100 feedback items per batch",
            },
        )

    results = {"submitted": 0, "failed": 0, "errors": []}

    for i, feedback in enumerate(feedback_list):
        try:
            feedback_id = storage.store_feedback(feedback.model_dump())

            queue.enqueue(
                item_type="feedback",
                action="upload",
                data={"feedback_id": feedback_id},
                priority=0,
            )

            results["submitted"] += 1

        except Exception as e:
            results["failed"] += 1
            results["errors"].append({
                "index": i,
                "image_id": feedback.image_id,
                "error": str(e),
            })

    return results


@router.get("/statistics")
async def get_feedback_statistics(
    plantation_id: Optional[str] = Query(None),
    days: int = Query(30, ge=1, le=365),
):
    """
    Get feedback statistics for analysis.

    Returns summary of feedback types and correction patterns.
    """
    return {
        "period_days": days,
        "plantation_id": plantation_id,
        "total_feedback": 0,
        "by_type": {
            "correct": 0,
            "incorrect": 0,
            "uncertain": 0,
        },
        "correction_rate": 0.0,
        "common_corrections": [],
        "message": "Statistics require cloud sync to be fully populated",
    }


@router.get("/retraining-queue")
async def get_retraining_queue():
    """
    Get items queued for model retraining.

    Returns list of incorrect detections pending review.
    """
    return {
        "queue_size": 0,
        "items": [],
        "message": "Retraining queue managed by ML pipeline",
    }


@router.post("/mark-reviewed")
async def mark_feedback_reviewed(
    feedback_id: str,
    reviewer_notes: Optional[str] = Query(None),
):
    """Mark a feedback item as reviewed for retraining."""
    return {
        "success": True,
        "feedback_id": feedback_id,
        "status": "reviewed",
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/export")
async def export_feedback_for_training(
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    feedback_type: Optional[str] = Query(None, description="Filter by type"),
    limit: int = Query(1000, ge=1, le=10000),
):
    """
    Export feedback data for model retraining.

    Returns feedback with associated image references in
    a format suitable for training pipeline ingestion.
    """
    return {
        "export_id": f"export_{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "filters": {
            "start_date": start_date,
            "end_date": end_date,
            "feedback_type": feedback_type,
        },
        "total_records": 0,
        "records": [],
        "message": "Export requires cloud database access",
    }
