import requests
import time
import json
import uuid
import random

# Configuration
API_URL = "http://localhost:8000"

def generate_soil_data(hectare_id, quality="good"):
    """Generate soil data with all 7 features"""
    
    if quality == "good":
        # Good soil conditions
        data = {
            "device_id": f"esp32_{hectare_id:02d}",
            "hectare_id": hectare_id,
            "N": random.uniform(120, 180),
            "P": random.uniform(35, 50),
            "K": random.uniform(160, 220),
            "pH": random.uniform(5.8, 6.4),
            "EC": random.uniform(0.6, 1.2),
            "temperature": random.uniform(22, 28),
            "humidity": random.uniform(65, 75)
        }
    elif quality == "fair":
        # Fair soil conditions
        data = {
            "device_id": f"esp32_{hectare_id:02d}",
            "hectare_id": hectare_id,
            "N": random.uniform(70, 110),
            "P": random.uniform(20, 30),
            "K": random.uniform(110, 150),
            "pH": random.uniform(5.2, 5.8),
            "EC": random.uniform(0.3, 0.6),
            "temperature": random.uniform(18, 22),
            "humidity": random.uniform(55, 65)
        }
    else:  # poor
        # Poor soil conditions
        data = {
            "device_id": f"esp32_{hectare_id:02d}",
            "hectare_id": hectare_id,
            "N": random.uniform(20, 60),
            "P": random.uniform(5, 15),
            "K": random.uniform(40, 90),
            "pH": random.uniform(4.2, 5.0),
            "EC": random.uniform(0.1, 0.3),
            "temperature": random.uniform(10, 18),
            "humidity": random.uniform(40, 55)
        }
    
    return data

def run_all_checks():
    print("==========================================")
    print("🚀 RUNNING 25 RECORD DATA POPULATION SCRIPT")
    print("==========================================\n")

    overall_success = True

    # ----------------------------------------------------
    # 1. API Health Check
    # ----------------------------------------------------
    print("1️⃣ Testing FastAPI Health Endpoint...")
    try:
        response = requests.get(f"{API_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ API Status: {data.get('status')}")
            print(f"   ✅ MongoDB connection: {data.get('database')}")
        else:
            print(f"   ❌ API returned status code {response.status_code}")
            overall_success = False
            return
    except requests.exceptions.ConnectionError:
        print("   ❌ FAILED: Cannot connect to FastAPI server.")
        overall_success = False
        return

    # ----------------------------------------------------
    # 2. Generating & Saving 25 Records via ML Pipeline
    # ----------------------------------------------------
    print("\n2️⃣ Generating 25 Data Points and Saving to MongoDB...")
    
    import sys
    import os
    sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
    from app.services.ml_service import predict_soil_health
    from app.services.fertilizer_service import fertilizer_recommendation
    from app.database import mongodb
    from datetime import datetime, timezone

    records_inserted = 0

    for i in range(1, 26):
        if i % 3 == 0:
            quality = "good"
        elif i % 3 == 1:
            quality = "fair"
        else:
            quality = "poor"

        payload = generate_soil_data(i, quality)
        
        try:
            # Run ML predict
            soil_health = predict_soil_health(payload)
            fertilizer = fertilizer_recommendation(
                payload["N"], payload["P"], payload["K"], payload["pH"], soil_health
            )

            # Create Mongo document
            result = payload.copy()
            result.update({
                "soil_health": soil_health,
                "fertilizer": fertilizer,
                "timestamp": datetime.now(timezone.utc)
            })
            
            # Save to MongoDB Database
            mongodb.predictions.insert_one(result)
            records_inserted += 1
            print(f"   ✅ Record {i:2d}/25 Saved -> Hectare: {i}, ML Prediction: {soil_health}")
        except Exception as e:
            print(f"      ❌ FAILED processing record {i}: {e}")
            overall_success = False

    time.sleep(1)

    # ----------------------------------------------------
    # 3. Validation
    # ----------------------------------------------------
    print(f"\n3️⃣ Validating Persistence... (Expected: {records_inserted} new records)")
    try:
        response = requests.get(f"{API_URL}/farm/latest?limit=25", timeout=5)
        if response.status_code == 200:
            data = response.json()
            if len(data) >= 25:
                print(f"   ✅ Great! API confirmed 25+ records exist in the latest data query.")
            else:
                print(f"   ❌ Warning: Expected at least 25 records, but API returned only {len(data)}")
                overall_success = False
        else:
            print(f"   ❌ API returned status code {response.status_code}")
            overall_success = False
    except Exception as e:
        print(f"   ❌ FAILED fetching API data: {e}")
        overall_success = False

    print("\n==========================================")
    if overall_success:
        print("🟢 ALL 25 RECORDS SUCCESSFULLY PREDICTED AND SAVED TO MONGODB")
    else:
        print("🔴 ERROR SAVING 25 RECORDS")
    print("==========================================")

if __name__ == "__main__":
    run_all_checks()
