"""
MongoDB database connection and management.
Uses Motor for async MongoDB operations.
"""

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from typing import Optional
import logging

from configs.settings import settings

logger = logging.getLogger(__name__)


class Database:
    """MongoDB database manager."""

    client: Optional[AsyncIOMotorClient] = None
    db: Optional[AsyncIOMotorDatabase] = None


# Global database instance
db = Database()


async def connect_to_mongodb():
    """
    Connect to MongoDB on application startup.
    Creates necessary indexes for collections.
    """
    try:
        # Get MongoDB settings
        mongodb_url = settings.mongodb.url
        database_name = settings.mongodb.database_name

        # Connect to MongoDB
        db.client = AsyncIOMotorClient(mongodb_url)
        db.db = db.client[database_name]

        # Test connection
        await db.client.admin.command('ping')

        # Create indexes for disease_detections collection
        await db.db.disease_detections.create_index("user_id")
        await db.db.disease_detections.create_index("created_at")
        await db.db.disease_detections.create_index([("location_lat", 1), ("location_lng", 1)])

        # Create indexes for iot_data collection
        await db.db.iot_data.create_index("user_id")
        await db.db.iot_data.create_index("device_id")
        await db.db.iot_data.create_index("timestamp")

        # Create indexes for chatbot_conversations (optional)
        await db.db.chatbot_conversations.create_index("session_id")
        await db.db.chatbot_conversations.create_index("user_id")
        await db.db.chatbot_conversations.create_index("created_at")

        logger.info(f"Connected to MongoDB at {mongodb_url}/{database_name}")

    except Exception as e:
        logger.warning(f"Failed to connect to MongoDB: {e}")
        logger.warning("Application will run without database persistence")
        db.client = None
        db.db = None


async def close_mongodb_connection():
    """Close MongoDB connection on application shutdown."""
    if db.client:
        db.client.close()
        logger.info("Closed MongoDB connection")


def get_database() -> Optional[AsyncIOMotorDatabase]:
    """
    Get database instance.

    Returns:
        MongoDB database instance or None if not connected
    """
    return db.db


def is_connected() -> bool:
    """Check if MongoDB is connected."""
    return db.client is not None and db.db is not None
