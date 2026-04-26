from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

class Database:
    client: AsyncIOMotorClient = None
    db = None

db = Database()

async def connect_to_mongo():
    """Connect to MongoDB on startup"""
    try:
        db.client = AsyncIOMotorClient(settings.MONGODB_URL, serverSelectionTimeoutMS=10000)
        db.db = db.client[settings.DATABASE_NAME]

        # Verify connection is alive before declaring success
        await db.client.admin.command("ping")

        # Create indexes (best-effort — don't fail startup if these error)
        try:
            await db.db.users.create_index("username", unique=True)
            await db.db.users.create_index("email", unique=True, sparse=True)
            await db.db.disease_detections.create_index("user_id")
            await db.db.disease_detections.create_index("created_at")
            await db.db.iot_data.create_index("user_id")
            await db.db.iot_data.create_index("device_id")
            await db.db.iot_data.create_index("timestamp")
        except Exception as idx_err:
            print(f"[WARNING] Index creation failed (non-fatal): {idx_err}")

        print("[SUCCESS] Connected to Remote MongoDB (Atlas)")
    except Exception as e:
        print(f"[WARNING] Could not connect to MongoDB: {e}")
        print("[WARNING] Running without database persistence.")
        db.client = None
        db.db = None

async def close_mongo_connection():
    """Close MongoDB connection on shutdown"""
    if db.client:
        db.client.close()
        print("Closed MongoDB connection")

async def get_database_async():
    """Get database, reconnecting automatically if the startup connection failed."""
    if db.db is None:
        await connect_to_mongo()
    return db.db

def get_database():
    """Get database instance (sync — returns None if not yet connected)."""
    return db.db
