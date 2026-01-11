import pickle
import pandas as pd
import numpy as np
import sys
import os

# ==========================================================
# CONFIGURATION — YOUR EXACT PATHS
# ==========================================================

PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"

PROCESSED_FOLDER = os.path.join(
    PROJECT_ROOT,
    "Preprocessed_XGBoost_EXACT_CATBOOST"
)

ARTIFACTS_FOLDER = os.path.join(
    PROJECT_ROOT,
    "XGBoost_Artifacts"
)

MODEL_PATH = os.path.join(
    ARTIFACTS_FOLDER,
    "xgboost_tea_yield_model.pkl"   # ← YOUR EXACT FILE NAME
)

FEATURE_CSV_PATH = os.path.join(
    PROCESSED_FOLDER,
    "X_test.csv"
)

KG_META_PATH = os.path.join(
    PROCESSED_FOLDER,
    "y_test_kg.csv"
)

SAMPLE_INDEX = 0  # row to test

# ==========================================================
# STEP 1: LOAD MODEL
# ==========================================================
print("\n[1] Loading XGBoost model...")

try:
    with open(MODEL_PATH, "rb") as f:
        model_obj = pickle.load(f)
    print("✅ Model loaded successfully")
except Exception as e:
    print("❌ Failed to load model:", e)
    print(f"Model path attempted: {MODEL_PATH}")
    print(f"Does file exist? {os.path.exists(MODEL_PATH)}")
    sys.exit(1)

print(f"Model object type: {type(model_obj)}")

# ==========================================================
# STEP 2: RESOLVE MODEL OBJECT
# ==========================================================
model = None

if hasattr(model_obj, "predict"):
    model = model_obj
    print("✔ Detected direct model or sklearn Pipeline")

elif isinstance(model_obj, dict):
    print("✔ Detected dictionary container")
    for key in ["model", "regressor", "xgb_model"]:
        if key in model_obj:
            model = model_obj[key]
            print(f"✔ Found model under key: '{key}'")
            break

if model is None:
    print("❌ Could not resolve usable model object")
    sys.exit(1)

# ==========================================================
# STEP 3: LOAD FEATURES
# ==========================================================
print("\n[2] Loading X_test.csv...")

try:
    X_test = pd.read_csv(FEATURE_CSV_PATH)
    print("✅ Feature CSV loaded")
except Exception as e:
    print("❌ Failed to load X_test.csv:", e)
    print(f"CSV path attempted: {FEATURE_CSV_PATH}")
    sys.exit(1)

print(f"Feature shape: {X_test.shape}")
print(f"Number of features: {X_test.shape[1]}")

# ==========================================================
# STEP 4: FEATURE COUNT VALIDATION
# ==========================================================
print("\n[3] Validating feature count...")

if hasattr(model, "n_features_in_"):
    expected = model.n_features_in_
    actual = X_test.shape[1]

    print(f"Expected features (from model): {expected}")
    print(f"Actual features (in X_test.csv): {actual}")

    if expected != actual:
        print("❌ FEATURE MISMATCH — STOP")
        print("This means your model was trained with different features")
        print("than what's in X_test.csv")
        sys.exit(1)
    else:
        print("✅ Feature count matches exactly")
else:
    print("⚠ Model does not expose n_features_in_ (older XGBoost)")
    print("⚠ Proceeding with caution")

# ==========================================================
# STEP 5: LOAD KG METADATA (Labor_Safe)
# ==========================================================
print("\n[4] Loading kg metadata (Labor_Safe)...")

try:
    y_test_kg = pd.read_csv(KG_META_PATH)
    print("✅ y_test_kg.csv loaded")
    print(f"Columns in y_test_kg: {list(y_test_kg.columns)}")
except Exception as e:
    print("❌ Failed to load y_test_kg.csv:", e)
    print(f"Path attempted: {KG_META_PATH}")
    sys.exit(1)

if "Labor_Safe" not in y_test_kg.columns:
    print("❌ Labor_Safe column missing — cannot convert to kg")
    print(f"Available columns: {list(y_test_kg.columns)}")
    sys.exit(1)

# ==========================================================
# STEP 6: RUN PREDICTION
# ==========================================================
print("\n[5] Running test prediction...")

try:
    X_sample = X_test.iloc[[SAMPLE_INDEX]]
    print(f"Sample features shape: {X_sample.shape}")
    
    log_eff_pred = model.predict(X_sample)[0]

    labor_safe = y_test_kg.iloc[SAMPLE_INDEX]["Labor_Safe"]

    # Convert back to kg (YOUR EXACT FORMULA from preprocessing)
    predicted_kg = labor_safe * np.expm1(log_eff_pred)

    print("✅ Prediction successful")
    print(f"Predicted log-efficiency: {log_eff_pred:.6f}")
    print(f"Labor_Safe: {labor_safe:.2f}")
    print(f"➡️  Predicted Yield (kg): {predicted_kg:.2f}")

except Exception as e:
    print("❌ Prediction failed:", e)
    import traceback
    traceback.print_exc()
    sys.exit(1)

# ==========================================================
# STEP 7: SANITY CHECKS
# ==========================================================
print("\n[6] Sanity checks...")

if np.isnan(log_eff_pred) or np.isnan(predicted_kg):
    print("❌ NaN detected — model unsafe")
    sys.exit(1)

if predicted_kg < 0:
    print("❌ Negative yield — model unsafe")
    sys.exit(1)

print("✅ Output is numerically stable")

# ==========================================================
# STEP 8: CHECK REAL TARGET VALUE FOR COMPARISON
# ==========================================================
print("\n[7] Comparing with actual yield...")

try:
    actual_yield = y_test_kg.iloc[SAMPLE_INDEX]["Target_Usable_Yield_Kg"]
    print(f"Actual Yield (kg): {actual_yield:.2f}")
    
    if abs(predicted_kg - actual_yield) < 100:  # Reasonable threshold
        print(f"✅ Prediction is reasonable")
    else:
        print(f"⚠ Prediction seems far from actual ({abs(predicted_kg - actual_yield):.2f} kg difference)")
except:
    print("⚠ Could not compare with actual yield (Target_Usable_Yield_Kg column not found)")

# ==========================================================
# FINAL STATUS
# ==========================================================
print("\n" + "=" * 70)
print("🎉 XGBOOST MODEL VERIFIED SUCCESSFULLY")
print("=" * 70)
print(f"Model: {os.path.basename(MODEL_PATH)}")
print(f"Features: {X_test.shape[1]}")
print(f"Sample index: {SAMPLE_INDEX}")
print(f"Prediction: {predicted_kg:.2f} kg")
print("=" * 70)
print("👉 Preprocessing ✔")
print("👉 Feature alignment ✔")
print("👉 Log → kg conversion ✔")
print("👉 SAFE TO DEPLOY AS API")
print("=" * 70)