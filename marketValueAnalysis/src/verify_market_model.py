
"""
verify_market_model.py
End-to-End Verification Script for Tea Pricing Model
Simulates Mobile App Inputs -> External APIs -> XGBoost Prediction
"""

import pandas as pd
import numpy as np
import joblib
import json
import requests
from datetime import datetime
import warnings

warnings.filterwarnings('ignore')

# Configuration
MODEL_DIR = '../results/final_model'
PREPROC_DIR = '../results/preprocessing'

def fetch_external_data():
    """
    Fetches REAL data from external APIs (Weather, Exchange)
    """
    print("\nFetching External Data (LIVE API CALLS)...")
    
    # 1. Weather API (Open-Meteo) - FREE & NO KEY
    print("  > Connecting to Open-Meteo API (Rainfall)...")
    try:
        # Get yesterday's rainfall for Hatton
        yesterday = (datetime.now() - pd.Timedelta(days=1)).strftime('%Y-%m-%d')
        url = "https://archive-api.open-meteo.com/v1/archive"
        params = {
            "latitude": 6.9003, # Hatton
            "longitude": 80.5966,
            "start_date": yesterday,
            "end_date": yesterday,
            "daily": "rain_sum",
            "timezone": "Asia/Colombo"
        }
        res = requests.get(url, params=params, timeout=5)
        if res.status_code == 200:
            data = res.json()
            rainfall_mm = data['daily']['rain_sum'][0]
            print(f"    ✅ Live Rainfall (Hatton, {yesterday}): {rainfall_mm} mm")
        else:
            print(f"    ⚠️ API Error: {res.status_code}. Using fallback.")
            rainfall_mm = 12.5
            
    except Exception as e:
        print(f"    ⚠️ Connection failed: {e}. Using fallback.")
        rainfall_mm = 12.5

    # 2. Exchange Rate API (Open Exchange Rates - FREE equivalent)
    # CBSL API often requires key/approval, using public free alternative for demo
    print("  > Connecting to Exchange Rate API...")
    try:
        url = "https://open.er-api.com/v6/latest/USD"
        res = requests.get(url, timeout=5)
        if res.status_code == 200:
            data = res.json()
            exchange_rate = data['rates']['LKR']
            print(f"    ✅ Live USD/LKR Rate: Rs. {exchange_rate:.2f}")
        else:
            print(f"    ⚠️ API Error. Using fallback.")
            exchange_rate = 309.0
            
    except Exception as e:
        print(f"    ⚠️ Connection failed: {e}. Using fallback.")
        exchange_rate = 309.0
    
    # 3. Market Price (Still Mocked - No Public API)
    print("  > Connecting to Tea Auction API (Mocked)...")
    market_price = 1143.0 
    print(f"    Current Market Average: Rs. {market_price}/kg (Mocked)")
    
    return {
        'rainfall_mm': rainfall_mm,
        'market_price': market_price,
        'exchange_rate': exchange_rate,
        'season': 'Peak' # Derived from date usually
    }

def load_resources():
    """Load model and encoders"""
    print("\nLoading AI Models & Resources...")
    try:
        model = joblib.load(f'{MODEL_DIR}/xgboost_final_tea_model.pkl')
        grade_encoder = joblib.load(f'{PREPROC_DIR}/grade_encoder.pkl')
        season_encoder = joblib.load(f'{PREPROC_DIR}/season_encoder.pkl')
        feature_names = joblib.load(f'{PREPROC_DIR}/feature_names.pkl')
        print("  > XGBoost Model loaded")
        print("  > Encoders loaded")
        return model, grade_encoder, season_encoder, feature_names
    except FileNotFoundError as e:
        print(f"Error loading resources: {e}")
        exit(1)

def prepare_features(user_inputs, external_data, encoders, feature_names):
    """
    Transforms raw inputs into the exact feature vector the model expects.
    Match logic in preprocessing.py / modeltraining.py
    """
    grade_encoder, season_encoder = encoders
    
    # 1. Base DataFrame
    row = {
        'grade_encoded': grade_encoder[user_inputs['grade']],
        'confidence': user_inputs['confidence'],
        'color': user_inputs['color'],
        'aroma': user_inputs['aroma'],
        'age': user_inputs['age'],
        'quantity_kg': user_inputs['quantity'],
        'market_price': external_data['market_price'],
        'rainfall_mm': external_data['rainfall_mm'],
        'exchange_rate': external_data['exchange_rate'],
        'season_encoded': season_encoder[external_data['season']]
    }
    
    # 2. Derived Features (Decomposed Interactions - Anti-Overfitting)
    row['grade_color'] = row['grade_encoded'] * row['color']
    row['grade_aroma'] = row['grade_encoded'] * row['aroma']
    row['grade_age'] = row['grade_encoded'] * row['age']
    
    # Market-Rainfall Interaction
    row['market_rainfall_interaction'] = row['market_price'] * (row['rainfall_mm'] / 100)
    
    # 3. Time-Series/Lag Features (Static defaults for single prediction)
    # In a real production system with a database, you'd fetch history.
    # For a stateless prediction, we assume neutral trends or current values.
    row['price_momentum_3d'] = 0.0          # Neutral momentum
    row['price_momentum_7d'] = 0.0          # Neutral momentum
    row['rainfall_lag_7d'] = row['rainfall_mm'] # Assume constant recent rain
    row['rainfall_lag_30d'] = row['rainfall_mm']
    
    # Convert to DataFrame with correct column order
    df = pd.DataFrame([row])
    
    # Ensure all expected columns exist (fill 0 for any missing)
    for col in feature_names:
        if col not in df.columns:
            df[col] = 0
            
    # Reorder exactly as model expects
    df = df[feature_names]
    
    return df

def run_verification():
    print("="*60)
    print("VERIFICATION SCRIPT: MARKET VALUE MODEL")
    print("Simulating Full App Workflow")
    print("="*60)
    
    # 1. Simulate Mobile Inputs
    print("\n[STEP 1] Simulating Mobile App Inputs...")
    mobile_inputs = {
        "grade": "BOPF",           # From Image Model
        "confidence": 0.94,         # From Image Model
        "color": 1.0,               # User Input (Good)
        "aroma": 0.5,               # User Input (Average)
        "age": 0.5,                 # User Input (Medium)
        "quantity": 500             # User Input (kg)
    }
    print(json.dumps(mobile_inputs, indent=2))
    
    # 2. Fetch External Data
    print("\n[STEP 2] Fetching Environment Data...")
    external_data = fetch_external_data()
    
    # 3. Load Model
    model, grade_enc, season_enc, feat_names = load_resources()
    
    # 4. Prepare Features
    print("\n[STEP 3] Preparing Features for AI...")
    X = prepare_features(mobile_inputs, external_data, (grade_enc, season_enc), feat_names)
    
    # 5. Predict
    print("\n[STEP 4] Running Prediction...")
    predicted_price = model.predict(X)[0]
    total_value = predicted_price * mobile_inputs['quantity']
    
    # 6. Generate Response
    response = {
        "success": True,
        "prediction": {
            "price_per_kg": round(float(predicted_price), 2),
            "total_value": round(float(total_value), 2),
            "confidence": mobile_inputs['confidence'],
            "model_accuracy": {
                "mae": 14.82,
                "within_20": "71%",
                "r2": 0.969
            }
        },
        "breakdown": {
            "base_market": external_data['market_price'],
            "grade_premium": "Calculated by Model", 
            "quality_premium": "Calculated by Model"
        },
        "timestamp": datetime.now().isoformat()
    }
    
    print("\n" + "="*60)
    print("FINAL JSON RESPONSE (Sent to Mobile App)")
    print("="*60)
    print(json.dumps(response, indent=2))
    
if __name__ == "__main__":
    run_verification()
