"""
CATBOOST PREPROCESSING
==================================================================

"""

import pandas as pd
import numpy as np
import os
from pathlib import Path

# ==========================================
# CONFIGURATION
# ==========================================
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction"
DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Preprocessed_CatBoost_XGBoost_Complete")
Path(PROCESSED_FOLDER).mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("CATBOOST PREPROCESSING - REPLICATE XGBOOST COMPLETELY")
print("=" * 80)
print("Adding ALL missing XGBoost features (34 total)")
print("=" * 80)

# ==========================================
# LOAD DATA
# ==========================================
print("\n Loading data...")
train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
val_df = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
test_df = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))

full_df = pd.concat([train_df, val_df, test_df], ignore_index=True)
full_df['Date'] = pd.to_datetime(full_df['Date'])
full_df = full_df.sort_values(['Division_ID', 'Date']).reset_index(drop=True)

print(f"   Total samples: {len(full_df)}")
print(f"   Date range: {full_df['Date'].min().date()} to {full_df['Date'].max().date()}")
print(f"   Divisions: {full_df['Division_ID'].nunique()}")

# ==========================================
# CREATE XGBOOST'S TARGET
# ==========================================
print("\n Creating XGBoost's target...")
full_df['Labor_Safe'] = full_df['Labor_Total'].clip(lower=1)
full_df['Weekly_Efficiency'] = full_df['Target_Usable_Yield_Kg'] / full_df['Labor_Safe']
full_df['Target_Log_Eff'] = np.log1p(full_df['Weekly_Efficiency'])
print(f"   Target mean: {full_df['Target_Log_Eff'].mean():.4f}")

# ==========================================
# CREATE ALL XGBOOST FEATURES
# ==========================================
print("\n Creating ALL XGBoost features...")

# 1. HUMIDITY FEATURES (XGBoost had these)
print("   ✓ Humidity stress features...")
if 'Humidity_Mean_Pct' in full_df.columns:
    # Basic humidity stats
    full_df['Humidity_3Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(3, min_periods=1).mean()
    )
    full_df['Humidity_7Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    full_df['Humidity_Std_7Day'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(7, min_periods=2).std().fillna(0)
    )
    
    # Humidity deficit
    full_df['Humidity_Deficit'] = 100 - full_df['Humidity_Mean_Pct']
    
    # Stress indicators (XGBoost had these)
    full_df['Is_Low_Humidity'] = (full_df['Humidity_Mean_Pct'] < 65).astype(int)
    full_df['Is_High_Humidity'] = (full_df['Humidity_Mean_Pct'] > 92).astype(int)
    full_df['Consecutive_Stress_Days'] = full_df.groupby('Division_ID')['Is_Low_Humidity'].transform(
        lambda x: x.rolling(window=30, min_periods=1).sum()
    )
    
    # Humidity stress index
    full_df['Humidity_Stress_Index'] = (
        (full_df['Is_Low_Humidity'] * 1.5) + 
        (full_df['Is_High_Humidity'] * 1.0)
    )
    
    # Extreme stress
    full_df['Extreme_Humidity_Stress'] = (full_df['Humidity_Mean_Pct'] < 60).astype(int)
    
    # Humidity volatility (XGBoost had this)
    full_df['Humidity_Volatility'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(14, min_periods=2).std().fillna(0)
    )

# 2. VAPOR PRESSURE DEFICIT (VPD) - Important for plants!
print("   ✓ VPD calculation...")
if 'Temperature_Daily_C' in full_df.columns and 'Humidity_Mean_Pct' in full_df.columns:
    # Calculate VPD (Vapor Pressure Deficit) in kPa
    # Saturation vapor pressure (Tetens formula)
    full_df['SVP_kPa'] = 0.6108 * np.exp((17.27 * full_df['Temperature_Daily_C']) / 
                                       (full_df['Temperature_Daily_C'] + 237.3))
    # Actual vapor pressure
    full_df['AVP_kPa'] = (full_df['Humidity_Mean_Pct'] / 100) * full_df['SVP_kPa']
    # Vapor Pressure Deficit
    full_df['VPD_kPa'] = full_df['SVP_kPa'] - full_df['AVP_kPa']

# 3. TEMPERATURE FEATURES
print("   ✓ Temperature features...")
if 'Temperature_Daily_C' in full_df.columns:
    for window in [7, 14, 28]:
        full_df[f'Temperature_{window}D_Avg'] = full_df.groupby('Division_ID')['Temperature_Daily_C'].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )

# 4. RAINFALL FEATURES (XGBoost had Rain_4wk_Sum)
print("   ✓ Rainfall features...")
if 'Rainfall_Daily_mm' in full_df.columns:
    for window in [7, 14, 28]:
        full_df[f'Rainfall_{window}D_Avg'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )
        full_df[f'Rain_{window}D_Sum'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
            lambda x: x.rolling(window, min_periods=1).sum()
        )
    
    # XGBoost had Rain_4wk_Sum
    full_df['Rain_4wk_Sum'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
        lambda x: x.rolling(28, min_periods=1).sum()
    )

# 5. LABOR FEATURES
print("   ✓ Labor features...")
full_df['Labor_7D_Avg'] = full_df.groupby('Division_ID')['Labor_Total'].transform(
    lambda x: x.rolling(7, min_periods=1).mean()
)

# XGBoost had Kg_Per_Worker_Potential
if 'Kg_Per_Worker_Potential' in full_df.columns:
    full_df['Kg_Per_Worker_Potential'] = full_df['Kg_Per_Worker_Potential']
else:
    # Calculate it
    full_df['Kg_Per_Worker_Potential'] = full_df['Crop_Harvested_Kg'] / full_df['Labor_Safe']

# 6. CROP & YIELD FEATURES
print("   ✓ Crop & yield features...")
if 'Crop_Harvested_Kg' in full_df.columns:
    full_df['Crop_7D_Avg'] = full_df.groupby('Division_ID')['Crop_Harvested_Kg'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    
    # Yield momentum (XGBoost had this!)
    full_df['Yield_Lag_7D'] = full_df.groupby('Division_ID')['Target_Usable_Yield_Kg'].shift(7)
    full_df['Yield_Momentum'] = full_df['Target_Usable_Yield_Kg'] / (full_df['Yield_Lag_7D'] + 0.1)
    full_df['Yield_Momentum'] = full_df['Yield_Momentum'].fillna(1.0).clip(0.5, 2.0)

# 7. WASTAGE FEATURES
print("   ✓ Wastage features...")
if 'C_Pct' in full_df.columns and 'D_Pct' in full_df.columns:
    full_df['C_Half_Waste'] = full_df['C_Pct'] / 2
    full_df['Total_Waste_Pct'] = full_df['C_Half_Waste'] + full_df['D_Pct']
    
    if 'Calculated_Waste_Pct' in full_df.columns:
        full_df['Calculated_Waste_Pct'] = full_df['Calculated_Waste_Pct']

# 8. TEMPORAL FEATURES
print("   ✓ Temporal features...")
full_df['Month'] = full_df['Date'].dt.month
full_df['Week_of_Year'] = full_df['Date'].dt.isocalendar().week
full_df['Day_of_Year'] = full_df['Date'].dt.dayofyear
full_df['Day_of_Week'] = full_df['Date'].dt.dayofweek
full_df['Is_Weekend'] = full_df['Day_of_Week'].isin([5, 6]).astype(int)

# 9. INTERACTION FEATURES (XGBoost likely had these)
print("   ✓ Interaction features...")
full_df['Crop_x_G_Pct'] = full_df['Crop_Harvested_Kg'] * (full_df['G_Pct'] / 100)
full_df['Labor_x_Temp'] = full_df['Labor_Total'] * full_df['Temperature_Daily_C']
full_df['Humidity_x_Temp'] = full_df['Humidity_Mean_Pct'] * full_df['Temperature_Daily_C']

# 10. FIELD INTENSITY
if 'Est_Field_Size_Ha' in full_df.columns:
    full_df['Field_Intensity'] = full_df['Labor_Total'] / (full_df['Est_Field_Size_Ha'] + 0.1)

# ==========================================
# CREATE ONE-HOT ENCODING FOR DIVISION_ID (LIKE XGBOOST)
# ==========================================
print("\n Creating one-hot encoding for Division_ID (like XGBoost)...")
divisions = full_df['Division_ID'].unique()
print(f"   Divisions: {divisions}")

# Create one-hot encoded columns
for division in divisions:
    if division != 'ELT':  # Use ELT as baseline (like XGBoost did)
        col_name = f'Division_{division}'
        full_df[col_name] = (full_df['Division_ID'] == division).astype(int)
        print(f"   Created: {col_name}")

# ==========================================
# SELECT FINAL FEATURES (Match XGBoost's 34)
# ==========================================
print("\n Selecting final features...")

# One-hot encoded division features
division_features = [f'Division_{d}' for d in divisions if d != 'ELT']

# Numerical features (match XGBoost's "num__" features)
numerical_features = [
    # Humidity features (XGBoost had these)
    'Humidity_Mean_Pct', 'Humidity_Deficit', 'Humidity_3Day_Avg', 'Humidity_7Day_Avg',
    'Humidity_Std_7Day', 'Consecutive_Stress_Days', 'Humidity_Stress_Index',
    'Humidity_Volatility', 'Is_Low_Humidity', 'Is_High_Humidity', 'Extreme_Humidity_Stress',
    
    # Temperature
    'Temperature_Daily_C', 'Temperature_7D_Avg', 'Temperature_14D_Avg', 'Temperature_28D_Avg',
    
    # Rainfall
    'Rainfall_Daily_mm', 'Rainfall_7D_Avg', 'Rainfall_14D_Avg', 'Rainfall_28D_Avg',
    'Rain_7D_Sum', 'Rain_14D_Sum', 'Rain_28D_Sum', 'Rain_4wk_Sum',
    
    # VPD
    'VPD_kPa',
    
    # Labor
    'Labor_Total', 'Labor_7D_Avg', 'Kg_Per_Worker_Potential',
    
    # Crop/Yield
    'Crop_Harvested_Kg', 'Crop_7D_Avg', 'G_Pct', 'Total_Waste_Pct', 'Calculated_Waste_Pct',
    'Yield_Momentum',
    
    # Temporal
    'Month', 'Week_of_Year', 'Day_of_Year', 'Is_Weekend',
    
    # Interactions
    'Crop_x_G_Pct', 'Labor_x_Temp', 'Humidity_x_Temp',
    
    # Field
    'Field_Intensity'
]

# Filter to existing features
numerical_features = [f for f in numerical_features if f in full_df.columns]
all_features = division_features + numerical_features

print(f"   One-hot divisions: {len(division_features)}")
print(f"   Numerical features: {len(numerical_features)}")
print(f"   Total features: {len(all_features)}")
print(f"   XGBoost had: 34 features")

# ==========================================
# CREATE SPLITS
# ==========================================
print("\n Creating time-series splits...")
train_end = pd.to_datetime(train_df['Date']).max()
val_end = pd.to_datetime(val_df['Date']).max()

train_mask = full_df['Date'] <= train_end
val_mask = (full_df['Date'] > train_end) & (full_df['Date'] <= val_end)
test_mask = full_df['Date'] > val_end

print(f"   Train: {train_mask.sum():,} samples")
print(f"   Val:   {val_mask.sum():,} samples")
print(f"   Test:  {test_mask.sum():,} samples")

# ==========================================
# SAVE DATA
# ==========================================
print("\n Saving data...")

train_data = full_df[train_mask].copy()
val_data = full_df[val_mask].copy()
test_data = full_df[test_mask].copy()

# Features
train_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"), index=False)
val_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"), index=False)
test_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"), index=False)

# Targets
train_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv"), index=False)
val_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_val_log.csv"), index=False)
test_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_test_log.csv"), index=False)

# For evaluation
train_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"), index=False)
val_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"), index=False)
test_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"), index=False)

# Feature list
pd.DataFrame({'feature': all_features}).to_csv(
    os.path.join(PROCESSED_FOLDER, "features.csv"), index=False)

# Full dataset
full_df.to_csv(os.path.join(PROCESSED_FOLDER, "full_dataset.csv"), index=False)

print(f"   ✓ Saved to: {PROCESSED_FOLDER}")

# ==========================================
# SUMMARY
# ==========================================
print("\n" + "=" * 80)
print(" PREPROCESSING COMPLETE - XGBOOST COMPLETE REPLICATION")
print("=" * 80)

print(f"\n FEATURE COMPARISON:")
print(f"   XGBoost features: 34")
print(f"   Our features: {len(all_features)}")
