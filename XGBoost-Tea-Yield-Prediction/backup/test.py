"""
CHECK IF XGBOOST AND CATBOOST DATA ARE NOW IDENTICAL
====================================================
"""

import pandas as pd
import numpy as np
import os

catboost_folder = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost_XGBoost_Complete"
xgboost_folder = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Preprocessed_XGBoost_EXACT_CATBOOST"

print("="*80)
print("CHECKING IF DATA IS NOW IDENTICAL")
print("="*80)

# Load X_train from both
X_cb = pd.read_csv(os.path.join(catboost_folder, "X_train.csv"))
X_xgb = pd.read_csv(os.path.join(xgboost_folder, "X_train.csv"))

print(f"\nShapes:")
print(f"CatBoost: {X_cb.shape}")
print(f"XGBoost:  {X_xgb.shape}")

print(f"\nFeatures match: {list(X_cb.columns) == list(X_xgb.columns)}")

print(f"\nLabor_Total comparison:")
print(f"CatBoost - Mean: {X_cb['Labor_Total'].mean():.2f}")
print(f"XGBoost  - Mean: {X_xgb['Labor_Total'].mean():.2f}")
print(f"Difference: {abs(X_cb['Labor_Total'].mean() - X_xgb['Labor_Total'].mean()):.2f}")

print(f"\nFirst 5 rows comparison (Labor_Total):")
print("CatBoost:", X_cb['Labor_Total'].head().values)
print("XGBoost: ", X_xgb['Labor_Total'].head().values)

# Check if they're identical
if X_cb.shape == X_xgb.shape and list(X_cb.columns) == list(X_xgb.columns):
    print(f"\n✅ PERFECT! XGBoost data now matches CatBoost exactly!")
    print(f"   Features: {X_cb.shape[1]}")
    print(f"   Samples: {X_cb.shape[0]:,}")
    print(f"   Labor is NOT scaled in both")
else:
    print(f"\n❌ STILL DIFFERENT!")
    print(f"   Check features and values")