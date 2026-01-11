"""
XGBOOST PREPROCESSING
=============================================
This script handles the data preprocessing pipeline explicitly for the XGBoost model.
It performs feature engineering, target transformation, and data splitting, ensuring compatibility with the model's requirements.
"""

# Import pandas library for dataframe operations
import pandas as pd
# Import numpy library for numerical calculations
import numpy as np
# Import os module for file path handling
import os
# Import Path for object-oriented filesystem paths
from pathlib import Path
# Import StandardScaler (though not used for Labor to preserve scale)
from sklearn.preprocessing import StandardScaler

# Print a separator line for console output clarity
print("=" * 80)
# Print the script title
print("XGBOOST PREPROCESSING")
# Print another separator line
print("=" * 80)

# ==========================================
# CONFIGURATION
# ==========================================
# Define the root directory of the project
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# Define path to the raw dataset folder
DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# Define path where processed files will be saved
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Preprocessed_XGBoost_EXACT_CATBOOST")
# Create the processed folder if it doesn't exist
Path(PROCESSED_FOLDER).mkdir(parents=True, exist_ok=True)

# ==========================================
# LOAD DATA
# ==========================================
# Print status message
print("\nLoading data...")
# Read raw training data
train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
# Read raw validation data
val_df = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
# Read raw test data
test_df = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))

# Combine all datasets for uniform processing
full_df = pd.concat([train_df, val_df, test_df], ignore_index=True)
# Convert 'Date' column to datetime objects
full_df['Date'] = pd.to_datetime(full_df['Date'])
# Sort data by Division and Date to ensure correct rolling window calculations
full_df = full_df.sort_values(['Division_ID', 'Date']).reset_index(drop=True)

# Print summary statistics of the loaded data
print(f"Total samples: {len(full_df):,}")
# Print the date range covered
print(f"Date range: {full_df['Date'].min().date()} to {full_df['Date'].max().date()}")
# Print the count of unique divisions
print(f"Divisions: {full_df['Division_ID'].nunique()}")

# ==========================================
# CREATE TARGET
# ==========================================
# Print status message
print("\nCreating target...")
# Create a safe labor value to prevent division by zero
# Formula: Labor_Safe = max(Labor_Total, 1)
full_df['Labor_Safe'] = full_df['Labor_Total'].clip(lower=1)
# Calculate efficiency (Yield per worker)
# Formula: Efficiency = Target_Usable_Yield_Kg / Labor_Safe
full_df['Weekly_Efficiency'] = full_df['Target_Usable_Yield_Kg'] / full_df['Labor_Safe']
# Create the log-transformed target variable
# Formula: Target = ln(1 + Weekly_Efficiency)
full_df['Target_Log_Eff'] = np.log1p(full_df['Weekly_Efficiency'])
# Print the mean of the transformed target
print(f"Target mean (log): {full_df['Target_Log_Eff'].mean():.4f}")

# ==========================================
# CREATE FEATURES 
# ==========================================
# Print status message
print("\nCreating features...")

# 1. HUMIDITY FEATURES - SAME
# Print status for humidity features
print("  ✓ Humidity features...")
# Check if base humidity column exists
if 'Humidity_Mean_Pct' in full_df.columns:
    # Calculate 3-day rolling average
    # Formula: Mean(Humidity) over [t-2, t-1, t]
    full_df['Humidity_3Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(3, min_periods=1).mean()
    )
    # Calculate 7-day rolling average
    # Formula: Mean(Humidity) over [t-6, ..., t]
    full_df['Humidity_7Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    # Calculate 7-day rolling standard deviation
    # Formula: StdDev(Humidity) over 7 days
    full_df['Humidity_Std_7Day'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(7, min_periods=2).std().fillna(0)
    )
    # Calculate humidity deficit
    # Formula: Deficit = 100 - Humidity_Mean_Pct
    full_df['Humidity_Deficit'] = 100 - full_df['Humidity_Mean_Pct']
    # Create binary indicator for low humidity
    # Formula: 1 if Humidity < 65 else 0
    full_df['Is_Low_Humidity'] = (full_df['Humidity_Mean_Pct'] < 65).astype(int)
    # Create binary indicator for high humidity
    # Formula: 1 if Humidity > 92 else 0
    full_df['Is_High_Humidity'] = (full_df['Humidity_Mean_Pct'] > 92).astype(int)
    # Calculate consecutive days of low humidity stress
    # Formula: Sum(Is_Low_Humidity) over 30 days
    full_df['Consecutive_Stress_Days'] = full_df.groupby('Division_ID')['Is_Low_Humidity'].transform(
        lambda x: x.rolling(window=30, min_periods=1).sum()
    )
    # Calculate weighted humidity stress index
    # Formula: Index = (1.5 * Is_Low_Humidity) + (1.0 * Is_High_Humidity)
    full_df['Humidity_Stress_Index'] = ((full_df['Is_Low_Humidity'] * 1.5) + (full_df['Is_High_Humidity'] * 1.0))
    # Create binary indicator for extreme low humidity
    # Formula: 1 if Humidity < 60 else 0
    full_df['Extreme_Humidity_Stress'] = (full_df['Humidity_Mean_Pct'] < 60).astype(int)
    # Calculate long-term humidity volatility
    # Formula: StdDev(Humidity) over 14 days
    full_df['Humidity_Volatility'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(14, min_periods=2).std().fillna(0)
    )

# 2. VPD - SAME
# Print status for VPD
print("  ✓ VPD calculation...")
# Check if Temp and Humidity cols exist
if 'Temperature_Daily_C' in full_df.columns and 'Humidity_Mean_Pct' in full_df.columns:
    # Calculate Saturation Vapor Pressure (SVP) using Tetens formula
    # Formula: SVP = 0.6108 * exp((17.27 * Temp) / (Temp + 237.3))
    full_df['SVP_kPa'] = 0.6108 * np.exp((17.27 * full_df['Temperature_Daily_C']) / 
                                       (full_df['Temperature_Daily_C'] + 237.3))
    # Calculate Actual Vapor Pressure (AVP)
    # Formula: AVP = (Humidity_Pct / 100) * SVP
    full_df['AVP_kPa'] = (full_df['Humidity_Mean_Pct'] / 100) * full_df['SVP_kPa']
    # Calculate Vapor Pressure Deficit (VPD)
    # Formula: VPD = SVP - AVP
    full_df['VPD_kPa'] = full_df['SVP_kPa'] - full_df['AVP_kPa']

# 3. TEMPERATURE - SAME
# Print status for Temperature features
print("  ✓ Temperature features...")
# Check if Temperature col exists
if 'Temperature_Daily_C' in full_df.columns:
    # Loop through windows [7, 14, 28] days
    for window in [7, 14, 28]:
        # Calculate rolling mean temperature
        # Formula: Mean(Temperature) over window
        full_df[f'Temperature_{window}D_Avg'] = full_df.groupby('Division_ID')['Temperature_Daily_C'].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )

# 4. RAINFALL - SAME
# Print status for Rainfall features
print("  ✓ Rainfall features...")
# Check if Rainfall col exists
if 'Rainfall_Daily_mm' in full_df.columns:
    # Loop through windows [7, 14, 28] days
    for window in [7, 14, 28]:
        # Calculate rolling mean rainfall
        # Formula: Mean(Rainfall) over window
        full_df[f'Rainfall_{window}D_Avg'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )
        # Calculate rolling sum of rainfall
        # Formula: Sum(Rainfall) over window
        full_df[f'Rain_{window}D_Sum'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
            lambda x: x.rolling(window, min_periods=1).sum()
        )
    # Calculate specifically 4-week rainfall sum
    # Formula: Sum(Rainfall) over 28 days
    full_df['Rain_4wk_Sum'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
        lambda x: x.rolling(28, min_periods=1).sum()
    )

# 5. LABOR - SAME (NO SCALING!)
# Print status for Labor features
print("  ✓ Labor features...")
# Calculate 7-day rolling average of labor
# Formula: Mean(Labor_Total) over 7 days
full_df['Labor_7D_Avg'] = full_df.groupby('Division_ID')['Labor_Total'].transform(
    lambda x: x.rolling(7, min_periods=1).mean()
)

# Kg_Per_Worker_Potential - SAME
# Check if pre-computed potential exists
if 'Kg_Per_Worker_Potential' in full_df.columns:
    # Keep existing column
    full_df['Kg_Per_Worker_Potential'] = full_df['Kg_Per_Worker_Potential']
else:
    # Calculate potential if missing
    # Formula: Potential = Crop_Harvested_Kg / Labor_Safe
    full_df['Kg_Per_Worker_Potential'] = full_df['Crop_Harvested_Kg'] / full_df['Labor_Safe']

# 6. CROP & YIELD - SAME
# Print status for Crop/Yield features
print("  ✓ Crop & yield features...")
# Check if Crop Harvested col exists
if 'Crop_Harvested_Kg' in full_df.columns:
    # Calculate 7-day rolling average of crop harvested
    # Formula: Mean(Crop_Harvested_Kg) over 7 days
    full_df['Crop_7D_Avg'] = full_df.groupby('Division_ID')['Crop_Harvested_Kg'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    # Create lagged yield feature (7 days prior)
    # Formula: Lag7 = Target_Yield[t-7]
    full_df['Yield_Lag_7D'] = full_df.groupby('Division_ID')['Target_Usable_Yield_Kg'].shift(7)
    # Calculate Yield Momentum
    # Formula: Momentum = Current_Yield / (Yield_Lag_7D + 0.1)
    full_df['Yield_Momentum'] = full_df['Target_Usable_Yield_Kg'] / (full_df['Yield_Lag_7D'] + 0.1)
    # Clip momentum to safe range [0.5, 2.0]
    # Formula: Clip(Momentum, 0.5, 2.0)
    full_df['Yield_Momentum'] = full_df['Yield_Momentum'].fillna(1.0).clip(0.5, 2.0)

# 7. WASTAGE - SAME
# Print status for Wastage features
print("  ✓ Wastage features...")
# Check if Wastage cols exist
if 'C_Pct' in full_df.columns and 'D_Pct' in full_df.columns:
    # Calculate half of C-grade waste
    # Formula: C_Half = C_Pct / 2
    full_df['C_Half_Waste'] = full_df['C_Pct'] / 2
    # Calculate total effective waste
    # Formula: Total_Waste = C_Half + D_Pct
    full_df['Total_Waste_Pct'] = full_df['C_Half_Waste'] + full_df['D_Pct']
    
    # Keep calculated waste percent if it exists
    if 'Calculated_Waste_Pct' in full_df.columns:
        full_df['Calculated_Waste_Pct'] = full_df['Calculated_Waste_Pct']

# 8. TEMPORAL - SAME
# Print status for Temporal features
print("  ✓ Temporal features...")
# Extract month
full_df['Month'] = full_df['Date'].dt.month
# Extract week of year
full_df['Week_of_Year'] = full_df['Date'].dt.isocalendar().week
# Extract day of year
full_df['Day_of_Year'] = full_df['Date'].dt.dayofyear
# Extract day of week (0=Mon, 6=Sun)
full_df['Day_of_Week'] = full_df['Date'].dt.dayofweek
# Create weekend indicator
# Formula: 1 if Day_of_Week in [5, 6] else 0
full_df['Is_Weekend'] = full_df['Day_of_Week'].isin([5, 6]).astype(int)

# 9. INTERACTIONS - SAME
# Print status for Interaction features
print("  ✓ Interaction features...")
# Interaction: Crop * Green Leaf Pct
# Formula: Crop_Harvested * (G_Pct / 100)
full_df['Crop_x_G_Pct'] = full_df['Crop_Harvested_Kg'] * (full_df['G_Pct'] / 100)
# Interaction: Labor * Temperature
# Formula: Labor_Total * Temperature_Daily_C
full_df['Labor_x_Temp'] = full_df['Labor_Total'] * full_df['Temperature_Daily_C']
# Interaction: Humidity * Temperature
# Formula: Humidity_Mean_Pct * Temperature_Daily_C
full_df['Humidity_x_Temp'] = full_df['Humidity_Mean_Pct'] * full_df['Temperature_Daily_C']

# 10. FIELD INTENSITY - SAME
# Check if Field Size exists
if 'Est_Field_Size_Ha' in full_df.columns:
    # Calculate labor intensity per hectare
    # Formula: Intensity = Labor_Total / (Est_Field_Size_Ha + 0.1)
    full_df['Field_Intensity'] = full_df['Labor_Total'] / (full_df['Est_Field_Size_Ha'] + 0.1)

# 11. ONE-HOT ENCODING - SAME
# Print status for Encoding
print("  ✓ One-hot encoding for Division...")
# Get unique divisions
divisions = full_df['Division_ID'].unique()
# Create boolean columns for each division
for division in divisions:
    if division != 'ELT': # Use ELT as baseline
        # Formula: 1 if Division_ID == division else 0
        full_df[f'Division_{division}'] = (full_df['Division_ID'] == division).astype(int)

# ==========================================
# SELECT FINAL FEATURES
# ==========================================
# Print status message
print("\nSelecting final features...")

# Collect one-hot encoded division feature names
division_features = [f'Division_{d}' for d in divisions if d != 'ELT']

# Define list of numerical features to include
numerical_features = [
    # Humidity
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
    
    # Labor (NO SCALING applied here)
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

# Filter list to only include features that exist in the dataframe
numerical_features = [f for f in numerical_features if f in full_df.columns]
# Combine division and numerical features
all_features = division_features + numerical_features

# Print counts of selected features
print(f"Total features: {len(all_features)}")
print(f"  Division: {len(division_features)}")
print(f"  Numerical: {len(numerical_features)}")
print(f"  Target: log_efficiency")

# ==========================================
# CREATE SPLITS 
# ==========================================
# Print status message
print("\nCreating splits...")
# Determine split dates
train_end = pd.to_datetime(train_df['Date']).max()
val_end = pd.to_datetime(val_df['Date']).max()

# Create boolean masks for time-based splitting
train_mask = full_df['Date'] <= train_end
val_mask = (full_df['Date'] > train_end) & (full_df['Date'] <= val_end)
test_mask = full_df['Date'] > val_end

# Print dataset sizes using the masks
print(f"Train: {train_mask.sum():,} samples")
print(f"Val:   {val_mask.sum():,} samples")
print(f"Test:  {test_mask.sum():,} samples")

# ==========================================
# IMPORTANT: DO NOT SCALE LABOR!
# ==========================================
# Print status check for Labor scaling
print("\nCRITICAL: Checking labor is NOT scaled...")
# Get training slice to check statistics
train_data = full_df[train_mask].copy()

# Print mean and std of Labor_Total to verify it hasn't been standardized
print(f"  Labor_Total mean: {train_data['Labor_Total'].mean():.2f}")
print(f"  Labor_Total std:  {train_data['Labor_Total'].std():.2f}")

# Perform sanity check: if mean is very small (< 1), it might have been scaled
if abs(train_data['Labor_Total'].mean()) < 1:
    print("  ⚠️  WARNING: Labor appears to be scaled!")
    print("  This will cause XGBoost to fail!")
else:
    print("  ✅ GOOD: Labor is NOT scaled")

# ==========================================
# SAVE DATA 
# ==========================================
# Print status message
print("\nSaving data...")

# Create final dataframes for each split
train_data = full_df[train_mask].copy()
val_data = full_df[val_mask].copy()
test_data = full_df[test_mask].copy()

# Features (44 features)
# Save Training features
train_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"), index=False)
# Save Validation features
val_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"), index=False)
# Save Test features
test_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"), index=False)

# Targets - LOG EFFICIENCY
# Save Training Log Target
train_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv"), index=False)
# Save Validation Log Target
val_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_val_log.csv"), index=False)
# Save Test Log Target
test_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_test_log.csv"), index=False)

# KG targets for evaluation
# Save raw yield and labor for Training evaluation
train_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"), index=False)
# Save raw yield and labor for Validation evaluation
val_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"), index=False)
# Save raw yield and labor for Test evaluation
test_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"), index=False)

# Print final success message
print(f"\n✅ PREPROCESSING COMPLETE!")
print(f"Saved to: {PROCESSED_FOLDER}")
print(f"Features: {len(all_features)}")
print(f"Target: log_efficiency → kg")
print(f"Labor: NOT scaled")

# Print next steps guidance
print(f"\nNEXT STEPS:")
print("1. Run XGBoost training on log_efficiency target")
print("2. Convert predictions to kg using: kg = Labor_Safe × exp(log_efficiency)")

# Print final separator
print(f"\n" + "=" * 80)