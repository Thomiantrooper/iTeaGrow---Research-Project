from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

class Database:
    client: AsyncIOMotorClient = None
    db = None

db = Database()

async def connect_to_mongo():
    """Connect to MongoDB on startup"""
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    db.db = db.client[settings.DATABASE_NAME]

    # Create indexes for users collection
    await db.db.users.create_index("username", unique=True)
    await db.db.users.create_index("email", unique=True, sparse=True)

    # Create indexes for disease_detections collection
    await db.db.disease_detections.create_index("user_id")
    await db.db.disease_detections.create_index("created_at")

    # Create indexes for iot_data collection
    await db.db.iot_data.create_index("user_id")
    await db.db.iot_data.create_index("device_id")
    await db.db.iot_data.create_index("timestamp")

    print(f"Connected to MongoDB at {settings.MONGODB_URL}")

async def close_mongo_connection():
    """Close MongoDB connection on shutdown"""
    if db.client:
        db.client.close()
        print("Closed MongoDB connection")

def get_database():
    """Get database instance"""
    return db.db
