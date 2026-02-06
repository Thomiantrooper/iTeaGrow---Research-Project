"""
MongoDB connection management.
"""

from motor.motor_asyncio import AsyncIOMotorClient
from configs.settings import settings
from src.core.logging import get_logger

logger = get_logger(__name__)

class MongoDB:
    client: AsyncIOMotorClient = None
    db = None

db = MongoDB()

async def connect_to_mongo():
    """Connect to MongoDB."""
    try:
        db.client = AsyncIOMotorClient(settings.database.mongodb_uri)
        db.db = db.client[settings.database.database_name]
        
        # Ping the database
        await db.client.admin.command('ping')
        logger.info(f"Connected to MongoDB at {settings.database.mongodb_uri}")
        
    except Exception as e:
        logger.error(f"Could not connect to MongoDB: {e}")
        raise

async def close_mongo_connection():
    """Close MongoDB connection."""
    if db.client:
        db.client.close()
        logger.info("Closed MongoDB connection")

def get_database():
    """Get database instance."""
    return db.db
