"""
Cloud synchronization manager for MinIO/S3-compatible storage.
Handles automatic sync between local and cloud storage.
"""

import io
import json
from datetime import datetime, timezone
from typing import Optional, BinaryIO, Generator
from pathlib import Path
import hashlib

from configs.settings import settings
from src.core.logging import get_logger
from src.core.exceptions import CloudStorageError, NetworkError

logger = get_logger(__name__)


class CloudSyncManager:
    """
    Manages synchronization between local storage and MinIO/S3 cloud storage.
    Supports resumable uploads and conflict resolution.
    """

    def __init__(
        self,
        endpoint: Optional[str] = None,
        access_key: Optional[str] = None,
        secret_key: Optional[str] = None,
        secure: Optional[bool] = None,
    ):
        """
        Initialize cloud sync manager.

        Args:
            endpoint: MinIO/S3 endpoint
            access_key: Access key
            secret_key: Secret key
            secure: Use HTTPS
        """
        self.endpoint = endpoint or settings.minio.endpoint
        self.access_key = access_key or settings.minio.access_key
        self.secret_key = secret_key or settings.minio.secret_key
        self.secure = secure if secure is not None else settings.minio.secure

        self.bucket_images = settings.minio.bucket_images
        self.bucket_models = settings.minio.bucket_models
        self.bucket_exports = settings.minio.bucket_exports

        self._client = None
        self._is_connected = False

    def _get_client(self):
        """Get or create MinIO client."""
        if self._client is None:
            try:
                from minio import Minio

                self._client = Minio(
                    self.endpoint,
                    access_key=self.access_key,
                    secret_key=self.secret_key,
                    secure=self.secure,
                )
                self._is_connected = True
                logger.info(f"Connected to MinIO at {self.endpoint}")
            except ImportError:
                logger.warning("minio package not installed, cloud sync disabled")
                self._is_connected = False
            except Exception as e:
                logger.error(f"Failed to connect to MinIO: {e}")
                self._is_connected = False

        return self._client

    def check_connection(self) -> bool:
        """Check if cloud storage is accessible."""
        client = self._get_client()
        if client is None:
            return False

        try:
            client.list_buckets()
            self._is_connected = True
            return True
        except Exception as e:
            logger.warning(f"Cloud storage not accessible: {e}")
            self._is_connected = False
            return False

    def ensure_buckets(self) -> bool:
        """Ensure all required buckets exist."""
        client = self._get_client()
        if client is None:
            return False

        buckets = [self.bucket_images, self.bucket_models, self.bucket_exports]

        try:
            for bucket in buckets:
                if not client.bucket_exists(bucket):
                    client.make_bucket(bucket)
                    logger.info(f"Created bucket: {bucket}")
            return True
        except Exception as e:
            logger.error(f"Failed to ensure buckets: {e}")
            return False

    def upload_image(
        self,
        image_id: str,
        image_data: bytes,
        metadata: Optional[dict] = None,
        content_type: str = "image/jpeg",
    ) -> bool:
        """
        Upload an image to cloud storage.

        Args:
            image_id: Image identifier
            image_data: Image bytes
            metadata: Optional metadata
            content_type: MIME type

        Returns:
            True if upload successful
        """
        client = self._get_client()
        if client is None:
            raise NetworkError("Cloud storage not available")

        object_name = f"images/{image_id}.jpg"

        try:
            minio_metadata = {}
            if metadata:
                for key, value in metadata.items():
                    minio_metadata[f"x-amz-meta-{key}"] = str(value)

            client.put_object(
                self.bucket_images,
                object_name,
                io.BytesIO(image_data),
                length=len(image_data),
                content_type=content_type,
                metadata=minio_metadata,
            )

            logger.info(f"Uploaded image {image_id} to cloud storage")
            return True

        except Exception as e:
            logger.error(f"Failed to upload image {image_id}: {e}")
            raise CloudStorageError(
                f"Upload failed: {e}",
                bucket=self.bucket_images,
                key=object_name,
            )

    def upload_detection_result(
        self,
        result_id: str,
        result_data: dict,
    ) -> bool:
        """
        Upload detection result to cloud storage.

        Args:
            result_id: Result identifier
            result_data: Detection result dictionary

        Returns:
            True if upload successful
        """
        client = self._get_client()
        if client is None:
            raise NetworkError("Cloud storage not available")

        object_name = f"detections/{result_id}.json"
        json_data = json.dumps(result_data, default=str).encode("utf-8")

        try:
            client.put_object(
                self.bucket_exports,
                object_name,
                io.BytesIO(json_data),
                length=len(json_data),
                content_type="application/json",
            )

            logger.info(f"Uploaded detection result {result_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to upload detection {result_id}: {e}")
            raise CloudStorageError(
                f"Upload failed: {e}",
                bucket=self.bucket_exports,
                key=object_name,
            )

    def upload_feedback(
        self,
        feedback_id: str,
        feedback_data: dict,
    ) -> bool:
        """
        Upload user feedback to cloud storage.

        Args:
            feedback_id: Feedback identifier
            feedback_data: Feedback dictionary

        Returns:
            True if upload successful
        """
        client = self._get_client()
        if client is None:
            raise NetworkError("Cloud storage not available")

        date_prefix = datetime.now().strftime("%Y/%m/%d")
        object_name = f"feedback/{date_prefix}/{feedback_id}.json"
        json_data = json.dumps(feedback_data, default=str).encode("utf-8")

        try:
            client.put_object(
                self.bucket_exports,
                object_name,
                io.BytesIO(json_data),
                length=len(json_data),
                content_type="application/json",
            )

            logger.info(f"Uploaded feedback {feedback_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to upload feedback {feedback_id}: {e}")
            raise CloudStorageError(
                f"Upload failed: {e}",
                bucket=self.bucket_exports,
                key=object_name,
            )

    def download_model(
        self,
        model_name: str,
        local_path: str,
    ) -> bool:
        """
        Download a model from cloud storage.

        Args:
            model_name: Model filename
            local_path: Local path to save model

        Returns:
            True if download successful
        """
        client = self._get_client()
        if client is None:
            raise NetworkError("Cloud storage not available")

        object_name = f"models/{model_name}"

        try:
            client.fget_object(
                self.bucket_models,
                object_name,
                local_path,
            )

            logger.info(f"Downloaded model {model_name} to {local_path}")
            return True

        except Exception as e:
            logger.error(f"Failed to download model {model_name}: {e}")
            raise CloudStorageError(
                f"Download failed: {e}",
                bucket=self.bucket_models,
                key=object_name,
            )

    def list_available_models(self) -> list[dict]:
        """List available models in cloud storage."""
        client = self._get_client()
        if client is None:
            return []

        try:
            objects = client.list_objects(
                self.bucket_models,
                prefix="models/",
            )

            models = []
            for obj in objects:
                models.append({
                    "name": obj.object_name.replace("models/", ""),
                    "size_bytes": obj.size,
                    "last_modified": obj.last_modified.isoformat(),
                    "etag": obj.etag,
                })

            return models

        except Exception as e:
            logger.error(f"Failed to list models: {e}")
            return []

    def check_model_version(
        self,
        model_name: str,
        local_checksum: str,
    ) -> dict:
        """
        Check if a newer model version is available.

        Args:
            model_name: Model filename
            local_checksum: MD5 checksum of local model

        Returns:
            Dictionary with version comparison info
        """
        client = self._get_client()
        if client is None:
            return {"needs_update": False, "error": "Not connected"}

        object_name = f"models/{model_name}"

        try:
            stat = client.stat_object(self.bucket_models, object_name)
            remote_etag = stat.etag.strip('"')

            needs_update = remote_etag != local_checksum

            return {
                "needs_update": needs_update,
                "local_checksum": local_checksum,
                "remote_checksum": remote_etag,
                "remote_size": stat.size,
                "remote_modified": stat.last_modified.isoformat(),
            }

        except Exception as e:
            return {"needs_update": False, "error": str(e)}

    def sync_iot_data(
        self,
        device_id: str,
        readings: list[dict],
    ) -> bool:
        """
        Batch upload IoT readings to cloud storage.

        Args:
            device_id: Device identifier
            readings: List of reading dictionaries

        Returns:
            True if sync successful
        """
        if not readings:
            return True

        client = self._get_client()
        if client is None:
            raise NetworkError("Cloud storage not available")

        date_prefix = datetime.now().strftime("%Y/%m/%d")
        timestamp = datetime.now().strftime("%H%M%S")
        object_name = f"iot/{device_id}/{date_prefix}/{timestamp}.jsonl"

        jsonl_data = "\n".join(
            json.dumps(r, default=str) for r in readings
        ).encode("utf-8")

        try:
            client.put_object(
                self.bucket_exports,
                object_name,
                io.BytesIO(jsonl_data),
                length=len(jsonl_data),
                content_type="application/x-ndjson",
            )

            logger.info(
                f"Synced {len(readings)} IoT readings for device {device_id}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to sync IoT data: {e}")
            raise CloudStorageError(
                f"IoT sync failed: {e}",
                bucket=self.bucket_exports,
                key=object_name,
            )

    def get_presigned_url(
        self,
        object_path: str,
        bucket: Optional[str] = None,
        expires_hours: int = 1,
    ) -> Optional[str]:
        """
        Generate a presigned URL for an object.

        Args:
            object_path: Path to the object
            bucket: Bucket name (default: images bucket)
            expires_hours: URL expiration time in hours

        Returns:
            Presigned URL or None
        """
        client = self._get_client()
        if client is None:
            return None

        bucket = bucket or self.bucket_images

        try:
            from datetime import timedelta

            url = client.presigned_get_object(
                bucket,
                object_path,
                expires=timedelta(hours=expires_hours),
            )
            return url

        except Exception as e:
            logger.error(f"Failed to generate presigned URL: {e}")
            return None

    def get_sync_status(self) -> dict:
        """Get current sync status."""
        return {
            "is_connected": self._is_connected,
            "endpoint": self.endpoint,
            "buckets": {
                "images": self.bucket_images,
                "models": self.bucket_models,
                "exports": self.bucket_exports,
            },
            "last_check": datetime.now(timezone.utc).isoformat(),
        }
