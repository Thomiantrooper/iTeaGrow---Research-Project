import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import sys
import os

# Set path to allow importing config
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '.')))
from config import settings

async def cleanup_duplicates():
    print(f"[-] Connecting to: {settings.MONGODB_URL}")
    try:
        client = AsyncIOMotorClient(settings.MONGODB_URL, serverSelectionTimeoutMS=5000)
        db = client[settings.DATABASE_NAME]
        
        # Test connection
        await client.admin.command('ping')
        print("[+] Connection Successful!")
        
        print("[-] Checking for duplicate usernames in 'users' collection...")
        pipeline = [
            {"$group": {"_id": "$username", "count": {"$sum": 1}, "ids": {"$push": "$_id"}}},
            {"$match": {"count": {"$gt": 1}}}
        ]
        
        duplicates = await db.users.aggregate(pipeline).to_list(None)
        
        if not duplicates:
            print("[+] No duplicate usernames found.")
        else:
            for dup in duplicates:
                username = dup['_id']
                ids = dup['ids']
                print(f"[!] Found {len(ids)} copies of user: {username}")
                
                # Keep the first one, delete the rest
                to_delete = ids[1:]
                result = await db.users.delete_many({"_id": {"$in": to_delete}})
                print(f"    [+] Deleted {result.deleted_count} duplicate(s) for '{username}'")

        print("[+] Database cleaned. Restarting the backend will now be able to build the unique indexes.")
            
    except Exception as e:
        print(f"[X] Error: {e}")

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(cleanup_duplicates())
