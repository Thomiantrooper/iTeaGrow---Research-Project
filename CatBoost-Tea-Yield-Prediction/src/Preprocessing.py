"""
CATBOOST PREPROCESSING
==================================================================
This script handles the data preprocessing pipeline specifically for the CatBoost model.
It loads raw data, creates features, performs target engineering, and saves the processed datasets.
"""

# Import pandas library for data manipulation and analysis
import pandas as pd
# Import numpy library for numerical operations and array handling
import numpy as np
# Import os module for operating system dependent functionality
import os
# Import Path class from pathlib for object-oriented filesystem paths
from pathlib import Path

# ==========================================
# CONFIGURATION
# ==========================================
# Define the root directory of the project
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction"
# Define the path to the dataset folder
DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# Define the path where processed data will be saved
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Preprocessed_CatBoost_XGBoost_Complete")
# Create the processed data directory if it doesn't exist, including parent directories
Path(PROCESSED_FOLDER).mkdir(parents=True, exist_ok=True)

# Print a separator line for visual clarity in the console
print("=" * 80)
# Print the title of the current process
print("CATBOOST PREPROCESSING")
# Print another separator line
print("=" * 80)

# ==========================================
# LOAD DATA
# ==========================================
# Print a message indicating that data loading has started
print("\n Loading data...")
# Read the training yield data from CSV file into a DataFrame
train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
# Read the validation yield data from CSV file into a DataFrame
val_df = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
# Read the test yield data from CSV file into a DataFrame
test_df = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))

# Concatenate train, validation, and test DataFrames into a single DataFrame for uniform processing
full_df = pd.concat([train_df, val_df, test_df], ignore_index=True)
# Convert the 'Date' column to datetime objects
full_df['Date'] = pd.to_datetime(full_df['Date'])
# Sort the DataFrame by 'Division_ID' and 'Date', then reset the index
full_df = full_df.sort_values(['Division_ID', 'Date']).reset_index(drop=True)

# Print the total number of samples in the combined dataset
print(f"   Total samples: {len(full_df)}")
# Print the date range of the data (earliest and latest dates)
print(f"   Date range: {full_df['Date'].min().date()} to {full_df['Date'].max().date()}")
# Print the number of unique divisions in the dataset
print(f"   Divisions: {full_df['Division_ID'].nunique()}")

# ==========================================
# CREATE CATBOOST'S TARGET
# ==========================================
# Print status message
print("\n Creating CatBoost's target...")
# Ensure Labor_Total is at least 1 to avoid division by zero, creating a safe labor column
# Formula: Labor_Safe = max(Labor_Total, 1)
full_df['Labor_Safe'] = full_df['Labor_Total'].clip(lower=1)
# Calculate Weekly Efficiency: Target Yield divided by Safe Labor
# Formula: Efficiency = Target_Usable_Yield_Kg / Labor_Safe
full_df['Weekly_Efficiency'] = full_df['Target_Usable_Yield_Kg'] / full_df['Labor_Safe']
# Create the target variable by taking the natural log of (1 + Weekly Efficiency) to normalize distribution
# Formula: Target = ln(1 + Weekly_Efficiency)
full_df['Target_Log_Eff'] = np.log1p(full_df['Weekly_Efficiency'])
# Print the mean of the new target variable formatted to 4 decimal places
print(f"   Target mean: {full_df['Target_Log_Eff'].mean():.4f}")

# ==========================================
# CREATE ALL CATBOOST FEATURES
# ==========================================
# Print status message for feature creation
print("\n Creating ALL CATBOOST features...")

# 1. HUMIDITY FEATURES
# Print status for humidity features
print("   ✓ Humidity stress features...")
# Check if humidity column exists in the dataframe
if 'Humidity_Mean_Pct' in full_df.columns:
    # Basic humidity stats
    # Calculate 3-day rolling average of humidity for each division
    # Formula: Mean(Humidity_Mean_Pct) over [t-2, t-1, t]
    full_df['Humidity_3Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(3, min_periods=1).mean()
    )
    # Calculate 7-day rolling average of humidity for each division
    # Formula: Mean(Humidity_Mean_Pct) over [t-6, ..., t]
    full_df['Humidity_7Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    # Calculate 7-day rolling standard deviation of humidity (volatility) filling NaNs with 0
    # Formula: StdDev(Humidity_Mean_Pct) over 7 days
    full_df['Humidity_Std_7Day'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(7, min_periods=2).std().fillna(0)
    )
    
    # Humidity deficit
    # Calculate humidity deficit as 100 minus the mean percentage
    # Formula: Deficit = 100 - Humidity_Mean_Pct
    full_df['Humidity_Deficit'] = 100 - full_df['Humidity_Mean_Pct']
    
    # Stress indicators
    # Create binary indicator for low humidity (< 65%)
    # Formula: 1 if Humidity < 65, else 0
    full_df['Is_Low_Humidity'] = (full_df['Humidity_Mean_Pct'] < 65).astype(int)
    # Create binary indicator for high humidity (> 92%)
    # Formula: 1 if Humidity > 92, else 0
    full_df['Is_High_Humidity'] = (full_df['Humidity_Mean_Pct'] > 92).astype(int)
    # Calculate count of consecutive stress days over a 30-day window
    # Formula: Sum(Is_Low_Humidity) over [t-29, ..., t]
    full_df['Consecutive_Stress_Days'] = full_df.groupby('Division_ID')['Is_Low_Humidity'].transform(
        lambda x: x.rolling(window=30, min_periods=1).sum()
    )
    
    # Humidity stress index
    # Create a composite stress index weighting low humidity more heavily than high humidity
    # Formula: Index = (1.5 * Is_Low_Humidity) + (1.0 * Is_High_Humidity)
    full_df['Humidity_Stress_Index'] = (
        (full_df['Is_Low_Humidity'] * 1.5) + 
        (full_df['Is_High_Humidity'] * 1.0)
    )
    
    # Extreme stress
    # Create binary indicator for extreme humidity stress (< 60%)
    # Formula: 1 if Humidity < 60, else 0
    full_df['Extreme_Humidity_Stress'] = (full_df['Humidity_Mean_Pct'] < 60).astype(int)
    
    # Humidity volatility
    # Calculate 14-day rolling standard deviation of humidity for long-term volatility
    # Formula: StdDev(Humidity) over 14 days
    full_df['Humidity_Volatility'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
        lambda x: x.rolling(14, min_periods=2).std().fillna(0)
    )

# 2. VAPOR PRESSURE DEFICIT (VPD) - Important for plants!
# Print status for VPD calculation
print("   ✓ VPD calculation...")
# Check if necessary columns exist for VPD calculation
if 'Temperature_Daily_C' in full_df.columns and 'Humidity_Mean_Pct' in full_df.columns:
    # Calculate VPD (Vapor Pressure Deficit) in kPa
    # Calculate Saturation Vapor Pressure using Tetens formula
    # Formula: SVP = 0.6108 * exp((17.27 * Temperature) / (Temperature + 237.3))
    full_df['SVP_kPa'] = 0.6108 * np.exp((17.27 * full_df['Temperature_Daily_C']) / 
                                       (full_df['Temperature_Daily_C'] + 237.3))
    # Calculate Actual Vapor Pressure based on humidity and SVP
    # Formula: AVP = (Humidity_Pct / 100) * SVP
    full_df['AVP_kPa'] = (full_df['Humidity_Mean_Pct'] / 100) * full_df['SVP_kPa']
    # Calculate Vapor Pressure Deficit as the difference between SVP and AVP
    # Formula: VPD = SVP - AVP
    full_df['VPD_kPa'] = full_df['SVP_kPa'] - full_df['AVP_kPa']

# 3. TEMPERATURE FEATURES
# Print status for temperature features
print("   ✓ Temperature features...")
# Check if temperature column exists
if 'Temperature_Daily_C' in full_df.columns:
    # Loop through different window sizes [7, 14, 28 days]
    for window in [7, 14, 28]:
        # Calculate rolling average temperature for the specified window size
        # Formula: Mean(Temperature) over K days
        full_df[f'Temperature_{window}D_Avg'] = full_df.groupby('Division_ID')['Temperature_Daily_C'].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )

# 4. RAINFALL FEATURES
# Print status for rainfall features
print("   ✓ Rainfall features...")
# Check if rainfall column exists
if 'Rainfall_Daily_mm' in full_df.columns:
    # Loop through different window sizes [7, 14, 28 days]
    for window in [7, 14, 28]:
        # Calculate rolling average rainfall for the window
        # Formula: Mean(Rainfall) over K days
        full_df[f'Rainfall_{window}D_Avg'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
            lambda x: x.rolling(window, min_periods=1).mean()
        )
        # Calculate rolling sum of rainfall for the window
        # Formula: Sum(Rainfall) over K days
        full_df[f'Rain_{window}D_Sum'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
            lambda x: x.rolling(window, min_periods=1).sum()
        )
    
    # Rain_4wk_Sum
    # Calculate 4-week (28 days) rolling sum of rainfall explicitly
    # Formula: Sum(Rainfall) over 28 days
    full_df['Rain_4wk_Sum'] = full_df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(
        lambda x: x.rolling(28, min_periods=1).sum()
    )

# 5. LABOR FEATURES
# Print status for labor features
print("   ✓ Labor features...")
# Calculate 7-day rolling average of total labor
# Formula: Mean(Labor_Total) over 7 days
full_df['Labor_7D_Avg'] = full_df.groupby('Division_ID')['Labor_Total'].transform(
    lambda x: x.rolling(7, min_periods=1).mean()
)

# Kg_Per_Worker_Potential
# Check if potential metric already exists
if 'Kg_Per_Worker_Potential' in full_df.columns:
    # Keep existing values
    full_df['Kg_Per_Worker_Potential'] = full_df['Kg_Per_Worker_Potential']
else:
    # Calculate it: Harvested Crop divided by Safe Labor
    # Formula: Potential = Crop_Harvested_Kg / Labor_Safe
    full_df['Kg_Per_Worker_Potential'] = full_df['Crop_Harvested_Kg'] / full_df['Labor_Safe']

# 6. CROP & YIELD FEATURES
# Print status for crop features
print("   ✓ Crop & yield features...")
# Check if crop harvested column exists
if 'Crop_Harvested_Kg' in full_df.columns:
    # Calculate 7-day rolling average of harvested crop
    # Formula: Mean(Crop_Harvested_Kg) over 7 days
    full_df['Crop_7D_Avg'] = full_df.groupby('Division_ID')['Crop_Harvested_Kg'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    
    # Yield momentum
    # Create a 7-day lag of target yield
    # Formula: Lag7 = Target_Yield[t-7]
    full_df['Yield_Lag_7D'] = full_df.groupby('Division_ID')['Target_Usable_Yield_Kg'].shift(7)
    # Calculate momentum: Current Yield divided by (Lagged Yield + small epsilon)
    # Formula: Momentum = Target_Yield / (Yield_Lag_7D + 0.1)
    full_df['Yield_Momentum'] = full_df['Target_Usable_Yield_Kg'] / (full_df['Yield_Lag_7D'] + 0.1)
    # Fill NaNs with 1.0 and clip momentum values to be between 0.5 and 2.0
    # Formula: Clip(Momentum, 0.5, 2.0)
    full_df['Yield_Momentum'] = full_df['Yield_Momentum'].fillna(1.0).clip(0.5, 2.0)

# 7. WASTAGE FEATURES
# Print status for wastage features
print("   ✓ Wastage features...")
# Check if required wastage columns exist
if 'C_Pct' in full_df.columns and 'D_Pct' in full_df.columns:
    # Calculate half of C waste percentage
    # Formula: C_Half = C_Pct / 2
    full_df['C_Half_Waste'] = full_df['C_Pct'] / 2
    # Calculate total waste percentage as sum of half C and all D waste
    # Formula: Total_Waste = C_Half + D_Pct
    full_df['Total_Waste_Pct'] = full_df['C_Half_Waste'] + full_df['D_Pct']
    
    # Update Calculated_Waste_Pct if it exists
    if 'Calculated_Waste_Pct' in full_df.columns:
        full_df['Calculated_Waste_Pct'] = full_df['Calculated_Waste_Pct']

# 8. TEMPORAL FEATURES
# Print status for temporal features
print("   ✓ Temporal features...")
# Extract month from Date
full_df['Month'] = full_df['Date'].dt.month
# Extract week of year from Date
full_df['Week_of_Year'] = full_df['Date'].dt.isocalendar().week
# Extract day of year from Date
full_df['Day_of_Year'] = full_df['Date'].dt.dayofyear
# Extract day of week from Date (0=Monday, 6=Sunday)
full_df['Day_of_Week'] = full_df['Date'].dt.dayofweek
# Create binary indicator for weekend (Saturday=5, Sunday=6)
# Formula: 1 if Day_of_Week in [5, 6], else 0
full_df['Is_Weekend'] = full_df['Day_of_Week'].isin([5, 6]).astype(int)

# 9. INTERACTION FEATURES
# Print status for interaction features
print("   ✓ Interaction features...")
# Interaction: Crop Harvested * G Percentage (fraction)
# Formula: Crop * (G_Pct / 100)
full_df['Crop_x_G_Pct'] = full_df['Crop_Harvested_Kg'] * (full_df['G_Pct'] / 100)
# Interaction: Labor Total * Daily Temperature
# Formula: Labor_Total * Temperature_Daily_C
full_df['Labor_x_Temp'] = full_df['Labor_Total'] * full_df['Temperature_Daily_C']
# Interaction: Humidity Mean * Daily Temperature
# Formula: Humidity_Mean_Pct * Temperature_Daily_C
full_df['Humidity_x_Temp'] = full_df['Humidity_Mean_Pct'] * full_df['Temperature_Daily_C']

# 10. FIELD INTENSITY
# Check if Field Size column exists
if 'Est_Field_Size_Ha' in full_df.columns:
    # Calculate Field Intensity: Labor Total divided by Field Size (with epsilon)
    # Formula: Intensity = Labor_Total / (Est_Field_Size_Ha + 0.1)
    full_df['Field_Intensity'] = full_df['Labor_Total'] / (full_df['Est_Field_Size_Ha'] + 0.1)

# ==========================================
# CREATE ONE-HOT ENCODING FOR DIVISION_ID 
# ==========================================
# Print status message
print("\n Creating one-hot encoding for Division_ID...")
# Get unique division IDs from the dataframe
divisions = full_df['Division_ID'].unique()
# Print list of divisions found
print(f"   Divisions: {divisions}")

# Create one-hot encoded columns
# Loop through each division
for division in divisions:
    # Skip 'ELT' to use it as the baseline category
    if division != 'ELT':  # Use ELT as baseline
        # Define new column name
        col_name = f'Division_{division}'
        # Create binary column: 1 if row belongs to division, 0 otherwise
        # Formula: 1 if Division_ID == current_division, else 0
        full_df[col_name] = (full_df['Division_ID'] == division).astype(int)
        # Print confirmation of column creation
        print(f"   Created: {col_name}")

# ==========================================
# SELECT FINAL FEATURES
# ==========================================
# Print status message
print("\n Selecting final features...")

# One-hot encoded division features
# Create list of division feature names (excluding ELT)
division_features = [f'Division_{d}' for d in divisions if d != 'ELT']

# Numerical features ("num__" features)
# Define list of all numerical features to include
numerical_features = [
    # Humidity features
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
# Keep only features that actually exist in the dataframe columns
numerical_features = [f for f in numerical_features if f in full_df.columns]
# Combine division features and numerical features into one list
all_features = division_features + numerical_features

# Print counts of features
print(f"   One-hot divisions: {len(division_features)}")
print(f"   Numerical features: {len(numerical_features)}")
print(f"   Total features: {len(all_features)}")
print(f"   XGBoost had: 34 features")

# ==========================================
# CREATE SPLITS
# ==========================================
# Print status message
print("\n Creating time-series splits...")
# Determine the end date of the training set
train_end = pd.to_datetime(train_df['Date']).max()
# Determine the end date of the validation set
val_end = pd.to_datetime(val_df['Date']).max()

# Create boolean mask for training data (dates <= train_end)
train_mask = full_df['Date'] <= train_end
# Create boolean mask for validation data (dates > train_end AND <= val_end)
val_mask = (full_df['Date'] > train_end) & (full_df['Date'] <= val_end)
# Create boolean mask for test data (dates > val_end)
test_mask = full_df['Date'] > val_end

# Print number of samples in each split
print(f"   Train: {train_mask.sum():,} samples")
print(f"   Val:   {val_mask.sum():,} samples")
print(f"   Test:  {test_mask.sum():,} samples")

# ==========================================
# SAVE DATA
# ==========================================
# Print status message
print("\n Saving data...")

# Create separate dataframes for each split using the masks
train_data = full_df[train_mask].copy()
val_data = full_df[val_mask].copy()
test_data = full_df[test_mask].copy()

# Features
# Save X_train.csv with selected features
train_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"), index=False)
# Save X_val.csv with selected features
val_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"), index=False)
# Save X_test.csv with selected features
test_data[all_features].to_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"), index=False)

# Targets
# Save y_train_log.csv (target)
train_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv"), index=False)
# Save y_val_log.csv (target)
val_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_val_log.csv"), index=False)
# Save y_test_log.csv (target)
test_data[['Target_Log_Eff']].to_csv(os.path.join(PROCESSED_FOLDER, "y_test_log.csv"), index=False)

# For evaluation
# Save auxiliary data for evaluation (Yield Kg, Labor Safe) for train set
train_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"), index=False)
# Save auxiliary data for evaluation for validation set
val_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"), index=False)
# Save auxiliary data for evaluation for test set
test_data[['Target_Usable_Yield_Kg', 'Labor_Safe']].to_csv(
    os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"), index=False)

# Feature list
# Save the list of feature names to a CSV file
pd.DataFrame({'feature': all_features}).to_csv(
    os.path.join(PROCESSED_FOLDER, "features.csv"), index=False)

# Full dataset
# Save the complete processed dataframe to CSV
full_df.to_csv(os.path.join(PROCESSED_FOLDER, "full_dataset.csv"), index=False)

# Print confirmation of save location
print(f"   ✓ Saved to: {PROCESSED_FOLDER}")

# ==========================================
# SUMMARY
# ==========================================
# Print separator
print("\n" + "=" * 80)
# Print completion message
print(" PREPROCESSING COMPLETED")
# Print separator
print("=" * 80)
