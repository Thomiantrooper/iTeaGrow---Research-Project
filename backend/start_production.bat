@echo off
title iTeaGrow Backend Server
echo ========================================
echo  iTeaGrow Backend - Production Server
echo ========================================
echo.

cd /d "%~dp0"

:: Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH.
    pause
    exit /b 1
)

:: Install dependencies if needed
echo Installing/updating dependencies...
pip install -r requirements.txt -q

:: Set production environment
set DEBUG=False
set HOST=0.0.0.0
set PORT=8000

echo.
echo Starting iTeaGrow backend on port %PORT%...
echo Press Ctrl+C to stop the server.
echo.

:restart_loop
echo [%date% %time%] Starting server...
python -m uvicorn main:app --host %HOST% --port %PORT% --workers 2
echo.
echo [%date% %time%] Server stopped. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto restart_loop
