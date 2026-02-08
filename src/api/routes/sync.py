"""
Sync and storage API routes.
"""

from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, Query, BackgroundTasks

from src.core.logging import get_logger
from src.api.schemas import SyncStatusResponse, ErrorResponse
from src.services.sync import LocalStorageManager, CloudSyncManager, SyncQueueManager

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1/sync", tags=["Sync"])

local_storage: Optional[LocalStorageManager] = None
cloud_sync: Optional[CloudSyncManager] = None
queue_manager: Optional[SyncQueueManager] = None


def get_local_storage() -> LocalStorageManager:
    """Dependency to get local storage instance."""
    global local_storage
    if local_storage is None:
        local_storage = LocalStorageManager()
    return local_storage


def get_cloud_sync() -> CloudSyncManager:
    """Dependency to get cloud sync instance."""
    global cloud_sync
    if cloud_sync is None:
        cloud_sync = CloudSyncManager()
    return cloud_sync


def get_queue_manager() -> SyncQueueManager:
    """Dependency to get queue manager instance."""
    global queue_manager
    if queue_manager is None:
        queue_manager = SyncQueueManager()
    return queue_manager


@router.get(
    "/status",
    response_model=SyncStatusResponse,
)
async def get_sync_status(
    storage: LocalStorageManager = Depends(get_local_storage),
    cloud: CloudSyncManager = Depends(get_cloud_sync),
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """
    Get current synchronization status.

    Returns information about pending uploads, connectivity,
    and storage usage.
    """
    is_online = cloud.check_connection()
    storage_stats = storage.get_storage_stats()
    queue_status = queue.get_status()

    return SyncStatusResponse(
        is_online=is_online,
        last_sync_time=queue_status.last_sync_time,
        pending_uploads=len(storage.get_pending_sync_items()),
        pending_downloads=0,
        failed_items=queue_status.failed_items,
        queue_size=queue_status.queue_size,
        storage_used_mb=storage_stats.get("total_disk_size_mb", 0),
        storage_available_mb=storage_stats.get("disk_free_mb", 0),
    )


@router.post("/trigger")
async def trigger_sync(
    background_tasks: BackgroundTasks,
    max_items: int = Query(50, ge=1, le=500),
    storage: LocalStorageManager = Depends(get_local_storage),
    cloud: CloudSyncManager = Depends(get_cloud_sync),
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """
    Manually trigger synchronization.

    Initiates upload of pending items to cloud storage.
    """
    if not cloud.check_connection():
        raise HTTPException(
            status_code=503,
            detail={
                "error": True,
                "error_code": "CLOUD_UNAVAILABLE",
                "message": "Cloud storage is not accessible",
            },
        )

    pending_items = storage.get_pending_sync_items()

    for item in pending_items[:max_items]:
        queue.enqueue(
            item_type=item["type"],
            action="upload",
            data={"item_id": item["id"], "path": item["path"]},
            priority=0,
        )

    background_tasks.add_task(_process_sync_queue, queue, storage, cloud)

    return {
        "success": True,
        "message": f"Queued {min(len(pending_items), max_items)} items for sync",
        "pending_total": len(pending_items),
    }


async def _process_sync_queue(
    queue: SyncQueueManager,
    storage: LocalStorageManager,
    cloud: CloudSyncManager,
):
    """Background task to process sync queue."""
    processed = queue.process_queue(max_items=50)
    logger.info(f"Processed {processed} sync items")


@router.get("/pending")
async def get_pending_items(
    limit: int = Query(100, ge=1, le=1000),
    storage: LocalStorageManager = Depends(get_local_storage),
):
    """Get list of items pending synchronization."""
    pending = storage.get_pending_sync_items()

    return {
        "total": len(pending),
        "items": pending[:limit],
    }


@router.get("/failed")
async def get_failed_items(
    limit: int = Query(100, ge=1, le=1000),
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """Get list of failed sync items."""
    failed = queue.get_failed_items(limit)

    return {
        "total": len(failed),
        "items": failed,
    }


@router.post("/retry")
async def retry_failed_items(
    item_id: Optional[str] = Query(None, description="Specific item to retry, or all if not specified"),
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """Retry failed sync items."""
    requeued = queue.retry_failed(item_id)

    return {
        "success": True,
        "requeued_count": requeued,
    }


@router.delete("/failed")
async def clear_failed_items(
    queue: SyncQueueManager = Depends(get_queue_manager),
):
    """Clear all failed sync items."""
    cleared = queue.clear_failed()

    return {
        "success": True,
        "cleared_count": cleared,
    }


@router.get("/storage-stats")
async def get_storage_statistics(
    storage: LocalStorageManager = Depends(get_local_storage),
):
    """Get detailed storage statistics."""
    return storage.get_storage_stats()


@router.post("/cleanup")
async def cleanup_synced_items(
    older_than_days: int = Query(7, ge=1, le=90),
    storage: LocalStorageManager = Depends(get_local_storage),
):
    """
    Clean up synced items older than specified days.

    Only removes items that have been successfully synced to cloud.
    """
    removed = storage.cleanup_synced_items(older_than_days)

    return {
        "success": True,
        "removed_count": removed,
    }


@router.get("/cloud-status")
async def get_cloud_status(
    cloud: CloudSyncManager = Depends(get_cloud_sync),
):
    """Get cloud storage connection status."""
    return cloud.get_sync_status()


@router.post("/ensure-buckets")
async def ensure_cloud_buckets(
    cloud: CloudSyncManager = Depends(get_cloud_sync),
):
    """Ensure required cloud storage buckets exist."""
    success = cloud.ensure_buckets()

    if not success:
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "BUCKET_CREATION_FAILED",
                "message": "Failed to create cloud storage buckets",
            },
        )

    return {
        "success": True,
        "message": "All required buckets are ready",
    }


@router.get("/models")
async def list_available_models(
    cloud: CloudSyncManager = Depends(get_cloud_sync),
):
    """List models available in cloud storage."""
    models = cloud.list_available_models()

    return {
        "models": models,
    }


@router.post("/download-model")
async def download_model(
    model_name: str = Query(..., description="Model filename to download"),
    local_path: str = Query(..., description="Local path to save model"),
    cloud: CloudSyncManager = Depends(get_cloud_sync),
):
    """Download a model from cloud storage."""
    try:
        cloud.download_model(model_name, local_path)
        return {
            "success": True,
            "message": f"Model downloaded to {local_path}",
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "error": True,
                "error_code": "DOWNLOAD_FAILED",
                "message": str(e),
            },
        )


@router.get("/check-model-update")
async def check_model_update(
    model_name: str = Query(...),
    local_checksum: str = Query(..., description="MD5 checksum of local model"),
    cloud: CloudSyncManager = Depends(get_cloud_sync),
):
    """Check if a newer model version is available in cloud storage."""
    result = cloud.check_model_version(model_name, local_checksum)

    return result
