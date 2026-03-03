# Manager Google Auth Provisioning Guide

This guide explains how to provision a Manager account so that they can successfully use the **Google Sign-In** button in the iTeaGrow application.

## 🔑 How Google Auth Works in the Backend

The authentication microservice (`Authentication-iTeaGrow-API`) requires a Manager to use Google Login. However, the Google Login feature is strictly an **authorization** gateway. It does **not** create a new user account. 

Before a manager can sign in using Google, their exact Gmail address *must* already exist in your system's MongoDB `users` collection, and their role *must* be explicitly set to `"manager"`.

If they attempt to log in and their address is not found or their role is not a manager, the system will return a `403 Forbidden` error.

---

## 🚀 The Best Way to Add a Manager

The absolute best and safest way to provision a manager is by using your API's standard `/api/users/register` endpoint. You can do this quickly via `curl`, Postman, or a simple Python script.

Since you are the system administrator, you can run this python script locally. It connects directly to your live production MongoDB database and provisions the user.

### Step 1: Create a Provisioning Script

Save the following Python script inside your `Authentication-iTeaGrow-API` folder as `provision_manager.py`:

```python
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from dotenv import load_dotenv
import os
import sys

# Load your connection string from the .env file
load_dotenv()
MONGODB_URL = os.getenv("MONGODB_URL")

if not MONGODB_URL:
    print("Error: MONGODB_URL not found in .env file.")
    sys.exit(1)

# Set up password hashing (same as your auth.py)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def provision_manager():
    # 1. Ask for Manager Details
    print("\n--- Provision a New iTeaGrow Manager ---")
    full_name = input("Enter Manager's Full Name (e.g., John Doe): ")
    email = input("Enter Manager's EXACT Gmail Address (e.g., john.doe@gmail.com): ")
    
    # We generate a random password, but they won't need it because they will use Google Sign-In
    # We'll just generate a username based on their email prefix
    username = email.split("@")[0] + "_mgr"
    hashed_password = pwd_context.hash("google_auth_placeholder_password")

    # 2. Connect to Production Database
    print(f"\nConnecting to MongoDB...")
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client["iteagrow"] # Match the database name in your config
    users_collection = db["users"]

    # 3. Check if email already exists
    existing_user = await users_collection.find_one({"email": email})
    if existing_user:
        print(f"Error: A user with the email {email} already exists!")
        return

    # 4. Create the Manager Document
    from datetime import datetime
    manager_doc = {
        "username": username,
        "full_name": full_name,
        "email": email,
        "role": "manager",
        "language_preference": "en",
        "hashed_password": hashed_password,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "is_active": True
    }

    # 5. Insert into Database
    try:
        result = await users_collection.insert_one(manager_doc)
        print("\n✅ SUCCESS!")
        print(f"Manager '{full_name}' ({email}) has been successfully provisioned.")
        print("They can now open the app and use 'Sign In with Google'.")
    except Exception as e:
        print(f"\n❌ Error inserting user: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    asyncio.run(provision_manager())
```

### Step 2: Run the Script

1. Open your terminal and navigate to the `Authentication-iTeaGrow-API` folder.
2. Activate your virtual environment if you aren't already in one (`venv\Scripts\activate`).
3. Make sure your production MongoDB connection string (`MONGODB_URL`) is correctly pasted inside your `.env` file!
4. Run the script:
   ```bash
   python provision_manager.py
   ```

### Step 3: Enter Details
The script will prompt you:
```text
--- Provision a New iTeaGrow Manager ---
Enter Manager's Full Name (e.g., John Doe): Kasun Perera
Enter Manager's EXACT Gmail Address (e.g., kasun.perera@gmail.com): kasun.perera.manager@gmail.com
```

### What Happens Behind the Scenes?
1. The script connects explicitly to the live MongoDB using your environmental variable string.
2. It generates a placeholder password (the manager doesn't need to know it since they will authenticate natively via Google).
3. It creates their database record (`role="manager"`), officially authorizing their Gmail address.
4. From that second forward, when the manager opens the Flutter app and hits the Google Sign-in button, the backend will find their email, confirm they are a manager, and log them right in!
