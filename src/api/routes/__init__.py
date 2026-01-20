"""API routes for the Tea Leaf Disease Detection Platform."""

from src.api.routes import inference, iot, recommendations, sync, health, feedback

__all__ = ["inference", "iot", "recommendations", "sync", "health", "feedback"]
