"""
Seed Demo Users Script
Creates demo users in MongoDB for testing purposes
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
from datetime import datetime

# MongoDB connection
MONGODB_URL = "mongodb://localhost:27017"
DATABASE_NAME = "iteagrow"

def get_password_hash(password: str) -> str:
    """Hash a password"""
    return bcrypt.hashpw(
        password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')

async def seed_demo_users():
    """Create demo users in MongoDB"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    # Demo users to create
    demo_users = [
        {
            "username": "admin",
            "full_name": "Admin User",
            "email": "admin@iteagrow.com",
            "phone": "+94771234567",
            "role": "admin",
            "language_preference": "en",
            "hashed_password": get_password_hash("admin123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "is_active": True
        },
        {
            "username": "manager",
            "full_name": "Manager User",
            "email": "manager@iteagrow.com",
            "phone": "+94772345678",
            "role": "manager",
            "language_preference": "en",
            "hashed_password": get_password_hash("manager123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "is_active": True
        },
        {
            "username": "farmer",
            "full_name": "Farmer User",
            "email": "farmer@iteagrow.com",
            "phone": "+94773456789",
            "role": "farmer",
            "language_preference": "en",
            "hashed_password": get_password_hash("farmer123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "is_active": True
        }
    ]

    print("Seeding demo users...")

    for user in demo_users:
        # Check if user already exists
        existing = await db.users.find_one({"username": user["username"]})

        if existing:
            print(f"  User '{user['username']}' already exists, updating...")
            await db.users.update_one(
                {"username": user["username"]},
                {"$set": user}
            )
        else:
            print(f"  Creating user '{user['username']}'...")
            result = await db.users.insert_one(user)
            print(f"    Created with ID: {result.inserted_id}")

    print("\nDemo users seeded successfully!")
    print("\nDemo Credentials:")
    print("  Admin:   admin / admin123")
    print("  Manager: manager / manager123")
    print("  Farmer:  farmer / farmer123")

    # Close connection
    client.close()

if __name__ == "__main__":
    asyncio.run(seed_demo_users())
