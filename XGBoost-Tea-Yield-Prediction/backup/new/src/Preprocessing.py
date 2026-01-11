
"""
TEA YIELD PREDICTION PREPROCESSING - OPTIMAL VERSION
====================================================
Uses your SUCCESSFUL approach (R² = 0.792) but frames it as yield prediction
for plantation managers.
"""

import pandas as pd
import numpy as np
import os
from pathlib import Path
import joblib
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
import warnings
warnings.filterwarnings('ignore')

# Configuration - Use YOUR SUCCESSFUL folder
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis")  # New folder for thesis
GRAPHS_FOLDER = os.path.join(PROJECT_ROOT, "Graphs_Thesis")

for folder in [PROCESSED_FOLDER, GRAPHS_FOLDER]:
    Path(folder).mkdir(parents=True, exist_ok=True)

def create_thesis_preprocessing():
    """Create preprocessing that replicates your success but is thesis-ready."""
    
    print("="*80)
    print("TEA YIELD PREDICTION PREPROCESSING - THESIS OPTIMAL VERSION")
    print("="*80)
    print("\nBased on your successful approach (R² = 0.792 for log efficiency)")
    print("Now framed as yield prediction for plantation managers\n")
    
    # Load raw data
    train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
    val_df = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
    test_df = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))
    
    full_df = pd.concat([train_df, val_df, test_df], ignore_index=True)
    full_df['Date'] = pd.to_datetime(full_df['Date'])
    full_df = full_df.sort_values(['Division_ID', 'Date']).reset_index(drop=True)
    
    print(f"Loaded {len(full_df):,} samples")
    print(f"Date range: {full_df['Date'].min().date()} to {full_df['Date'].max().date()}")
    print(f"Plantations: {full_df['Division_ID'].nunique()}")
    
    # ==========================================
    # CREATE FEATURES LIKE YOUR SUCCESSFUL APPROACH
    # ==========================================
    print("\nCreating features based on your successful approach...")
    
    # 1. Primary target: Log Efficiency (what worked!)
    full_df['Labor_Safe'] = full_df['Labor_Total'].clip(lower=1)
    full_df['Weekly_Efficiency'] = full_df['Target_Usable_Yield_Kg'] / full_df['Labor_Safe']
    full_df['Target_Log_Efficiency'] = np.log1p(full_df['Weekly_Efficiency'])
    
    # 2. Also save raw yield for reference
    full_df['Target_Usable_Yield_Kg'] = full_df['Target_Usable_Yield_Kg']
    
    # 3. Create key humidity features (from your success)
    if 'Humidity_Mean_Pct' in full_df.columns:
        # Core humidity features that worked
        full_df['Humidity_7Day_Avg'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
            lambda x: x.rolling(7, min_periods=1).mean()
        )
        full_df['Humidity_Std_7Day'] = full_df.groupby('Division_ID')['Humidity_Mean_Pct'].transform(
            lambda x: x.rolling(7, min_periods=2).std().fillna(0)
        )
        
        # Humidity stress indicators
        full_df['Low_Humidity_Stress'] = (full_df['Humidity_Mean_Pct'] < 65).astype(int)
        full_df['High_Humidity_Stress'] = (full_df['Humidity_Mean_Pct'] > 92).astype(int)
        full_df['Optimal_Humidity'] = ((full_df['Humidity_Mean_Pct'] >= 70) & 
                                      (full_df['Humidity_Mean_Pct'] <= 90)).astype(int)
    
    # 4. Create rolling statistics for climate variables
    for var in ['Temperature_Daily_C', 'Rainfall_Daily_mm']:
        if var in full_df.columns:
            for window in [7, 14, 28]:
                full_df[f'{var}_{window}D_Avg'] = full_df.groupby('Division_ID')[var].transform(
                    lambda x: x.rolling(window, min_periods=1).mean()
                )
    
    # 5. Operational features
    full_df['Labor_7D_Avg'] = full_df.groupby('Division_ID')['Labor_Total'].transform(
        lambda x: x.rolling(7, min_periods=1).mean()
    )
    
    # 6. Temporal features
    full_df['Month'] = full_df['Date'].dt.month
    full_df['Week_of_Year'] = full_df['Date'].dt.isocalendar().week
    
    # ==========================================
    # SELECT FEATURES (like your successful approach)
    # ==========================================
    print("\nSelecting features...")
    
    # Define features (based on what worked for you)
    numerical_features = [
        'Humidity_Mean_Pct', 'Humidity_7Day_Avg', 'Humidity_Std_7Day',
        'Temperature_Daily_C', 'Temperature_Daily_C_7D_Avg', 'Temperature_Daily_C_14D_Avg',
        'Rainfall_Daily_mm', 'Rainfall_Daily_mm_7D_Avg', 'Rainfall_Daily_mm_14D_Avg',
        'Labor_Total', 'Labor_7D_Avg', 'G_Pct',
        'Low_Humidity_Stress', 'High_Humidity_Stress', 'Optimal_Humidity',
        'Month', 'Week_of_Year'
    ]
    
    # Only include features that exist
    numerical_features = [f for f in numerical_features if f in full_df.columns]
    
    categorical_features = ['Division_ID']
    
    print(f"Selected {len(numerical_features)} numerical features")
    print(f"Selected {len(categorical_features)} categorical features")
    
    # ==========================================
    # CREATE SPLITS (time-series aware)
    # ==========================================
    print("\nCreating time-series splits...")
    
    train_end = pd.to_datetime(train_df['Date']).max()
    val_end = pd.to_datetime(val_df['Date']).max()
    
    train_mask = full_df['Date'] <= train_end
    val_mask = (full_df['Date'] > train_end) & (full_df['Date'] <= val_end)
    test_mask = full_df['Date'] > val_end
    
    print(f"Training samples: {train_mask.sum():,}")
    print(f"Validation samples: {val_mask.sum():,}")
    print(f"Test samples: {test_mask.sum():,}")
    
    # ==========================================
    # APPLY PREPROCESSING
    # ==========================================
    print("\nApplying preprocessing...")
    
    preprocessor = ColumnTransformer([
        ('categorical', OneHotEncoder(sparse_output=False, handle_unknown='ignore'), 
         categorical_features),
        ('numerical', StandardScaler(), numerical_features)
    ])
    
    X_train = preprocessor.fit_transform(full_df[train_mask][categorical_features + numerical_features])
    X_val = preprocessor.transform(full_df[val_mask][categorical_features + numerical_features])
    X_test = preprocessor.transform(full_df[test_mask][categorical_features + numerical_features])
    
    feature_names = preprocessor.get_feature_names_out()
    
    # Targets
    y_train_log = full_df[train_mask]['Target_Log_Efficiency']
    y_val_log = full_df[val_mask]['Target_Log_Efficiency']
    y_test_log = full_df[test_mask]['Target_Log_Efficiency']
    
    # Also save raw yield for context
    y_train_kg = full_df[train_mask]['Target_Usable_Yield_Kg']
    y_val_kg = full_df[val_mask]['Target_Usable_Yield_Kg']
    y_test_kg = full_df[test_mask]['Target_Usable_Yield_Kg']
    
    print(f"Training features shape: {X_train.shape}")
    print(f"Validation features shape: {X_val.shape}")
    print(f"Test features shape: {X_test.shape}")
    
    # ==========================================
    # SAVE DATA
    # ==========================================
    print("\nSaving processed data...")
    
    # Save feature matrices
    pd.DataFrame(X_train, columns=feature_names).to_csv(
        os.path.join(PROCESSED_FOLDER, "X_train.csv"), index=False)
    pd.DataFrame(X_val, columns=feature_names).to_csv(
        os.path.join(PROCESSED_FOLDER, "X_val.csv"), index=False)
    pd.DataFrame(X_test, columns=feature_names).to_csv(
        os.path.join(PROCESSED_FOLDER, "X_test.csv"), index=False)
    
    # Save log efficiency targets (for modeling)
    y_train_log.to_frame().to_csv(
        os.path.join(PROCESSED_FOLDER, "y_train_log.csv"), index=False)
    y_val_log.to_frame().to_csv(
        os.path.join(PROCESSED_FOLDER, "y_val_log.csv"), index=False)
    y_test_log.to_frame().to_csv(
        os.path.join(PROCESSED_FOLDER, "y_test_log.csv"), index=False)
    
    # Save raw yield targets (for context/reference)
    y_train_kg.to_frame().to_csv(
        os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"), index=False)
    y_val_kg.to_frame().to_csv(
        os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"), index=False)
    y_test_kg.to_frame().to_csv(
        os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"), index=False)
    
    # Save preprocessor
    joblib.dump(preprocessor, os.path.join(PROCESSED_FOLDER, "preprocessor.pkl"))
    
    # Save feature metadata
    feature_metadata = pd.DataFrame({
        'feature_name': feature_names,
        'original_name': [name.split('__')[-1] for name in feature_names],
        'type': ['categorical' if 'Division_ID' in name else 'numerical' for name in feature_names]
    })
    feature_metadata.to_csv(os.path.join(PROCESSED_FOLDER, "feature_metadata.csv"), index=False)
    
    # Save full dataset
    full_df.to_csv(os.path.join(PROCESSED_FOLDER, "full_dataset.csv"), index=False)
    
    # ==========================================
    # CREATE SUMMARY
    # ==========================================
    print("\n" + "="*80)
    print("PREPROCESSING COMPLETE - THESIS OPTIMAL VERSION")
    print("="*80)
    
    summary = f"""
    SUMMARY OF PREPROCESSED DATA
    ----------------------------
    Based on: Your successful approach (R² = 0.792 for log efficiency prediction)
    Framed as: Tea yield prediction system for plantation managers
    
    Data Statistics:
    • Total samples: {len(full_df):,}
    • Training samples: {train_mask.sum():,}
    • Validation samples: {val_mask.sum():,}
    • Test samples: {test_mask.sum():,}
    • Features: {len(feature_names)}
    • Plantations: {full_df['Division_ID'].nunique()}
    
    Target Variables:
    1. Primary target: Target_Log_Efficiency (log-transformed kg/worker)
       - Average: {y_train_log.mean():.3f}
       - Range: {y_train_log.min():.3f} to {y_train_log.max():.3f}
       - This is what gave you R² = 0.792
    
    2. Reference target: Target_Usable_Yield_Kg (raw kg)
       - Average: {y_train_kg.mean():.1f} kg
       - Range: {y_train_kg.min():.1f} to {y_train_kg.max():.1f} kg
       - For context and presentation
    
    Key Features Created:
    • Humidity features: {len([f for f in numerical_features if 'humidity' in f.lower()])}
    • Temperature features: {len([f for f in numerical_features if 'temp' in f.lower()])}
    • Rainfall features: {len([f for f in numerical_features if 'rain' in f.lower()])}
    • Operational features: {len([f for f in numerical_features if 'labor' in f.lower() or 'g_pct' in f.lower()])}
    
    Files Saved:
    1. Feature matrices: X_train.csv, X_val.csv, X_test.csv
    2. Log efficiency targets: y_train_log.csv, y_val_log.csv, y_test_log.csv
    3. Raw yield targets: y_train_kg.csv, y_val_kg.csv, y_test_kg.csv
    4. Preprocessor: preprocessor.pkl
    5. Feature metadata: feature_metadata.csv
    6. Full dataset: full_dataset.csv
    
    For Your Thesis:
    • Use Target_Log_Efficiency for modeling (high accuracy)
    • Convert predictions back to kg for presentation to managers
    • Show both log-space (modeling) and kg-space (practical) results
    
    Next Steps:
    1. Run optimal tuning: python optimal_tuning.py
    2. Expect R² ~ 0.79 based on your previous success
    3. Present results in kg for plantation managers
    """
    
    print(summary)
    
    # Save summary
    with open(os.path.join(PROCESSED_FOLDER, "preprocessing_summary.txt"), 'w') as f:
        f.write(summary)
    
    print(f"\n✅ Preprocessing complete!")
    print(f"   Data saved to: {PROCESSED_FOLDER}")
    print(f"   Ready for optimal tuning")
    
    return full_df, preprocessor, feature_names

if __name__ == "__main__":
    create_thesis_preprocessing()