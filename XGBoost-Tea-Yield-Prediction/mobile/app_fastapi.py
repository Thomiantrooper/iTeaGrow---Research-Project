import pickle
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List
import os
from datetime import datetime

# ==============================
# CONFIGURATION
# ==============================
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
ARTIFACTS_FOLDER = os.path.join(PROJECT_ROOT, "XGBoost_Artifacts")
MODEL_PATH = os.path.join(ARTIFACTS_FOLDER, "xgboost_tea_yield_model.pkl")

# ==============================
# CRITICAL: FEATURE ORDER FROM TRAINING
# ==============================
# This MUST match the exact order your model was trained with
FEATURE_ORDER = [
    'Division_LN', 'Division_LYN', 'Division_NC', 'Humidity_Mean_Pct',
    'Humidity_Deficit', 'Humidity_3Day_Avg', 'Humidity_7Day_Avg',
    'Humidity_Std_7Day', 'Consecutive_Stress_Days', 'Humidity_Stress_Index',
    'Humidity_Volatility', 'Is_Low_Humidity', 'Is_High_Humidity',
    'Extreme_Humidity_Stress', 'Temperature_Daily_C', 'Temperature_7D_Avg',
    'Temperature_14D_Avg', 'Temperature_28D_Avg', 'Rainfall_Daily_mm',
    'Rainfall_7D_Avg', 'Rainfall_14D_Avg', 'Rainfall_28D_Avg', 'Rain_7D_Sum',
    'Rain_14D_Sum', 'Rain_28D_Sum', 'Rain_4wk_Sum', 'VPD_kPa', 'Labor_Total',
    'Labor_7D_Avg', 'Kg_Per_Worker_Potential', 'Crop_Harvested_Kg',
    'Crop_7D_Avg', 'G_Pct', 'Total_Waste_Pct', 'Calculated_Waste_Pct',
    'Yield_Momentum', 'Month', 'Week_of_Year', 'Day_of_Year', 'Is_Weekend',
    'Crop_x_G_Pct', 'Labor_x_Temp', 'Humidity_x_Temp', 'Field_Intensity'
]

FEATURE_COUNT = len(FEATURE_ORDER)
print(f"📊 Expected feature count: {FEATURE_COUNT}")

# ==============================
# LOAD MODEL
# ==============================
print("🔧 Loading XGBoost model...")

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"❌ Model file not found: {MODEL_PATH}")

with open(MODEL_PATH, "rb") as f:
    model_obj = pickle.load(f)
print("✅ Model loaded from pickle")

# Resolve model object
if hasattr(model_obj, "predict"):
    model = model_obj
elif isinstance(model_obj, dict):
    for key in ["model", "regressor", "xgb_model"]:
        if key in model_obj:
            model = model_obj[key]
            break
    else:
        raise ValueError("Could not find model in dictionary")
else:
    raise ValueError(f"Unsupported model object type: {type(model_obj)}")

# Verify feature count
model_features = getattr(model, "n_features_in_", None)
if model_features and model_features != FEATURE_COUNT:
    print(f"⚠ Warning: Model expects {model_features} features, but our list has {FEATURE_COUNT}")

# ==============================
# FASTAPI SETUP
# ==============================
app = FastAPI(
    title="iTeaGrow Yield Prediction API",
    version="1.0.0",
    description="Predict tea yield using XGBoost ML model",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Enable CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================
# DATA MODELS
# ==============================
class YieldPredictionRequest(BaseModel):
    features: List[float] = Field(..., min_items=FEATURE_COUNT, max_items=FEATURE_COUNT)
    labor_safe: float = Field(..., gt=0)
    division_id: str = Field(default="ELT")
    prediction_date: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d"))

class YieldPredictionResponse(BaseModel):
    success: bool
    predicted_yield_kg: float
    division_id: str
    timestamp: str
    feature_order: List[str]  # For debugging

class HealthResponse(BaseModel):
    status: str
    feature_count: int
    ready: bool
    feature_order: List[str]

# ==============================
# API ENDPOINTS
# ==============================
@app.get("/", response_model=HealthResponse)
async def health_check():
    """Quick health check endpoint"""
    return {
        "status": "ready",
        "feature_count": FEATURE_COUNT,
        "ready": True,
        "feature_order": FEATURE_ORDER
    }

@app.post("/predict", response_model=YieldPredictionResponse)
async def predict_yield(request: YieldPredictionRequest):
    """
    Predict tea yield in kg
    
    Features must be in exact order matching training:
    1. Division_LN
    2. Division_LYN
    3. Division_NC
    4. Humidity_Mean_Pct
    ... etc (44 total)
    """
    try:
        # Validate input length
        if len(request.features) != FEATURE_COUNT:
            raise HTTPException(
                status_code=422,
                detail=f"Need exactly {FEATURE_COUNT} features, got {len(request.features)}"
            )
        
        # Create DataFrame with CORRECT COLUMN NAMES in EXACT ORDER
        # This is critical - XGBoost needs feature names to match training
        X_input = pd.DataFrame([request.features], columns=FEATURE_ORDER)
        
        # Make prediction (log efficiency)
        log_eff = float(model.predict(X_input)[0])
        
        # Convert to kg: kg = labor_safe * expm1(log_efficiency)
        predicted_kg = request.labor_safe * np.expm1(log_eff)
        
        # Ensure non-negative
        predicted_kg = max(0.0, predicted_kg)
        
        return {
            "success": True,
            "predicted_yield_kg": round(predicted_kg, 2),
            "division_id": request.division_id,
            "timestamp": datetime.now().isoformat(),
            "feature_order": FEATURE_ORDER  # Helpful for debugging
        }
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback_str = traceback.format_exc()
        print(f"❌ Prediction error: {e}")
        print(f"📝 Traceback: {traceback_str}")
        
        raise HTTPException(
            status_code=500,
            detail=f"Prediction error: {str(e)}"
        )

@app.get("/features")
async def get_features():
    """Return feature info with exact order"""
    return {
        "required_features": FEATURE_COUNT,
        "feature_order": FEATURE_ORDER,
        "example_features": [0.1] * FEATURE_COUNT
    }

@app.get("/features/example")
async def get_example_features():
    """Get example feature values in correct order"""
    example_values = {
        'Division_LN': 0.0,
        'Division_LYN': 1.0,  # Example: if predicting for LYN division
        'Division_NC': 0.0,
        'Humidity_Mean_Pct': 75.0,
        'Humidity_Deficit': 25.0,
        'Humidity_3Day_Avg': 76.0,
        'Humidity_7Day_Avg': 77.0,
        'Humidity_Std_7Day': 2.5,
        'Consecutive_Stress_Days': 0.0,
        'Humidity_Stress_Index': 0.0,
        'Humidity_Volatility': 1.5,
        'Is_Low_Humidity': 0.0,
        'Is_High_Humidity': 0.0,
        'Extreme_Humidity_Stress': 0.0,
        'Temperature_Daily_C': 24.5,
        'Temperature_7D_Avg': 24.0,
        'Temperature_14D_Avg': 23.5,
        'Temperature_28D_Avg': 23.0,
        'Rainfall_Daily_mm': 5.0,
        'Rainfall_7D_Avg': 4.5,
        'Rainfall_14D_Avg': 4.0,
        'Rainfall_28D_Avg': 3.5,
        'Rain_7D_Sum': 31.5,
        'Rain_14D_Sum': 56.0,
        'Rain_28D_Sum': 98.0,
        'Rain_4wk_Sum': 98.0,
        'VPD_kPa': 1.2,
        'Labor_Total': 70.0,
        'Labor_7D_Avg': 72.0,
        'Kg_Per_Worker_Potential': 15.0,
        'Crop_Harvested_Kg': 1000.0,
        'Crop_7D_Avg': 950.0,
        'G_Pct': 85.0,
        'Total_Waste_Pct': 5.0,
        'Calculated_Waste_Pct': 4.5,
        'Yield_Momentum': 1.0,
        'Month': 6.0,
        'Week_of_Year': 24.0,
        'Day_of_Year': 165.0,
        'Is_Weekend': 0.0,
        'Crop_x_G_Pct': 850.0,
        'Labor_x_Temp': 1680.0,
        'Humidity_x_Temp': 1837.5,
        'Field_Intensity': 100.0
    }
    
    # Convert to list in correct order
    ordered_values = [example_values[name] for name in FEATURE_ORDER]
    
    return {
        "features": ordered_values,
        "labor_safe": 70.0
    }

# ==============================
# STARTUP MESSAGE
# ==============================
print("\n" + "="*50)
print("🚀 FastAPI Server Ready!")
print(f"📌 Local: http://127.0.0.1:8000")
print(f"📌 Docs:  http://127.0.0.1:8000/docs")
print(f"📌 Features: {FEATURE_COUNT}")
print("="*50 + "\n")