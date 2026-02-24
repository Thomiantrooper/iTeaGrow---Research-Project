from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.collection import Collection
from pymongo.errors import ConnectionFailure, OperationFailure
from app.config import settings
import logging

logger = logging.getLogger(__name__)

class MongoDB:
    client: MongoClient = None
    db = None
    predictions: Collection = None

    @classmethod
    def connect(cls):
        """Connect to MongoDB"""
        try:
            cls.client = MongoClient(settings.MONGO_URL)
            cls.db = cls.client[settings.DATABASE_NAME]
            cls.predictions = cls.db["predictions"]
            
            # Create indexes for better query performance
            cls.predictions.create_index([("timestamp", DESCENDING)])
            cls.predictions.create_index([("hectare_id", ASCENDING), ("timestamp", DESCENDING)])
            
            # Test connection
            cls.client.admin.command('ping')
            logger.info("✅ Connected to MongoDB")
            
        except ConnectionFailure as e:
            logger.error(f"❌ MongoDB connection failed: {e}")
            raise
        except Exception as e:
            logger.error(f"❌ Unexpected MongoDB error: {e}")
            raise

    @classmethod
    def close(cls):
        """Close MongoDB connection"""
        if cls.client:
            cls.client.close()
            logger.info("🔒 MongoDB connection closed")

# Initialize MongoDB connection
mongodb = MongoDB()
mongodb.connect()