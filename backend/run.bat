@echo off
echo Starting iTeaGrow Backend API...
echo.
echo Make sure MongoDB is running on localhost:27017
echo.

REM Activate virtual environment if exists
if exist "..\disease_env\Scripts\activate.bat" (
    call ..\disease_env\Scripts\activate.bat
)

REM Install dependencies if needed
pip install -r requirements.txt

REM Run the server
python main.py

pause
