#!/bin/bash
echo "========================================"
echo "  iTeaGrow Backend Server"
echo "========================================"
echo ""

# Check if MongoDB is running
echo "Checking MongoDB connection..."
python3 -c "from pymongo import MongoClient; c = MongoClient('localhost', 27017, serverSelectionTimeoutMS=2000); c.admin.command('ping')" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "[ERROR] MongoDB is not running!"
    echo "Please start MongoDB first."
    exit 1
fi
echo "[OK] MongoDB is running"

# Create virtual environment if needed
if [ ! -d "venv" ]; then
    echo ""
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo ""
echo "Activating virtual environment..."
source venv/bin/activate

echo ""
echo "Installing dependencies..."
pip install -r requirements.txt -q

# Seed demo users if needed
echo ""
echo "Checking demo users..."
python seed_demo_users.py

# Start the server
echo ""
echo "========================================"
echo "  Starting FastAPI Server on port 8000"
echo "  API Docs: http://localhost:8000/docs"
echo "  Press Ctrl+C to stop"
echo "========================================"
echo ""
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
