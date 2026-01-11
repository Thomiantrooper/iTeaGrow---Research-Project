"""
Local storage manager for offline-first operation.
Provides encrypted local storage with automatic compression.
"""

import json
import gzip
import shutil
from pathlib import Path
from datetime import datetime, timezone
from typing import Optional, Any, BinaryIO
import uuid
import hashlib

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import LocalStorageError
from src.core.security import security_manager

logger = get_logger(__name__)


class LocalStorageManager:
    """
    Manages local file storage with encryption and compression support.
    Designed for offline-first operation in remote plantations.
    """

    METADATA_FILE = ".storage_metadata.json"
    INDEX_FILE = ".storage_index.json"

    def __init__(
        self,
        base_path: Optional[str] = None,
        compression_enabled: Optional[bool] = None,
        encryption_enabled: bool = True,
    ):
        """
        Initialize local storage manager.

        Args:
            base_path: Base directory for local storage
            compression_enabled: Enable gzip compression
            encryption_enabled: Enable encryption for sensitive data
        """
        self.base_path = Path(base_path or settings.sync.local_storage_path)
        self.compression_enabled = (
            compression_enabled
            if compression_enabled is not None
            else settings.sync.compression_enabled
        )
        self.encryption_enabled = encryption_enabled and settings.sync.encryption_key

        self._ensure_directories()
        self._load_index()

    def _ensure_directories(self) -> None:
        """Create necessary directory structure."""
        directories = [
            self.base_path,
            self.base_path / "images",
            self.base_path / "detections",
            self.base_path / "iot_data",
            self.base_path / "feedback",
            self.base_path / "pending_sync",
            self.base_path / "cache",
        ]

        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)

        logger.info(f"Local storage initialized at {self.base_path}")

    def _load_index(self) -> None:
        """Load the storage index from disk."""
        index_path = self.base_path / self.INDEX_FILE

        if index_path.exists():
            try:
                with open(index_path, "r") as f:
                    self._index = json.load(f)
            except Exception as e:
                logger.error(f"Failed to load index: {e}")
                self._index = self._create_empty_index()
        else:
            self._index = self._create_empty_index()

    def _create_empty_index(self) -> dict:
        """Create an empty storage index."""
        return {
            "created_at": datetime.now(timezone.utc).isoformat(),
            "last_modified": datetime.now(timezone.utc).isoformat(),
            "items": {},
            "pending_sync": [],
            "statistics": {
                "total_items": 0,
                "total_size_bytes": 0,
                "images_count": 0,
                "detections_count": 0,
                "iot_readings_count": 0,
            },
        }

    def _save_index(self) -> None:
        """Save the storage index to disk."""
        self._index["last_modified"] = datetime.now(timezone.utc).isoformat()
        index_path = self.base_path / self.INDEX_FILE

        try:
            with open(index_path, "w") as f:
                json.dump(self._index, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save index: {e}")

    def store_image(
        self,
        image_bytes: bytes,
        image_id: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> str:
        """
        Store an image locally.

        Args:
            image_bytes: Raw image bytes
            image_id: Optional image identifier
            metadata: Optional metadata to store with image

        Returns:
            Image ID for retrieval
        """
        image_id = image_id or str(uuid.uuid4())

        checksum = hashlib.sha256(image_bytes).hexdigest()

        if self.compression_enabled:
            data = gzip.compress(image_bytes)
            extension = ".jpg.gz"
        else:
            data = image_bytes
            extension = ".jpg"

        if self.encryption_enabled:
            try:
                data = security_manager.encrypt_data(data)
                extension += ".enc"
            except Exception as e:
                logger.warning(f"Encryption failed, storing unencrypted: {e}")

        file_path = self.base_path / "images" / f"{image_id}{extension}"

        try:
            with open(file_path, "wb") as f:
                f.write(data)
        except Exception as e:
            raise LocalStorageError(f"Failed to store image: {e}", path=str(file_path))

        self._index["items"][image_id] = {
            "type": "image",
            "path": str(file_path.relative_to(self.base_path)),
            "checksum": checksum,
            "size_bytes": len(data),
            "original_size_bytes": len(image_bytes),
            "compressed": self.compression_enabled,
            "encrypted": self.encryption_enabled,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "metadata": metadata or {},
            "sync_status": "pending",
        }

        self._index["pending_sync"].append(image_id)
        self._index["statistics"]["total_items"] += 1
        self._index["statistics"]["total_size_bytes"] += len(data)
        self._index["statistics"]["images_count"] += 1

        self._save_index()

        logger.info(f"Stored image {image_id} ({len(data)} bytes)")

        return image_id

    def retrieve_image(self, image_id: str) -> Optional[bytes]:
        """
        Retrieve an image from local storage.

        Args:
            image_id: Image identifier

        Returns:
            Image bytes or None if not found
        """
        if image_id not in self._index["items"]:
            return None

        item = self._index["items"][image_id]
        file_path = self.base_path / item["path"]

        if not file_path.exists():
            logger.error(f"Image file not found: {file_path}")
            return None

        try:
            with open(file_path, "rb") as f:
                data = f.read()

            if item.get("encrypted"):
                data = security_manager.decrypt_data(data)

            if item.get("compressed"):
                data = gzip.decompress(data)

            return data

        except Exception as e:
            logger.error(f"Failed to retrieve image {image_id}: {e}")
            return None

    def store_detection_result(
        self,
        detection_data: dict,
        image_id: str,
    ) -> str:
        """
        Store detection results locally.

        Args:
            detection_data: Detection result dictionary
            image_id: Associated image ID

        Returns:
            Detection result ID
        """
        result_id = f"det_{image_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"

        data = json.dumps(detection_data, default=str).encode("utf-8")

        if self.compression_enabled:
            data = gzip.compress(data)

        file_path = self.base_path / "detections" / f"{result_id}.json"
        if self.compression_enabled:
            file_path = file_path.with_suffix(".json.gz")

        try:
            with open(file_path, "wb") as f:
                f.write(data)
        except Exception as e:
            raise LocalStorageError(
                f"Failed to store detection: {e}", path=str(file_path)
            )

        self._index["items"][result_id] = {
            "type": "detection",
            "path": str(file_path.relative_to(self.base_path)),
            "image_id": image_id,
            "size_bytes": len(data),
            "compressed": self.compression_enabled,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "sync_status": "pending",
        }

        self._index["pending_sync"].append(result_id)
        self._index["statistics"]["detections_count"] += 1

        self._save_index()

        return result_id

    def store_iot_reading(
        self,
        reading_data: dict,
        device_id: str,
    ) -> str:
        """
        Store IoT sensor reading locally.

        Args:
            reading_data: IoT reading dictionary
            device_id: Device identifier

        Returns:
            Reading ID
        """
        reading_id = f"iot_{device_id}_{datetime.now().strftime('%Y%m%d%H%M%S%f')}"

        data = json.dumps(reading_data, default=str).encode("utf-8")

        file_path = self.base_path / "iot_data" / device_id
        file_path.mkdir(parents=True, exist_ok=True)

        daily_file = file_path / f"{datetime.now().strftime('%Y%m%d')}.jsonl"

        try:
            with open(daily_file, "ab") as f:
                f.write(data + b"\n")
        except Exception as e:
            raise LocalStorageError(
                f"Failed to store IoT reading: {e}", path=str(daily_file)
            )

        if reading_id not in self._index["items"]:
            self._index["statistics"]["iot_readings_count"] += 1

        return reading_id

    def store_feedback(
        self,
        feedback_data: dict,
    ) -> str:
        """
        Store user feedback locally.

        Args:
            feedback_data: Feedback dictionary

        Returns:
            Feedback ID
        """
        feedback_id = feedback_data.get("feedback_id", str(uuid.uuid4()))

        data = json.dumps(feedback_data, default=str).encode("utf-8")

        file_path = self.base_path / "feedback" / f"{feedback_id}.json"

        try:
            with open(file_path, "wb") as f:
                f.write(data)
        except Exception as e:
            raise LocalStorageError(
                f"Failed to store feedback: {e}", path=str(file_path)
            )

        self._index["items"][feedback_id] = {
            "type": "feedback",
            "path": str(file_path.relative_to(self.base_path)),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "sync_status": "pending",
        }

        self._index["pending_sync"].append(feedback_id)
        self._save_index()

        return feedback_id

    def get_pending_sync_items(self) -> list[dict]:
        """Get all items pending synchronization."""
        pending = []
        for item_id in self._index.get("pending_sync", []):
            if item_id in self._index["items"]:
                item = self._index["items"][item_id].copy()
                item["id"] = item_id
                pending.append(item)
        return pending

    def mark_synced(self, item_id: str) -> None:
        """Mark an item as successfully synced."""
        if item_id in self._index["items"]:
            self._index["items"][item_id]["sync_status"] = "synced"
            self._index["items"][item_id]["synced_at"] = (
                datetime.now(timezone.utc).isoformat()
            )

        if item_id in self._index["pending_sync"]:
            self._index["pending_sync"].remove(item_id)

        self._save_index()

    def get_storage_stats(self) -> dict:
        """Get storage statistics."""
        stats = self._index["statistics"].copy()

        total_size = sum(
            f.stat().st_size for f in self.base_path.rglob("*") if f.is_file()
        )

        stats["total_disk_size_bytes"] = total_size
        stats["total_disk_size_mb"] = total_size / (1024 * 1024)
        stats["pending_sync_count"] = len(self._index.get("pending_sync", []))

        try:
            disk_usage = shutil.disk_usage(self.base_path)
            stats["disk_free_mb"] = disk_usage.free / (1024 * 1024)
            stats["disk_total_mb"] = disk_usage.total / (1024 * 1024)
            stats["disk_used_percent"] = (
                (disk_usage.used / disk_usage.total) * 100
            )
        except Exception:
            pass

        return stats

    def cleanup_synced_items(self, older_than_days: int = 7) -> int:
        """
        Remove synced items older than specified days.

        Args:
            older_than_days: Age threshold in days

        Returns:
            Number of items removed
        """
        cutoff = datetime.now(timezone.utc).timestamp() - (older_than_days * 86400)
        removed = 0

        items_to_remove = []

        for item_id, item in self._index["items"].items():
            if item.get("sync_status") != "synced":
                continue

            synced_at = item.get("synced_at")
            if not synced_at:
                continue

            try:
                synced_time = datetime.fromisoformat(
                    synced_at.replace("Z", "+00:00")
                ).timestamp()

                if synced_time < cutoff:
                    items_to_remove.append(item_id)
            except Exception:
                continue

        for item_id in items_to_remove:
            item = self._index["items"][item_id]
            file_path = self.base_path / item["path"]

            try:
                if file_path.exists():
                    file_path.unlink()
                del self._index["items"][item_id]
                removed += 1
            except Exception as e:
                logger.error(f"Failed to remove item {item_id}: {e}")

        if removed > 0:
            self._save_index()
            logger.info(f"Cleaned up {removed} synced items")

        return removed

    def export_for_sync(self, item_id: str) -> Optional[dict]:
        """
        Prepare an item for cloud sync.

        Args:
            item_id: Item identifier

        Returns:
            Dictionary with item data and metadata for sync
        """
        if item_id not in self._index["items"]:
            return None

        item = self._index["items"][item_id]

        export_data = {
            "id": item_id,
            "type": item["type"],
            "metadata": item.get("metadata", {}),
            "created_at": item["created_at"],
        }

        file_path = self.base_path / item["path"]

        if file_path.exists():
            with open(file_path, "rb") as f:
                export_data["data"] = f.read()
            export_data["checksum"] = item.get("checksum")

        return export_data
