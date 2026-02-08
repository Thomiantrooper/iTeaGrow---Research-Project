"""
Sync queue manager for reliable offline-first synchronization.
Uses Redis for queue persistence when available, falls back to local storage.
"""

import json
import time
from datetime import datetime, timezone
from typing import Optional, Callable
from threading import Thread, Event
import uuid

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import SyncError
from src.api.schemas import SyncQueueItem, SyncStatus, SyncStatusResponse

logger = get_logger(__name__)


class SyncQueueManager:
    """
    Manages synchronization queue with retry logic and priority handling.
    Supports both Redis and local file-based queuing.
    """

    QUEUE_KEY = "tealeaf:sync:queue"
    PROCESSING_KEY = "tealeaf:sync:processing"
    FAILED_KEY = "tealeaf:sync:failed"

    def __init__(
        self,
        redis_url: Optional[str] = None,
        max_queue_size: Optional[int] = None,
        max_retries: int = 5,
        retry_delay_seconds: int = 60,
    ):
        """
        Initialize the sync queue manager.

        Args:
            redis_url: Redis connection URL
            max_queue_size: Maximum queue size
            max_retries: Maximum retry attempts
            retry_delay_seconds: Delay between retries
        """
        self.redis_url = redis_url or settings.redis.url
        self.max_queue_size = max_queue_size or settings.sync.max_queue_size
        self.max_retries = max_retries
        self.retry_delay_seconds = retry_delay_seconds

        self._redis_client = None
        self._use_redis = False
        self._local_queue: list[dict] = []
        self._processing: dict[str, dict] = {}
        self._failed: list[dict] = []

        self._sync_thread: Optional[Thread] = None
        self._stop_event = Event()
        self._sync_handlers: dict[str, Callable] = {}

        self._init_redis()

    def _init_redis(self) -> None:
        """Initialize Redis connection."""
        try:
            import redis

            self._redis_client = redis.from_url(
                self.redis_url,
                decode_responses=True,
            )
            self._redis_client.ping()
            self._use_redis = True
            logger.info("Connected to Redis for sync queue")
        except ImportError:
            logger.info("redis package not installed, using local queue")
            self._use_redis = False
        except Exception as e:
            logger.warning(f"Redis not available, using local queue: {e}")
            self._use_redis = False

    def enqueue(
        self,
        item_type: str,
        action: str,
        data: dict,
        priority: int = 0,
    ) -> str:
        """
        Add an item to the sync queue.

        Args:
            item_type: Type of item (image, detection, feedback, iot)
            action: Action to perform (upload, update, delete)
            data: Item data
            priority: Queue priority (higher = more urgent)

        Returns:
            Queue item ID
        """
        item_id = str(uuid.uuid4())

        queue_item = {
            "item_id": item_id,
            "item_type": item_type,
            "action": action,
            "data": data,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "priority": priority,
            "retry_count": 0,
            "max_retries": self.max_retries,
            "status": SyncStatus.PENDING.value,
            "error_message": None,
        }

        if self._use_redis:
            self._redis_enqueue(queue_item)
        else:
            self._local_enqueue(queue_item)

        logger.debug(f"Enqueued sync item {item_id}: {item_type}/{action}")

        return item_id

    def _redis_enqueue(self, item: dict) -> None:
        """Enqueue item using Redis."""
        score = -item["priority"] * 1000000 + time.time()
        self._redis_client.zadd(
            self.QUEUE_KEY,
            {json.dumps(item): score},
        )

    def _local_enqueue(self, item: dict) -> None:
        """Enqueue item using local list."""
        self._local_queue.append(item)
        self._local_queue.sort(key=lambda x: (-x["priority"], x["created_at"]))

        if len(self._local_queue) > self.max_queue_size:
            self._local_queue = self._local_queue[:self.max_queue_size]

    def dequeue(self) -> Optional[SyncQueueItem]:
        """
        Remove and return the highest priority item from the queue.

        Returns:
            SyncQueueItem or None if queue is empty
        """
        if self._use_redis:
            item_data = self._redis_dequeue()
        else:
            item_data = self._local_dequeue()

        if item_data is None:
            return None

        item_data["status"] = SyncStatus.SYNCING.value
        self._processing[item_data["item_id"]] = item_data

        return SyncQueueItem(**item_data)

    def _redis_dequeue(self) -> Optional[dict]:
        """Dequeue item using Redis."""
        items = self._redis_client.zrange(self.QUEUE_KEY, 0, 0)
        if not items:
            return None

        item_json = items[0]
        self._redis_client.zrem(self.QUEUE_KEY, item_json)
        self._redis_client.hset(
            self.PROCESSING_KEY,
            json.loads(item_json)["item_id"],
            item_json,
        )

        return json.loads(item_json)

    def _local_dequeue(self) -> Optional[dict]:
        """Dequeue item using local list."""
        if not self._local_queue:
            return None

        return self._local_queue.pop(0)

    def complete(self, item_id: str) -> None:
        """Mark an item as successfully synced."""
        if item_id in self._processing:
            del self._processing[item_id]

        if self._use_redis:
            self._redis_client.hdel(self.PROCESSING_KEY, item_id)

        logger.debug(f"Completed sync item {item_id}")

    def fail(self, item_id: str, error_message: str) -> None:
        """
        Mark an item as failed and handle retry logic.

        Args:
            item_id: Item identifier
            error_message: Error description
        """
        if item_id not in self._processing:
            return

        item = self._processing[item_id]
        item["retry_count"] += 1
        item["error_message"] = error_message
        item["last_attempt"] = datetime.now(timezone.utc).isoformat()

        if item["retry_count"] < item["max_retries"]:
            item["status"] = SyncStatus.PENDING.value
            item["priority"] -= 1

            if self._use_redis:
                self._redis_enqueue(item)
            else:
                self._local_enqueue(item)

            logger.warning(
                f"Retry {item['retry_count']}/{item['max_retries']} for {item_id}: {error_message}"
            )
        else:
            item["status"] = SyncStatus.FAILED.value
            self._failed.append(item)

            if self._use_redis:
                self._redis_client.hset(
                    self.FAILED_KEY,
                    item_id,
                    json.dumps(item),
                )

            logger.error(
                f"Sync item {item_id} permanently failed after {item['retry_count']} attempts"
            )

        del self._processing[item_id]

        if self._use_redis:
            self._redis_client.hdel(self.PROCESSING_KEY, item_id)

    def register_handler(
        self,
        item_type: str,
        handler: Callable[[SyncQueueItem], bool],
    ) -> None:
        """
        Register a sync handler for an item type.

        Args:
            item_type: Type of items to handle
            handler: Callable that processes the item and returns success status
        """
        self._sync_handlers[item_type] = handler
        logger.info(f"Registered sync handler for {item_type}")

    def start_background_sync(
        self,
        interval_seconds: Optional[int] = None,
    ) -> None:
        """
        Start background sync processing.

        Args:
            interval_seconds: Sync interval in seconds
        """
        if self._sync_thread is not None and self._sync_thread.is_alive():
            logger.warning("Background sync already running")
            return

        interval = interval_seconds or settings.sync.sync_interval
        self._stop_event.clear()

        self._sync_thread = Thread(
            target=self._sync_loop,
            args=(interval,),
            daemon=True,
            name="SyncQueueWorker",
        )
        self._sync_thread.start()
        logger.info(f"Started background sync with {interval}s interval")

    def stop_background_sync(self) -> None:
        """Stop background sync processing."""
        self._stop_event.set()
        if self._sync_thread is not None:
            self._sync_thread.join(timeout=10)
            self._sync_thread = None
        logger.info("Stopped background sync")

    def _sync_loop(self, interval: int) -> None:
        """Background sync processing loop."""
        while not self._stop_event.is_set():
            try:
                self.process_queue()
            except Exception as e:
                logger.error(f"Error in sync loop: {e}")

            self._stop_event.wait(interval)

    def process_queue(self, max_items: int = 10) -> int:
        """
        Process items in the sync queue.

        Args:
            max_items: Maximum items to process in one batch

        Returns:
            Number of items processed
        """
        processed = 0

        for _ in range(max_items):
            item = self.dequeue()
            if item is None:
                break

            handler = self._sync_handlers.get(item.item_type)
            if handler is None:
                logger.warning(f"No handler for item type: {item.item_type}")
                self.fail(item.item_id, f"No handler for type: {item.item_type}")
                continue

            try:
                success = handler(item)
                if success:
                    self.complete(item.item_id)
                    processed += 1
                else:
                    self.fail(item.item_id, "Handler returned False")
            except Exception as e:
                self.fail(item.item_id, str(e))

        return processed

    def get_status(self) -> SyncStatusResponse:
        """Get current sync queue status."""
        if self._use_redis:
            pending = self._redis_client.zcard(self.QUEUE_KEY)
            failed = self._redis_client.hlen(self.FAILED_KEY)
        else:
            pending = len(self._local_queue)
            failed = len(self._failed)

        processing = len(self._processing)

        return SyncStatusResponse(
            is_online=self._use_redis,
            last_sync_time=datetime.now(timezone.utc),
            pending_uploads=pending,
            pending_downloads=0,
            failed_items=failed,
            queue_size=pending + processing,
            storage_used_mb=0.0,
            storage_available_mb=0.0,
        )

    def get_failed_items(self, limit: int = 100) -> list[dict]:
        """Get list of failed sync items."""
        if self._use_redis:
            items = self._redis_client.hgetall(self.FAILED_KEY)
            return [json.loads(v) for v in list(items.values())[:limit]]
        else:
            return self._failed[:limit]

    def retry_failed(self, item_id: Optional[str] = None) -> int:
        """
        Retry failed items.

        Args:
            item_id: Specific item to retry, or None for all failed items

        Returns:
            Number of items requeued
        """
        requeued = 0

        if self._use_redis:
            if item_id:
                item_json = self._redis_client.hget(self.FAILED_KEY, item_id)
                if item_json:
                    item = json.loads(item_json)
                    item["retry_count"] = 0
                    item["status"] = SyncStatus.PENDING.value
                    self._redis_enqueue(item)
                    self._redis_client.hdel(self.FAILED_KEY, item_id)
                    requeued = 1
            else:
                items = self._redis_client.hgetall(self.FAILED_KEY)
                for iid, item_json in items.items():
                    item = json.loads(item_json)
                    item["retry_count"] = 0
                    item["status"] = SyncStatus.PENDING.value
                    self._redis_enqueue(item)
                    self._redis_client.hdel(self.FAILED_KEY, iid)
                    requeued += 1
        else:
            if item_id:
                for i, item in enumerate(self._failed):
                    if item["item_id"] == item_id:
                        item["retry_count"] = 0
                        item["status"] = SyncStatus.PENDING.value
                        self._local_enqueue(item)
                        self._failed.pop(i)
                        requeued = 1
                        break
            else:
                for item in self._failed:
                    item["retry_count"] = 0
                    item["status"] = SyncStatus.PENDING.value
                    self._local_enqueue(item)
                requeued = len(self._failed)
                self._failed.clear()

        logger.info(f"Requeued {requeued} failed items for retry")
        return requeued

    def clear_failed(self) -> int:
        """Clear all failed items."""
        if self._use_redis:
            count = self._redis_client.hlen(self.FAILED_KEY)
            self._redis_client.delete(self.FAILED_KEY)
        else:
            count = len(self._failed)
            self._failed.clear()

        logger.info(f"Cleared {count} failed items")
        return count
