from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.collection import Collection
from pymongo.errors import ConnectionFailure, OperationFailure, ServerSelectionTimeoutError
from app.config import settings
import logging
import time

logger = logging.getLogger(__name__)

class MongoDB:
    client: MongoClient = None
    db = None
    predictions: Collection = None
    connected = False

    @classmethod
    def connect(cls, max_retries=3, retry_delay=2):
        """Connect to MongoDB with retry logic"""
        
        for attempt in range(max_retries):
            try:
                logger.info(f"🔄 Connecting to MongoDB Atlas (attempt {attempt + 1}/{max_retries})...")
                
                # Create client with timeout
                cls.client = MongoClient(
                    settings.MONGO_URL, 
                    serverSelectionTimeoutMS=5000,
                    connectTimeoutMS=5000,
                    socketTimeoutMS=5000
                )
                
                # Test connection
                cls.client.admin.command('ping')
                logger.info("✅ MongoDB Atlas ping successful")
                
                # Get database
                cls.db = cls.client[settings.DATABASE_NAME]
                
                # List collections to verify
                collections = cls.db.list_collection_names()
                logger.info(f"📁 Collections in database: {collections}")
                
                # Check if 'predictions' collection exists, if not create it
                if "predictions" in collections:
                    cls.predictions = cls.db["predictions"]
                    count = cls.predictions.count_documents({})
                    logger.info(f"📊 Predictions collection has {count} documents")
                else:
                    # Create the collection
                    logger.info("📁 Creating 'predictions' collection...")
                    cls.db.create_collection("predictions")
                    cls.predictions = cls.db["predictions"]
                    logger.info("✅ Predictions collection created")
                
                # Create indexes
                try:
                    cls.predictions.create_index([("timestamp", DESCENDING)], background=True)
                    cls.predictions.create_index([("hectare_id", ASCENDING), ("timestamp", DESCENDING)], background=True)
                    logger.info("✅ Indexes created/verified")
                except Exception as e:
                    logger.warning(f"⚠️  Index creation warning: {e}")
                
                cls.connected = True
                logger.info("✅ MongoDB connected successfully!")
                return True
                
            except ServerSelectionTimeoutError as e:
                logger.error(f"❌ MongoDB connection timeout (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    logger.info(f"⏳ Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    logger.error("❌ All connection attempts failed")
                    cls.connected = False
                    
            except ConnectionFailure as e:
                logger.error(f"❌ MongoDB connection failure (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    logger.info(f"⏳ Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    logger.error("❌ All connection attempts failed")
                    cls.connected = False
                    
            except Exception as e:
                logger.error(f"❌ Unexpected MongoDB error: {e}")
                cls.connected = False
        
        return False

    @classmethod
    def check_connection(cls):
        """Check if MongoDB is still connected"""
        try:
            if cls.client:
                cls.client.admin.command('ping')
                return True
            return False
        except:
            return False

    @classmethod
    def get_stats(cls):
        """Get database statistics"""
        try:
            if cls.connected and cls.db:
                stats = {
                    "database": settings.DATABASE_NAME,
                    "collections": cls.db.list_collection_names(),
                    "connected": True
                }
                
                if "predictions" in stats["collections"] and cls.predictions:
                    stats["document_count"] = cls.predictions.count_documents({})
                    
                    # Get latest document
                    latest = cls.predictions.find_one({}, sort=[("timestamp", DESCENDING)])
                    if latest:
                        # Convert ObjectId to string for JSON serialization
                        if "_id" in latest:
                            latest["_id"] = str(latest["_id"])
                        stats["latest_document"] = latest
                
                return stats
            else:
                return {"connected": False, "database": settings.DATABASE_NAME}
        except Exception as e:
            logger.error(f"Error getting stats: {e}")
            return {"connected": False, "error": str(e)}

    @classmethod
    def insert_prediction(cls, data: dict):
        """Insert a prediction document"""
        try:
            if not cls.connected:
                cls.connect()
            
            result = cls.predictions.insert_one(data)
            logger.info(f"✅ Inserted prediction with ID: {result.inserted_id}")
            return result.inserted_id
        except Exception as e:
            logger.error(f"❌ Failed to insert prediction: {e}")
            return None

    @classmethod
    def find_predictions(cls, query={}, limit=100, sort_field="timestamp", sort_order=DESCENDING):
        """Find predictions with query"""
        try:
            if not cls.connected:
                cls.connect()
            
            cursor = cls.predictions.find(query).sort(sort_field, sort_order).limit(limit)
            results = list(cursor)
            
            # Convert ObjectId to string for each document
            for doc in results:
                doc["_id"] = str(doc["_id"])
            
            return results
        except Exception as e:
            logger.error(f"❌ Failed to find predictions: {e}")
            return []

    @classmethod
    def close(cls):
        """Close MongoDB connection"""
        if cls.client:
            cls.client.close()
            cls.connected = False
            logger.info("🔒 MongoDB connection closed")

# Initialize MongoDB connection
try:
    mongodb = MongoDB()
    if mongodb.connect():
        logger.info("✅ MongoDB initialization complete")
    else:
        logger.error("❌ MongoDB initialization failed")
        # Still create the object, it will try to connect on first use
        mongodb = MongoDB()
except Exception as e:
    logger.error(f"❌ Critical MongoDB error: {e}")
    mongodb = MongoDB()