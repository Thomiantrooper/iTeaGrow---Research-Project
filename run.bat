@echo off
title Tea Leaf Disease Detection - Starting Services

echo.
echo ========================================
echo   Tea Leaf Disease Detection Platform
echo ========================================
echo.

cd /d "%~dp0"

echo [CHECK] Checking services...

:: Check MongoDB
tasklist /FI "IMAGENAME eq mongod.exe" 2>NUL | find /I /N "mongod.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] MongoDB is running
) else (
    echo [INFO] Starting MongoDB...
    start "" /B mongod --dbpath C:\data\db
    timeout /t 2 >nul
)

:: Check Ollama
curl -s http://localhost:11434/api/tags >nul 2>&1
if "%ERRORLEVEL%"=="0" (
    echo [OK] Ollama is running
) else (
    echo [INFO] Starting Ollama...
    start "" /B ollama serve
    timeout /t 3 >nul
)

echo.
echo [START] Starting Backend Server (with MongoDB)...
start "Backend Server" cmd /k "cd /d %~dp0\backend && call ..\venv\Scripts\activate.bat && python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"

echo [INFO] Starting Flutter Web Server (port 5000)...
echo [INFO] Attempting to launch Chrome with security flags...

start "" "http://localhost:5000"

start "Flutter App" cmd /k "cd /d %~dp0\frontend\iTeaGrow---Research-Project && flutter run -d web-server --web-port=5000"

echo.
echo ========================================
echo   All Services Started!
echo ========================================
echo.
echo Services:
echo   - Backend API:  http://localhost:8000
echo   - API Docs:     http://localhost:8000/docs
echo   - MongoDB:      mongodb://localhost:27017
echo   - Ollama:       http://localhost:11434
echo.
echo Close the opened windows to stop services.
pause
