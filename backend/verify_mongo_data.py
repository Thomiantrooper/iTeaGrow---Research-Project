import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from config import settings
import sys

# Force the remote URL if not picked up correctly, or use the one from settings
MONGODB_URL = settings.MONGODB_URL
DATABASE_NAME = settings.DATABASE_NAME

async def verify_data():
    print(f"[-] Attempting to connect to: {MONGODB_URL}")
    print(f"[-] Database: {DATABASE_NAME}")
    
    try:
        client = AsyncIOMotorClient(MONGODB_URL, serverSelectionTimeoutMS=5000)
        db = client[DATABASE_NAME]
        
        # Trigger a connection
        print("[-] Pinging server...")
        await client.admin.command('ping')
        print("[+] Connection Successful!")
        
        # Count users
        count = await db.users.count_documents({})
        print(f"[+] User Count in DB: {count}")
        
        if count > 0:
            print("[-] Listing first 5 users:")
            cursor = db.users.find().limit(5)
            async for user in cursor:
                print(f"    - {user.get('username')} ({user.get('role')})")
        else:
            print("[!] No users found in database.")
            
    except Exception as e:
        print("\n[X] CONNECTION FAILED")
        print(f"    Error: {e}")
        print("\n[INFO] If this script fails, the Backend is likely running in OFFLINE MODE.")
        print("       Data is NOT being stored in MongoDB.")

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(verify_data())
