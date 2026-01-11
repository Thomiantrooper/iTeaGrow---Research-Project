
# # # # import pandas as pd
# # # # import numpy as np

# # # # # Check your actual log efficiency values
# # # # log_eff = pd.read_csv(r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Pre_Processed_Thesis\y_train_log.csv").iloc[:, 0]

# # # # print(f"Log efficiency stats:")
# # # # print(f"Mean: {log_eff.mean():.3f}")
# # # # print(f"Std: {log_eff.std():.3f}")
# # # # print(f"Min: {log_eff.min():.3f}")
# # # # print(f"Max: {log_eff.max():.3f}")
# # # # print(f"Variance: {log_eff.var():.3f}")

# # # # # Check if there's any variation
# # # # print(f"\nUnique values: {log_eff.nunique()}")
# # # # print(f"Value counts of top 5:")
# # # # print(log_eff.value_counts().head())

# # # # # Check raw yield
# # # # raw_yield = pd.read_csv(r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Pre_Processed_Thesis\y_train_kg.csv").iloc[:, 0]
# # # # print(f"\nRaw yield stats:")
# # # # print(f"Mean: {raw_yield.mean():.1f}")
# # # # print(f"Std: {raw_yield.std():.1f}")
# # # # print(f"Min: {raw_yield.min():.1f}")
# # # # print(f"Max: {raw_yield.max():.1f}")

# # # """
# # # QUICK FIX FOR PREPROCESSING - CORRECT TARGET CREATION
# # # =====================================================
# # # Run this FIRST to check and fix your data
# # # """

# # # import pandas as pd
# # # import numpy as np
# # # import os

# # # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # # DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# # # PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis")

# # # print("="*80)
# # # print("DIAGNOSING DATA PROBLEM")
# # # print("="*80)

# # # # Load raw data
# # # train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))

# # # print(f"\nRaw data columns: {train_df.columns.tolist()}")
# # # print(f"\nFirst few rows of raw data:")
# # # print(train_df[['Target_Usable_Yield_Kg', 'Labor_Total']].head(10))

# # # # Calculate proper log efficiency
# # # train_df['Labor_Adjusted'] = train_df['Labor_Total'].clip(lower=1)
# # # train_df['Weekly_Efficiency'] = train_df['Target_Usable_Yield_Kg'] / train_df['Labor_Adjusted']
# # # train_df['Target_Log_Efficiency'] = np.log1p(train_df['Weekly_Efficiency'])

# # # print(f"\nCalculated efficiency stats:")
# # # print(f"Weekly Efficiency mean: {train_df['Weekly_Efficiency'].mean():.1f}")
# # # print(f"Weekly Efficiency range: {train_df['Weekly_Efficiency'].min():.1f} to {train_df['Weekly_Efficiency'].max():.1f}")
# # # print(f"Log Efficiency mean: {train_df['Target_Log_Efficiency'].mean():.3f}")
# # # print(f"Log Efficiency std: {train_df['Target_Log_Efficiency'].std():.3f}")
# # # print(f"Log Efficiency min: {train_df['Target_Log_Efficiency'].min():.3f}")
# # # print(f"Log Efficiency max: {train_df['Target_Log_Efficiency'].max():.3f}")

# # # # Check your processed data
# # # print("\n" + "="*80)
# # # print("CHECKING YOUR PROCESSED DATA")
# # # print("="*80)

# # # try:
# # #     your_log_eff = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv")).iloc[:, 0]
# # #     print(f"Your processed log efficiency stats:")
# # #     print(f"Mean: {your_log_eff.mean():.3f}")
# # #     print(f"Std: {your_log_eff.std():.3f}")
# # #     print(f"Min: {your_log_eff.min():.3f}")
# # #     print(f"Max: {your_log_eff.max():.3f}")
# # #     print(f"Variance: {your_log_eff.var():.3f}")
    
# # #     # Compare
# # #     print(f"\nCOMPARISON:")
# # #     print(f"Calculated mean: {train_df['Target_Log_Efficiency'].mean():.3f}")
# # #     print(f"Your processed mean: {your_log_eff.mean():.3f}")
# # #     print(f"Difference: {abs(train_df['Target_Log_Efficiency'].mean() - your_log_eff.mean()):.3f}")
    
# # #     if your_log_eff.var() < 0.01:
# # #         print("\n❌ PROBLEM FOUND: Your log efficiency has NO VARIANCE!")
# # #         print("   The model can't learn anything from constant values.")
# # #         print("\nSOLUTION: Recreate preprocessing with proper log transformation")
        
# # # except Exception as e:
# # #     print(f"Error loading your data: {e}")




# # """
# # QUICK FIX: USE YOUR SUCCESSFUL DATA FOR THESIS
# # ==============================================
# # Copy Pre_Processed11 to Thesis_Processed and continue
# # """

# # import shutil
# # import os

# # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # SOURCE_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed11")
# # TARGET_FOLDER = os.path.join(PROJECT_ROOT, "Thesis_Processed_Final")

# # print("="*80)
# # print("COPYING SUCCESSFUL DATA FOR THESIS")
# # print("="*80)

# # # Copy entire folder
# # if os.path.exists(SOURCE_FOLDER):
# #     if os.path.exists(TARGET_FOLDER):
# #         shutil.rmtree(TARGET_FOLDER)
    
# #     shutil.copytree(SOURCE_FOLDER, TARGET_FOLDER)
# #     print(f"✅ Copied {SOURCE_FOLDER} to {TARGET_FOLDER}")
# #     print(f"\nNow use {TARGET_FOLDER} for your thesis tuning!")
    
# #     # List files
# #     print(f"\nFiles available:")
# #     for file in os.listdir(TARGET_FOLDER):
# #         if file.endswith('.csv'):
# #             print(f"  - {file}")
# # else:
# #     print(f"❌ Source folder not found: {SOURCE_FOLDER}")





# import pandas as pd
# import numpy as np
# import os

# PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"

# # Compare successful data vs thesis data
# print("="*80)
# print("COMPARING SUCCESSFUL VS THESIS DATA")
# print("="*80)

# # Successful data (Pre_Processed11)
# success_x = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed11", "X_train.csv"))
# success_y = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed11", "y_train.csv")).iloc[:, 0]

# # Thesis data (Thesis_Processed_Final - which is just a copy of Pre_Processed11)
# thesis_x = pd.read_csv(os.path.join(PROJECT_ROOT, "Thesis_Processed_Final", "X_train.csv"))
# thesis_y = pd.read_csv(os.path.join(PROJECT_ROOT, "Thesis_Processed_Final", "y_train.csv")).iloc[:, 0]

# print(f"\nSUCCESSFUL DATA (Pre_Processed11):")
# print(f"X shape: {success_x.shape}")
# print(f"Y shape: {success_y.shape}")
# print(f"Y stats - Mean: {success_y.mean():.3f}, Std: {success_y.std():.3f}")
# print(f"\nFirst 5 features: {success_x.columns[:5].tolist()}")

# print(f"\nTHESIS DATA (Thesis_Processed_Final):")
# print(f"X shape: {thesis_x.shape}")
# print(f"Y shape: {thesis_y.shape}")
# print(f"Y stats - Mean: {thesis_y.mean():.3f}, Std: {thesis_y.std():.3f}")
# print(f"\nFirst 5 features: {thesis_x.columns[:5].tolist()}")

# print(f"\nCOMPARISON:")
# print(f"Same X shape? {success_x.shape == thesis_x.shape}")
# print(f"Same Y shape? {success_y.shape == thesis_y.shape}")
# print(f"Same features? {success_x.columns.tolist() == thesis_x.columns.tolist()}")
# print(f"Y correlation: {np.corrcoef(success_y, thesis_y)[0,1]:.6f}")

# # Check if features are standardized
# print(f"\nFEATURE STATS (first 5 features):")
# for i in range(min(5, success_x.shape[1])):
#     feat_name = success_x.columns[i]
#     print(f"\n{feat_name}:")
#     print(f"  Successful - Mean: {success_x.iloc[:, i].mean():.3f}, Std: {success_x.iloc[:, i].std():.3f}")
#     print(f"  Thesis     - Mean: {thesis_x.iloc[:, i].mean():.3f}, Std: {thesis_x.iloc[:, i].std():.3f}")

# # Check your tuning error - length mismatch
# print(f"\n" + "="*80)
# print("CHECKING FOR LENGTH MISMATCH")
# print("="*80)

# # Load all data from thesis preprocessing
# X_train = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "X_train.csv"))
# X_val = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "X_val.csv"))
# X_test = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "X_test.csv"))

# y_train_log = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "y_train_log.csv")).iloc[:, 0]
# y_val_log = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "y_val_log.csv")).iloc[:, 0]
# y_test_log = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "y_test_log.csv")).iloc[:, 0]

# y_train_kg = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "y_train_kg.csv")).iloc[:, 0]
# y_val_kg = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "y_val_kg.csv")).iloc[:, 0]
# y_test_kg = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "y_test_kg.csv")).iloc[:, 0]

# print(f"\nTHESIS PREPROCESSING DATA SHAPES:")
# print(f"X_train: {X_train.shape}")
# print(f"X_val: {X_val.shape}")
# print(f"X_test: {X_test.shape}")
# print(f"y_train_log: {y_train_log.shape}")
# print(f"y_val_log: {y_val_log.shape}")
# print(f"y_test_log: {y_test_log.shape}")
# print(f"y_train_kg: {y_train_kg.shape}")
# print(f"y_val_kg: {y_val_kg.shape}")
# print(f"y_test_kg: {y_test_kg.shape}")

# # Check if lengths match
# print(f"\nLENGTH CHECKS:")
# print(f"X_train vs y_train_log: {len(X_train) == len(y_train_log)}")
# print(f"X_val vs y_val_log: {len(X_val) == len(y_val_log)}")
# print(f"X_test vs y_test_log: {len(X_test) == len(y_test_log)}")

# print(f"\nTARGET RANGES:")
# print(f"y_train_log: {y_train_log.min():.3f} to {y_train_log.max():.3f}")
# print(f"y_train_kg: {y_train_kg.min():.1f} to {y_train_kg.max():.1f}")




"""
ANALYZING THE FEATURE DIFFERENCE
================================
Why thesis tuning failed: Different feature sets!
"""

import pandas as pd
import numpy as np
import os

PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"

print("="*80)
print("ANALYZING FEATURE DIFFERENCES")
print("="*80)

# Load feature sets
success_features = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed11", "X_train.csv")).columns.tolist()
thesis_features = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed_Thesis", "X_train.csv")).columns.tolist()

print(f"\nSuccessful data has {len(success_features)} features")
print(f"Thesis data has {len(thesis_features)} features")

# Find differences
success_set = set(success_features)
thesis_set = set(thesis_features)

print(f"\nFeatures in successful but NOT in thesis:")
missing_from_thesis = success_set - thesis_set
for feat in sorted(missing_from_thesis):
    print(f"  - {feat}")

print(f"\nFeatures in thesis but NOT in successful:")
extra_in_thesis = thesis_set - success_set
for feat in sorted(extra_in_thesis):
    print(f"  - {feat}")

print(f"\nFEATURE CATEGORY ANALYSIS:")

# Categorize successful features
def categorize_features(feature_list):
    categories = {
        'humidity': [],
        'temperature': [],
        'rainfall': [],
        'labor': [],
        'quality': [],
        'temporal': [],
        'division': [],
        'other': []
    }
    
    for feat in feature_list:
        feat_lower = feat.lower()
        if 'humid' in feat_lower:
            categories['humidity'].append(feat)
        elif 'temp' in feat_lower:
            categories['temperature'].append(feat)
        elif 'rain' in feat_lower:
            categories['rainfall'].append(feat)
        elif 'labor' in feat_lower or 'worker' in feat_lower:
            categories['labor'].append(feat)
        elif 'g_pct' in feat_lower or 'grade' in feat_lower:
            categories['quality'].append(feat)
        elif 'month' in feat_lower or 'week' in feat_lower or 'day' in feat_lower:
            categories['temporal'].append(feat)
        elif 'division' in feat_lower:
            categories['division'].append(feat)
        else:
            categories['other'].append(feat)
    
    return categories

print("\nSuccessful data feature categories:")
success_cats = categorize_features(success_features)
for cat, feats in success_cats.items():
    if feats:
        print(f"  {cat.capitalize()}: {len(feats)} features")

print("\nThesis data feature categories:")
thesis_cats = categorize_features(thesis_features)
for cat, feats in thesis_cats.items():
    if feats:
        print(f"  {cat.capitalize()}: {len(feats)} features")

print(f"\n" + "="*80)
print("SOLUTION: USE THE SUCCESSFUL FEATURE SET")
print("="*80)

# Load successful target data for context
y_train_success = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed11", "y_train.csv")).iloc[:, 0]
y_val_success = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed11", "y_val.csv")).iloc[:, 0]
y_test_success = pd.read_csv(os.path.join(PROJECT_ROOT, "Pre_Processed11", "y_test.csv")).iloc[:, 0]

# Convert to kg
y_train_kg_success = np.expm1(y_train_success)
y_val_kg_success = np.expm1(y_val_success)
y_test_kg_success = np.expm1(y_test_success)

print(f"\nSuccessful data targets (kg):")
print(f"  Training: {y_train_kg_success.mean():.1f} ± {y_train_kg_success.std():.1f} kg")
print(f"  Validation: {y_val_kg_success.mean():.1f} ± {y_val_kg_success.std():.1f} kg")
print(f"  Test: {y_test_kg_success.mean():.1f} ± {y_test_kg_success.std():.1f} kg")

# Check if we should use the successful data directly
print(f"\n" + "="*80)
print("RECOMMENDATION")
print("="*80)
print("\n✅ USE YOUR SUCCESSFUL DATA (Pre_Processed11/Thesis_Processed_Final):")
print(f"   • {len(success_features)} features (comprehensive)")
print(f"   • Already gave you R² = 0.792")
print(f"   • Properly engineered for humidity analysis")
print(f"   • Time-series aware splits")

print(f"\n❌ DON'T USE Thesis preprocessing (Pre_Processed_Thesis):")
print(f"   • Only {len(thesis_features)} features (missing key features)")
print(f"   • Different feature engineering")
print(f"   • Likely missing rolling statistics and interactions")

print(f"\n" + "="*80)
print("NEXT STEPS")
print("="*80)
print("1. Use Thesis_Processed_Final (copy of Pre_Processed11) for tuning")
print("2. Run the fixed tuning code I provided")
print("3. Expect R² ~0.79 as before")
print("4. Present results as yield prediction system for managers")