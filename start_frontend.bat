@echo off
echo ========================================
echo  Tea Leaf Disease Detection - Frontend
echo ========================================
echo.

cd /d "%~dp0frontend\iTeaGrow---Research-Project"

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    echo.
    echo Please install Flutter:
    echo 1. Download from: https://flutter.dev/docs/get-started/install/windows
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to your PATH
    echo.
    pause
    exit /b 1
)

echo Getting Flutter packages...
call flutter pub get

echo.
echo Checking for connected devices...
call flutter devices

echo.
echo ========================================
echo Choose how to run the app:
echo ========================================
echo 1. Chrome (Web)
echo 2. Android Emulator
echo 3. Connected Android Device
echo 4. Windows Desktop
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    echo Running on Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo Running on Android Emulator...
    flutter run -d emulator
) else if "%choice%"=="3" (
    echo Running on connected Android device...
    flutter run
) else if "%choice%"=="4" (
    echo Running on Windows...
    flutter run -d windows
) else (
    echo Invalid choice. Running on default device...
    flutter run
)

pause
