import asyncio
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime, timedelta
import bcrypt
from jose import jwt

# Simple test server
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB client
client = None
db = None

SECRET_KEY = "test-secret-key"
ALGORITHM = "HS256"

@app.on_event("startup")
async def startup():
    global client, db
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client["iteagrow"]
    print("Connected to MongoDB")

@app.on_event("shutdown")
async def shutdown():
    global client
    if client:
        client.close()

@app.get("/")
async def root():
    return {"message": "Test API"}

@app.post("/register")
async def register(data: dict):
    try:
        username = data.get("username")
        password = data.get("password")
        full_name = data.get("full_name")

        print(f"Registering user: {username}")

        # Check if exists
        existing = await db.users.find_one({"username": username})
        if existing:
            return {"error": "Username exists"}

        # Hash password
        hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

        # Create user
        user_doc = {
            "username": username,
            "full_name": full_name,
            "hashed_password": hashed,
            "role": "farmer",
            "created_at": datetime.utcnow(),
            "is_active": True
        }

        result = await db.users.insert_one(user_doc)
        print(f"User created: {result.inserted_id}")

        # Create token
        token = jwt.encode(
            {"sub": username, "user_id": str(result.inserted_id)},
            SECRET_KEY,
            algorithm=ALGORITHM
        )

        return {
            "access_token": token,
            "user": {
                "id": str(result.inserted_id),
                "username": username,
                "full_name": full_name
            }
        }
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
