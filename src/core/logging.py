"""
Logging configuration for the Tea Leaf Disease Detection Platform.
Provides structured logging with JSON formatting for production environments.
"""

import logging
import sys
import json
from datetime import datetime, timezone
from typing import Optional, Any
from pathlib import Path
import traceback


class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        if record.exc_info:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__ if record.exc_info[0] else None,
                "message": str(record.exc_info[1]) if record.exc_info[1] else None,
                "traceback": traceback.format_exception(*record.exc_info),
            }

        if hasattr(record, "extra_data"):
            log_data["extra"] = record.extra_data

        return json.dumps(log_data, default=str)


class ContextLogger(logging.LoggerAdapter):
    """Logger adapter that adds contextual information to log messages."""

    def process(self, msg: str, kwargs: dict) -> tuple:
        extra = kwargs.get("extra", {})
        extra.update(self.extra)
        kwargs["extra"] = extra
        return msg, kwargs


def setup_logging(
    log_level: str = "INFO",
    log_file: Optional[str] = None,
    json_format: bool = True,
) -> None:
    """
    Configure logging for the application.

    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Optional file path for log output
        json_format: Whether to use JSON formatting (recommended for production)
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper(), logging.INFO))

    root_logger.handlers.clear()

    if json_format:
        formatter = JSONFormatter()
    else:
        formatter = logging.Formatter(
            fmt="%(asctime)s | %(levelname)-8s | %(name)s:%(funcName)s:%(lineno)d | %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)

    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        file_handler = logging.FileHandler(log_file, encoding="utf-8")
        file_handler.setFormatter(formatter)
        root_logger.addHandler(file_handler)

    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.error").setLevel(logging.WARNING)


def get_logger(
    name: str,
    context: Optional[dict[str, Any]] = None,
) -> logging.LoggerAdapter:
    """
    Get a logger instance with optional context.

    Args:
        name: Logger name (typically __name__)
        context: Optional context dictionary to include in all log messages

    Returns:
        Configured logger adapter
    """
    logger = logging.getLogger(name)
    return ContextLogger(logger, context or {})


class RequestLogger:
    """Utility class for logging HTTP requests and responses."""

    def __init__(self, logger: logging.LoggerAdapter):
        self.logger = logger

    def log_request(
        self,
        method: str,
        path: str,
        client_ip: Optional[str] = None,
        request_id: Optional[str] = None,
    ) -> None:
        """Log incoming HTTP request."""
        self.logger.info(
            f"Request: {method} {path}",
            extra={
                "extra_data": {
                    "type": "request",
                    "method": method,
                    "path": path,
                    "client_ip": client_ip,
                    "request_id": request_id,
                }
            },
        )

    def log_response(
        self,
        method: str,
        path: str,
        status_code: int,
        duration_ms: float,
        request_id: Optional[str] = None,
    ) -> None:
        """Log HTTP response."""
        log_level = logging.INFO if status_code < 400 else logging.WARNING
        self.logger.log(
            log_level,
            f"Response: {method} {path} - {status_code} ({duration_ms:.2f}ms)",
            extra={
                "extra_data": {
                    "type": "response",
                    "method": method,
                    "path": path,
                    "status_code": status_code,
                    "duration_ms": duration_ms,
                    "request_id": request_id,
                }
            },
        )

    def log_inference(
        self,
        image_id: str,
        num_detections: int,
        inference_time_ms: float,
        model_type: str = "yolov8n",
    ) -> None:
        """Log model inference results."""
        self.logger.info(
            f"Inference completed: {num_detections} detections in {inference_time_ms:.2f}ms",
            extra={
                "extra_data": {
                    "type": "inference",
                    "image_id": image_id,
                    "num_detections": num_detections,
                    "inference_time_ms": inference_time_ms,
                    "model_type": model_type,
                }
            },
        )
