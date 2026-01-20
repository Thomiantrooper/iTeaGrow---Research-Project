@echo off
echo ========================================
echo   iTeaGrow Backend Server
echo ========================================
echo.

:: Check if MongoDB is running
echo Checking MongoDB connection...
python -c "from pymongo import MongoClient; c = MongoClient('localhost', 27017, serverSelectionTimeoutMS=2000); c.admin.command('ping')" 2>nul
if errorlevel 1 (
    echo [ERROR] MongoDB is not running!
    echo Please start MongoDB first.
    echo.
    pause
    exit /b 1
)
echo [OK] MongoDB is running

:: Install dependencies if needed
if not exist "venv" (
    echo.
    echo Creating virtual environment...
    python -m venv venv
)

:: Activate virtual environment and install dependencies
echo.
echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Installing dependencies...
pip install -r requirements.txt -q

:: Seed demo users if needed
echo.
echo Checking demo users...
python seed_demo_users.py

:: Start the server
echo.
echo ========================================
echo   Starting FastAPI Server on port 8000
echo   API Docs: http://localhost:8000/docs
echo   Press Ctrl+C to stop
echo ========================================
echo.
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
