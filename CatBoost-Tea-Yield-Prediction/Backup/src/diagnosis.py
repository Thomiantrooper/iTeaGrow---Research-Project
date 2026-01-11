# # # # # # # """
# # # # # # # Check the relationship between columns
# # # # # # # """
# # # # # # # import pandas as pd
# # # # # # # import numpy as np

# # # # # # # # Load original data
# # # # # # # train = pd.read_csv(r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\dataset\train_yield.csv")

# # # # # # # print("=" * 80)
# # # # # # # print("COLUMN RELATIONSHIP CHECK")
# # # # # # # print("=" * 80)

# # # # # # # print("\nColumns in dataset:")
# # # # # # # print(train.columns.tolist())

# # # # # # # print("\n1. First 10 rows of key columns:")
# # # # # # # cols_to_check = ['Crop_Harvested_Kg', 'Target_Usable_Yield_Kg', 'G_Pct', 'C_Pct', 'D_Pct', 'Labor_Total']
# # # # # # # print(train[cols_to_check].head(10))

# # # # # # # print("\n2. Calculate relationship:")
# # # # # # # print("   Is Target_Usable_Yield derived from Crop_Harvested_Kg?")

# # # # # # # # Check if: Usable = Crop * (G% / 100)
# # # # # # # train['Calculated_Usable'] = train['Crop_Harvested_Kg'] * (train['G_Pct'] / 100)
# # # # # # # train['Diff'] = abs(train['Target_Usable_Yield_Kg'] - train['Calculated_Usable'])

# # # # # # # print(f"\n   Mean difference: {train['Diff'].mean():.2f}")
# # # # # # # print(f"   Max difference: {train['Diff'].max():.2f}")
# # # # # # # print(f"   Correlation: {train['Crop_Harvested_Kg'].corr(train['Target_Usable_Yield_Kg']):.4f}")

# # # # # # # print("\n3. First 10 comparisons:")
# # # # # # # print(train[['Crop_Harvested_Kg', 'G_Pct', 'Calculated_Usable', 'Target_Usable_Yield_Kg', 'Diff']].head(10))

# # # # # # # print("\n4. THIS IS THE PROBLEM!")
# # # # # # # if train['Diff'].mean() < 1:
# # # # # # #     print("   ✅ Target_Usable_Yield_Kg = Crop_Harvested_Kg × (G_Pct / 100)")
# # # # # # #     print("   ⚠️  We CANNOT use Crop_Harvested_Kg as a feature!")
# # # # # # #     print("   ⚠️  That's like giving the model the answer!")
# # # # # # # else:
# # # # # # #     print("   They are different - Crop can be used as feature")

# # # # # # # print("\n5. What should we predict?")
# # # # # # # print("   Option A: Predict Crop_Harvested_Kg (total harvest)")
# # # # # # # print("   Option B: Predict without using Crop as feature")
# # # # # # # print("   Option C: Check what XGBoost actually did")

# # # # # # # print("\n" + "=" * 80)




# # # # # # """
# # # # # # Check if Crop_Harvested_Kg is in the data after preprocessing
# # # # # # """
# # # # # # import pandas as pd

# # # # # # DATA_FOLDER = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\dataset"

# # # # # # print("=" * 80)
# # # # # # print("CHECKING CROP COLUMN")
# # # # # # print("=" * 80)

# # # # # # # Check raw data
# # # # # # train = pd.read_csv(f"{DATA_FOLDER}/train_yield.csv")
# # # # # # print("\n1. RAW DATA COLUMNS:")
# # # # # # print(train.columns.tolist())
# # # # # # print(f"\n   'Crop_Harvested_Kg' in raw data? {'Crop_Harvested_Kg' in train.columns}")

# # # # # # # Check preprocessed data
# # # # # # PROC_FOLDER = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost"
# # # # # # X_train = pd.read_csv(f"{PROC_FOLDER}/X_train.csv")

# # # # # # print("\n2. PREPROCESSED DATA COLUMNS:")
# # # # # # print(X_train.columns.tolist())
# # # # # # print(f"\n   'Crop_Harvested_Kg' in preprocessed? {'Crop_Harvested_Kg' in X_train.columns}")
# # # # # # print(f"   'Crop_7D_Avg' in preprocessed? {'Crop_7D_Avg' in X_train.columns}")

# # # # # # print("\n3. THE ISSUE:")
# # # # # # if 'Crop_Harvested_Kg' not in X_train.columns:
# # # # # #     print("   ❌ Crop_Harvested_Kg is NOT in the features!")
# # # # # #     print("   ❌ This is why R² = 0.28")
# # # # # #     print("   ✅ Need to add it to get R² = 0.75+")
# # # # # # else:
# # # # # #     print("   ✅ Crop_Harvested_Kg is in features")
# # # # # #     print("   Something else is wrong")

# # # # # # print("\n4. STATISTICS:")
# # # # # # if 'Crop_Harvested_Kg' in train.columns:
# # # # # #     print(f"   Crop_Harvested_Kg mean: {train['Crop_Harvested_Kg'].mean():.1f}")
# # # # # #     print(f"   Target_Usable_Yield_Kg mean: {train['Target_Usable_Yield_Kg'].mean():.1f}")
# # # # # #     print(f"   Correlation: {train['Crop_Harvested_Kg'].corr(train['Target_Usable_Yield_Kg']):.4f}")

# # # # # # print("\n" + "=" * 80)




# # # # # """
# # # # # Verify the new preprocessed data has everything
# # # # # """
# # # # # import pandas as pd
# # # # # import numpy as np

# # # # # PROC = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost"

# # # # # print("=" * 80)
# # # # # print("VERIFY NEW PREPROCESSED DATA")
# # # # # print("=" * 80)

# # # # # X_train = pd.read_csv(f"{PROC}/X_train.csv")
# # # # # y_train_log = pd.read_csv(f"{PROC}/y_train_log.csv")
# # # # # y_train_kg = pd.read_csv(f"{PROC}/y_train_kg.csv")

# # # # # print(f"\n✅ X_train shape: {X_train.shape}")
# # # # # print(f"✅ Features ({X_train.shape[1]}):")
# # # # # for i, col in enumerate(X_train.columns, 1):
# # # # #     print(f"   {i:2d}. {col}")

# # # # # print(f"\n✅ y_train_log:")
# # # # # print(f"   Column: {y_train_log.columns[0]}")
# # # # # print(f"   Mean: {y_train_log.iloc[:, 0].mean():.4f}")
# # # # # print(f"   Is this log(yield)? Mean ~7.14? {6.5 < y_train_log.iloc[:, 0].mean() < 7.5}")

# # # # # print(f"\n✅ y_train_kg:")
# # # # # print(f"   Column: {y_train_kg.columns[0]}")
# # # # # print(f"   Mean: {y_train_kg.iloc[:, 0].mean():.1f} kg")

# # # # # print("\n✅ KEY FEATURES CHECK:")
# # # # # key_features = ['Crop_Harvested_Kg', 'Crop_7D_Avg', 'Labor_Total', 'G_Pct', 'Total_Waste_Pct']
# # # # # for feat in key_features:
# # # # #     status = "✓" if feat in X_train.columns else "✗"
# # # # #     print(f"   {status} {feat}")

# # # # # print("\n✅ SAMPLE DATA (first 3 rows):")
# # # # # print(X_train[['Division_ID', 'Crop_Harvested_Kg', 'Labor_Total', 'G_Pct', 'Month']].head(3))

# # # # # print("\n✅ CORRELATION CHECK:")
# # # # # # Check if Crop is predictive
# # # # # sample = X_train.copy()
# # # # # sample['Target'] = y_train_kg.iloc[:, 0].values
# # # # # if 'Crop_Harvested_Kg' in sample.columns:
# # # # #     corr = sample['Crop_Harvested_Kg'].corr(sample['Target'])
# # # # #     print(f"   Crop_Harvested_Kg vs Target: {corr:.4f}")
# # # # #     print(f"   This should be ~0.58-0.60")

# # # # # print("\n" + "=" * 80)
# # # # # print("READY TO TUNE!")
# # # # # print("=" * 80)
# # # # # print("\nNow run: python tea_yield.tune.py")
# # # # # print("Expected: R² should jump to 0.60-0.80 range")
# # # # # print("=" * 80)



# # # # """
# # # # Find out why CatBoost is stuck at 0.28
# # # # """
# # # # import pandas as pd
# # # # import numpy as np
# # # # from catboost import CatBoostRegressor, Pool
# # # # from sklearn.metrics import r2_score
# # # # from sklearn.linear_model import LinearRegression

# # # # PROC = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost"

# # # # print("=" * 80)
# # # # print("DEBUG CATBOOST R² = 0.28 ISSUE")
# # # # print("=" * 80)

# # # # # Load data
# # # # X_train = pd.read_csv(f"{PROC}/X_train.csv")
# # # # X_val = pd.read_csv(f"{PROC}/X_val.csv")
# # # # y_train_log = pd.read_csv(f"{PROC}/y_train_log.csv").iloc[:, 0]
# # # # y_val_log = pd.read_csv(f"{PROC}/y_val_log.csv").iloc[:, 0]
# # # # y_val_kg = pd.read_csv(f"{PROC}/y_val_kg.csv").iloc[:, 0]

# # # # print(f"\n1. DATA CHECK:")
# # # # print(f"   X_train: {X_train.shape}")
# # # # print(f"   X_val: {X_val.shape}")
# # # # print(f"   y_train_log mean: {y_train_log.mean():.4f}")
# # # # print(f"   y_val_log mean: {y_val_log.mean():.4f}")

# # # # # Check Division_ID encoding
# # # # print(f"\n2. DIVISION_ID CHECK:")
# # # # print(f"   Type in X_train: {X_train['Division_ID'].dtype}")
# # # # print(f"   Unique values: {X_train['Division_ID'].unique()}")
# # # # print(f"   Is it string? {X_train['Division_ID'].dtype == 'object'}")

# # # # # Test 1: Simple baseline with just Crop
# # # # print(f"\n3. BASELINE TEST - Just Crop_Harvested_Kg:")
# # # # X_simple = X_train[['Crop_Harvested_Kg']].values
# # # # X_simple_val = X_val[['Crop_Harvested_Kg']].values

# # # # lr = LinearRegression()
# # # # lr.fit(X_simple, y_train_log)
# # # # pred_log = lr.predict(X_simple_val)
# # # # pred_kg = np.expm1(pred_log)
# # # # r2_kg = r2_score(y_val_kg, pred_kg)
# # # # print(f"   Linear Regression R² (KG): {r2_kg:.4f}")
# # # # print(f"   If this is ~0.35-0.40, Crop alone has predictive power")

# # # # # Test 2: CatBoost with ONLY numerical features (no Division_ID)
# # # # print(f"\n4. CATBOOST TEST - NO CATEGORICAL:")
# # # # X_train_nocats = X_train.drop('Division_ID', axis=1)
# # # # X_val_nocats = X_val.drop('Division_ID', axis=1)

# # # # model = CatBoostRegressor(
# # # #     iterations=500,
# # # #     learning_rate=0.05,
# # # #     depth=6,
# # # #     verbose=False,
# # # #     random_seed=42
# # # # )
# # # # model.fit(X_train_nocats, y_train_log)
# # # # pred_log = model.predict(X_val_nocats)
# # # # pred_kg = np.expm1(pred_log)
# # # # r2_kg = r2_score(y_val_kg, pred_kg)
# # # # print(f"   CatBoost R² (KG) WITHOUT Division_ID: {r2_kg:.4f}")

# # # # # Test 3: CatBoost WITH categorical (current approach)
# # # # print(f"\n5. CATBOOST TEST - WITH CATEGORICAL:")
# # # # pool_train = Pool(X_train, y_train_log, cat_features=['Division_ID'])
# # # # pool_val = Pool(X_val, y_val_log, cat_features=['Division_ID'])

# # # # model2 = CatBoostRegressor(
# # # #     iterations=500,
# # # #     learning_rate=0.05,
# # # #     depth=6,
# # # #     verbose=False,
# # # #     random_seed=42
# # # # )
# # # # model2.fit(pool_train)
# # # # pred_log = model2.predict(X_val)
# # # # pred_kg = np.expm1(pred_log)
# # # # r2_kg = r2_score(y_val_kg, pred_kg)
# # # # print(f"   CatBoost R² (KG) WITH Division_ID: {r2_kg:.4f}")

# # # # # Test 4: Check if target is the problem
# # # # print(f"\n6. TARGET DISTRIBUTION CHECK:")
# # # # print(f"   y_train_log stats:")
# # # # print(f"      Mean: {y_train_log.mean():.4f}")
# # # # print(f"      Std: {y_train_log.std():.4f}")
# # # # print(f"      Min: {y_train_log.min():.4f}")
# # # # print(f"      Max: {y_train_log.max():.4f}")
# # # # print(f"      Range: {y_train_log.max() - y_train_log.min():.4f}")

# # # # # Test 5: Try predicting KG directly (no log)
# # # # print(f"\n7. TEST PREDICTING KG DIRECTLY (NO LOG):")
# # # # y_train_kg_direct = pd.read_csv(f"{PROC}/y_train_kg.csv").iloc[:, 0]

# # # # model3 = CatBoostRegressor(
# # # #     iterations=500,
# # # #     learning_rate=0.05,
# # # #     depth=6,
# # # #     verbose=False,
# # # #     random_seed=42
# # # # )
# # # # model3.fit(X_train_nocats, y_train_kg_direct)
# # # # pred_kg_direct = model3.predict(X_val_nocats)
# # # # r2_kg_direct = r2_score(y_val_kg, pred_kg_direct)
# # # # print(f"   CatBoost R² predicting KG directly: {r2_kg_direct:.4f}")

# # # # print("\n" + "=" * 80)
# # # # print("DIAGNOSIS:")
# # # # print("=" * 80)
# # # # print(f"\nIf baseline with just Crop > 0.35: Problem is in CatBoost setup")
# # # # print(f"If CatBoost without cats > 0.50: Problem is categorical handling")
# # # # print(f"If predicting KG directly > 0.50: Problem is log transform")
# # # # print("=" * 80)


# # # """
# # # Check what XGBoost actually predicted to get R² = 0.79
# # # """
# # # import pandas as pd
# # # import numpy as np

# # # XGBOOST_FOLDER = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Thesis_Processed_Final"

# # # print("=" * 80)
# # # print("WHAT DID XGBOOST ACTUALLY PREDICT?")
# # # print("=" * 80)

# # # # Check if XGBoost preprocessed files exist
# # # import os
# # # if os.path.exists(XGBOOST_FOLDER):
# # #     print(f"\n✅ Found XGBoost folder: {XGBOOST_FOLDER}")
    
# # #     # List files
# # #     files = os.listdir(XGBOOST_FOLDER)
# # #     print(f"\n📁 Files in XGBoost folder:")
# # #     for f in files:
# # #         print(f"   - {f}")
    
# # #     # Try to load y targets
# # #     try:
# # #         # Check for different possible target files
# # #         possible_files = [
# # #             'y_train.csv', 'y_val.csv', 'y_test.csv',
# # #             'y_train_log.csv', 'y_val_log.csv', 'y_test_log.csv',
# # #             'y_train_kg.csv', 'y_val_kg.csv', 'y_test_kg.csv'
# # #         ]
        
# # #         print(f"\n📊 TARGET FILES:")
# # #         for pf in possible_files:
# # #             path = os.path.join(XGBOOST_FOLDER, pf)
# # #             if os.path.exists(path):
# # #                 df = pd.read_csv(path)
# # #                 print(f"\n   ✅ {pf}:")
# # #                 print(f"      Columns: {df.columns.tolist()}")
# # #                 print(f"      Shape: {df.shape}")
# # #                 if len(df.columns) > 0:
# # #                     print(f"      Mean: {df.iloc[:, 0].mean():.4f}")
# # #                     print(f"      Std: {df.iloc[:, 0].std():.4f}")
# # #                     print(f"      Min: {df.iloc[:, 0].min():.4f}")
# # #                     print(f"      Max: {df.iloc[:, 0].max():.4f}")
                    
# # #                     # Identify what this is
# # #                     mean_val = df.iloc[:, 0].mean()
# # #                     if 2.5 < mean_val < 4.0:
# # #                         print(f"      → This looks like LOG EFFICIENCY (log(yield/labor))")
# # #                     elif 6.5 < mean_val < 8.0:
# # #                         print(f"      → This looks like LOG YIELD (log(yield))")
# # #                     elif 15 < mean_val < 25:
# # #                         print(f"      → This looks like EFFICIENCY (yield/labor)")
# # #                     elif 1000 < mean_val < 2000:
# # #                         print(f"      → This looks like YIELD KG (raw)")
# # #     except Exception as e:
# # #         print(f"\n❌ Error reading files: {e}")
    
# # #     # Check feature files
# # #     print(f"\n🔍 CHECKING FEATURES:")
# # #     try:
# # #         X_train_path = os.path.join(XGBOOST_FOLDER, "X_train.csv")
# # #         if os.path.exists(X_train_path):
# # #             X = pd.read_csv(X_train_path)
# # #             print(f"   ✅ X_train shape: {X.shape}")
# # #             print(f"   ✅ Features: {X.columns.tolist()[:10]}...")
# # #         else:
# # #             print(f"   ❌ No X_train.csv found")
# # #     except Exception as e:
# # #         print(f"   ❌ Error: {e}")
    
# # #     # Check full dataset
# # #     print(f"\n📋 CHECKING FULL DATASET:")
# # #     try:
# # #         full_path = os.path.join(XGBOOST_FOLDER, "full_dataset.csv")
# # #         if os.path.exists(full_path):
# # #             full = pd.read_csv(full_path, nrows=5)
# # #             print(f"   ✅ Columns in full dataset:")
# # #             for col in full.columns:
# # #                 print(f"      - {col}")
# # #         else:
# # #             # Try the processed final folder
# # #             alt_path = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Pre_Processed_Thesis\full_dataset.csv"
# # #             if os.path.exists(alt_path):
# # #                 full = pd.read_csv(alt_path, nrows=5)
# # #                 print(f"   ✅ Columns in full dataset (alt location):")
# # #                 for col in full.columns:
# # #                     print(f"      - {col}")
# # #     except Exception as e:
# # #         print(f"   ❌ Error: {e}")

# # # else:
# # #     print(f"\n❌ XGBoost folder not found: {XGBOOST_FOLDER}")
    
# # #     # Try alternate path
# # #     alt = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Pre_Processed_Thesis"
# # #     if os.path.exists(alt):
# # #         print(f"\n✅ Found alternate: {alt}")

# # # print("\n" + "=" * 80)
# # # print("KEY QUESTION:")
# # # print("=" * 80)
# # # print("Did XGBoost predict:")
# # # print("  A) Log Efficiency (mean ~2.9) → Then convert: KG = Labor × (exp(pred) - 1)")
# # # print("  B) Log Yield (mean ~7.1) → Then convert: KG = exp(pred) - 1")
# # # print("  C) Raw KG directly (mean ~1400)?")
# # # print("=" * 80)




# # """
# # QUICK DIAGNOSTIC: CAN CATBOOST MATCH XGBOOST?
# # """
# # import pandas as pd
# # import numpy as np
# # from catboost import CatBoostRegressor
# # from sklearn.metrics import r2_score

# # print("=" * 80)
# # print("QUICK DIAGNOSTIC: CAN CATBOOST MATCH XGBOOST?")
# # print("=" * 80)

# # # Load data
# # PROC = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost_XGBoostStyle"

# # X_train = pd.read_csv(f"{PROC}/X_train.csv")
# # X_val = pd.read_csv(f"{PROC}/X_val.csv")
# # y_train_log = pd.read_csv(f"{PROC}/y_train_log.csv").iloc[:, 0]
# # y_val_log = pd.read_csv(f"{PROC}/y_val_log.csv").iloc[:, 0]
# # y_val_kg = pd.read_csv(f"{PROC}/y_val_kg.csv")

# # cat_features = ['Division_ID']

# # print(f"\n📊 DATA SHAPE:")
# # print(f"   X_train: {X_train.shape}")
# # print(f"   X_val: {X_val.shape}")
# # print(f"   Features: {X_train.shape[1]}")
# # print(f"   Cat features: {len(cat_features)}")

# # print(f"\n🎯 TARGET:")
# # print(f"   y_train_log mean: {y_train_log.mean():.4f}")
# # print(f"   XGBoost target:   2.9024")

# # # TEST 1: Simple CatBoost with minimal features
# # print(f"\n🧪 TEST 1: Using only Crop and Labor (strong predictors)")
# # simple_features = ['Crop_Harvested_Kg', 'Labor_Total'] + cat_features
# # X_train_simple = X_train[simple_features]
# # X_val_simple = X_val[simple_features]

# # model1 = CatBoostRegressor(
# #     iterations=500,
# #     learning_rate=0.05,
# #     depth=6,
# #     random_seed=42,
# #     verbose=False
# # )
# # model1.fit(X_train_simple, y_train_log, cat_features=cat_features)

# # pred_log = model1.predict(X_val_simple)
# # pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(pred_log))
# # r2_simple = r2_score(y_val_kg['Target_Usable_Yield_Kg'], pred_kg)

# # print(f"   R² with just Crop+Labor: {r2_simple:.4f}")
# # print(f"   (Should be > 0.35)")

# # # TEST 2: Use all features but simple params
# # print(f"\n🧪 TEST 2: All features with optimal params")
# # model2 = CatBoostRegressor(
# #     iterations=1000,
# #     learning_rate=0.03,
# #     depth=8,
# #     l2_leaf_reg=3,
# #     random_strength=1,
# #     bootstrap_type='MVS',
# #     random_seed=42,
# #     verbose=False
# # )
# # model2.fit(X_train, y_train_log, cat_features=cat_features)

# # pred_log2 = model2.predict(X_val)
# # pred_kg2 = y_val_kg['Labor_Safe'] * (np.expm1(pred_log2))
# # r2_all = r2_score(y_val_kg['Target_Usable_Yield_Kg'], pred_kg2)

# # print(f"   R² with all features: {r2_all:.4f}")
# # print(f"   (Should be > 0.50)")

# # # TEST 3: Try XGBoost-like parameters
# # print(f"\n🧪 TEST 3: XGBoost-style parameters")
# # model3 = CatBoostRegressor(
# #     iterations=1500,
# #     learning_rate=0.01,
# #     depth=10,
# #     l2_leaf_reg=1,
# #     random_strength=1,
# #     bootstrap_type='Bernoulli',
# #     subsample=0.8,
# #     random_seed=42,
# #     verbose=False
# # )
# # model3.fit(X_train, y_train_log, cat_features=cat_features)

# # pred_log3 = model3.predict(X_val)
# # pred_kg3 = y_val_kg['Labor_Safe'] * (np.expm1(pred_log3))
# # r3 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], pred_kg3)

# # print(f"   R² XGBoost-style: {r3:.4f}")
# # print(f"   (Should be > 0.60)")

# # print(f"\n" + "=" * 80)
# # print("ANALYSIS:")
# # print("=" * 80)

# # if r2_simple > 0.35:
# #     print(f"✅ Crop+Labor baseline: {r2_simple:.4f} - Good!")
# # else:
# #     print(f"❌ Crop+Labor baseline: {r2_simple:.4f} - Too low!")

# # if r2_all > 0.50:
# #     print(f"✅ All features: {r2_all:.4f} - Promising!")
# # else:
# #     print(f"❌ All features: {r2_all:.4f} - Not enough!")

# # if r3 > 0.60:
# #     print(f"✅ XGBoost-style: {r3:.4f} - Getting close to 0.75!")
# # else:
# #     print(f"❌ XGBoost-style: {r3:.4f} - Need improvement")

# # print(f"\n" + "=" * 80)
# # print("RECOMMENDATION:")
# # print("=" * 80)

# # if r3 > 0.60:
# #     print(f"🚀 Good! CatBoost can reach >0.60 with right parameters")
# #     print(f"   Run Optuna with these settings:")
# #     print(f"   - Learning rate: 0.005 to 0.05")
# #     print(f"   - Depth: 8 to 12")
# #     print(f"   - Iterations: 2000 to 5000")
# #     print(f"   - Bootstrap: 'Bernoulli'")
# # else:
# #     print(f"⚠️  Still low. Let's check feature importance...")
# #     feature_importance = model2.feature_importances_
# #     importance_df = pd.DataFrame({
# #         'feature': X_train.columns,
# #         'importance': feature_importance
# #     }).sort_values('importance', ascending=False)
    
# #     print(f"\n📊 TOP 10 FEATURES:")
# #     print(importance_df.head(10))


# """
# DEBUG: IS CATBOOST LEARNING?
# """
# import pandas as pd
# import numpy as np
# from catboost import CatBoostRegressor
# from sklearn.metrics import r2_score, mean_absolute_error
# from sklearn.linear_model import LinearRegression

# print("=" * 80)
# print("DEBUG: IS CATBOOST LEARNING?")
# print("=" * 80)

# # Load data
# PROC = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost_XGBoostStyle"

# X_train = pd.read_csv(f"{PROC}/X_train.csv")
# X_val = pd.read_csv(f"{PROC}/X_val.csv")
# y_train_log = pd.read_csv(f"{PROC}/y_train_log.csv").iloc[:, 0]
# y_val_log = pd.read_csv(f"{PROC}/y_val_log.csv").iloc[:, 0]
# y_val_kg = pd.read_csv(f"{PROC}/y_val_kg.csv")

# cat_features = ['Division_ID']

# print(f"\n📊 Check feature correlation with target...")
# correlations = []
# for col in X_train.columns:
#     if col not in cat_features:
#         corr = X_train[col].corr(y_train_log)
#         correlations.append((col, abs(corr), corr))

# correlations.sort(key=lambda x: x[1], reverse=True)

# print(f"\n🏆 TOP 10 CORRELATED FEATURES:")
# for i, (col, abs_corr, corr) in enumerate(correlations[:10]):
#     print(f"   {i+1:2d}. {col:25s}: {corr:7.4f}")

# print(f"\n🎯 BASELINE TESTS:")

# # TEST 1: Perfect predictor test
# print(f"\n🧪 TEST 1: What if we use the PERFECT predictor?")
# # Let's see what R² we get if we use the ideal prediction
# best_kg_pred = y_val_kg['Labor_Safe'] * (np.expm1(y_val_log))
# perfect_r2 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], best_kg_pred)
# print(f"   R² if we predict log_eff PERFECTLY: {perfect_r2:.4f}")

# # TEST 2: What if we predict the mean?
# print(f"\n🧪 TEST 2: What if we always predict the mean?")
# mean_kg = y_val_kg['Labor_Safe'] * (np.expm1(np.mean(y_val_log)))
# mean_r2 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], mean_kg)
# print(f"   R² if we always predict mean: {mean_r2:.4f}")

# # TEST 3: Linear regression baseline
# print(f"\n🧪 TEST 3: Linear regression baseline")
# lr = LinearRegression()

# # Create numeric-only X (no categorical for LR)
# X_train_numeric = X_train.drop('Division_ID', axis=1)
# X_val_numeric = X_val.drop('Division_ID', axis=1)

# lr.fit(X_train_numeric, y_train_log)
# lr_pred_log = lr.predict(X_val_numeric)
# lr_pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(lr_pred_log))
# lr_r2 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], lr_pred_kg)
# print(f"   Linear Regression R²: {lr_r2:.4f}")

# # TEST 4: Check CatBoost learning curves
# print(f"\n🧪 TEST 4: CatBoost learning with 100 iterations")
# model = CatBoostRegressor(
#     iterations=100,
#     learning_rate=0.1,
#     depth=6,
#     random_seed=42,
#     verbose=False
# )
# model.fit(X_train, y_train_log, cat_features=cat_features)

# pred_log = model.predict(X_val)
# pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(pred_log))
# catboost_r2 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], pred_kg)
# print(f"   CatBoost (100 iters) R²: {catboost_r2:.4f}")

# # TEST 5: Manual prediction using correlation
# print(f"\n🧪 TEST 5: Manual prediction using top feature")
# # Use only Crop_Harvested_Kg to predict
# from sklearn.linear_model import Ridge

# ridge = Ridge(alpha=1.0)
# ridge.fit(X_train[['Crop_Harvested_Kg']], y_train_log)
# ridge_pred_log = ridge.predict(X_val[['Crop_Harvested_Kg']])
# ridge_pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(ridge_pred_log))
# ridge_r2 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], ridge_pred_kg)
# print(f"   Ridge (just Crop) R²: {ridge_r2:.4f}")

# print(f"\n" + "=" * 80)
# print("CRITICAL ANALYSIS:")
# print("=" * 80)

# print(f"\n1. Perfect prediction R²: {perfect_r2:.4f}")
# print(f"   → This is the MAXIMUM possible R²")
# print(f"   → If this is low, the problem is in TARGET TRANSFORMATION")

# print(f"\n2. Linear Regression R²: {lr_r2:.4f}")
# print(f"   → This shows if features have ANY predictive power")

# print(f"\n3. Ridge (Crop only) R²: {ridge_r2:.4f}")
# print(f"   → Crop_Harvested_Kg correlation: {correlations[0][2]:.4f}")

# print(f"\n" + "=" * 80)
# print("DIAGNOSIS:")
# print("=" * 80)

# if perfect_r2 < 0.8:
#     print(f"🚨 ISSUE: Perfect prediction R² is only {perfect_r2:.4f}")
#     print(f"   → The problem might be in the INVERSE TRANSFORM")
#     print(f"   → Formula: KG = Labor × (exp(log_eff) - 1)")
#     print(f"   → Let's check if this formula is correct...")
    
#     # Check formula correctness
#     print(f"\n   CHECKING FORMULA:")
#     test_idx = 0
#     test_labor = y_val_kg.iloc[test_idx]['Labor_Safe']
#     test_log_eff = y_val_log.iloc[test_idx]
#     test_kg = y_val_kg.iloc[test_idx]['Target_Usable_Yield_Kg']
    
#     calculated = test_labor * (np.exp(test_log_eff) - 1)
#     print(f"      Labor: {test_labor}")
#     print(f"      Log_eff: {test_log_eff:.4f}")
#     print(f"      Actual KG: {test_kg:.1f}")
#     print(f"      Calculated KG: {calculated:.1f}")
#     print(f"      Match? {abs(test_kg - calculated) < 0.1}")

# elif lr_r2 < 0.3:
#     print(f"🚨 ISSUE: Linear regression R² is only {lr_r2:.4f}")
#     print(f"   → Features don't have strong predictive power")
#     print(f"   → We might need BETTER FEATURES")

# else:
#     print(f"✅ Models are learning")
#     print(f"   → Perfect R²: {perfect_r2:.4f}")
#     print(f"   → LR R²: {lr_r2:.4f}")
#     print(f"   → CatBoost should beat LR")


"""
COMPARE WITH XGBOOST: What features did XGBoost use?
"""
import pandas as pd
import numpy as np
import os

print("=" * 80)
print("COMPARE WITH XGBOOST: Feature Analysis")
print("=" * 80)

# Load our CatBoost preprocessed data
CATBOOST_PROC = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction\Preprocessed_CatBoost_XGBoostStyle"
X_train_cb = pd.read_csv(f"{CATBOOST_PROC}/X_train.csv")
y_train_cb = pd.read_csv(f"{CATBOOST_PROC}/y_train_log.csv").iloc[:, 0]

# Load XGBoost preprocessed data (if available)
XGBOOST_PROC = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction\Thesis_Processed_Final"

print(f"\n📊 OUR CATBOOST FEATURES ({len(X_train_cb.columns)}):")
print("   Categorical:", [f for f in X_train_cb.columns if f == 'Division_ID'])
print("   Numerical:", [f for f in X_train_cb.columns if f != 'Division_ID'])

print(f"\n📈 FEATURE CORRELATIONS (Our CatBoost):")
correlations = []
for col in X_train_cb.columns:
    if col != 'Division_ID':
        corr = X_train_cb[col].corr(y_train_cb)
        correlations.append((col, corr))

correlations.sort(key=lambda x: abs(x[1]), reverse=True)

for col, corr in correlations[:15]:
    print(f"   {col:25s}: {corr:7.4f}")

print(f"\n🔍 CHECKING XGBOOST FEATURES...")

# Try to load XGBoost features
try:
    xgboost_features_path = f"{XGBOOST_PROC}/X_train.csv"
    if os.path.exists(xgboost_features_path):
        X_train_xgb = pd.read_csv(xgboost_features_path)
        print(f"\n✅ FOUND XGBOOST FEATURES: {X_train_xgb.shape[1]} features")
        print(f"   First 10 features: {X_train_xgb.columns.tolist()[:10]}")
        
        # Check if there are features we're missing
        our_features_set = set(X_train_cb.columns)
        xgb_features_set = set(X_train_xgb.columns)
        
        missing_in_xgb = xgb_features_set - our_features_set
        missing_in_us = our_features_set - xgb_features_set
        
        if missing_in_xgb:
            print(f"\n❌ WE ARE MISSING {len(missing_in_xgb)} XGBOOST FEATURES:")
            for f in list(missing_in_xgb)[:10]:
                print(f"   - {f}")
        
        if missing_in_us:
            print(f"\n📝 XGBoost missing {len(missing_in_us)} of our features")
            
    else:
        print(f"\n❌ XGBoost X_train.csv not found at: {xgboost_features_path}")
        
except Exception as e:
    print(f"\n❌ Error loading XGBoost data: {e}")

# Check the full dataset to see what features exist
print(f"\n🔍 CHECKING FULL DATASET FOR MORE FEATURES...")
try:
    full_path = f"{XGBOOST_PROC}/full_dataset.csv"
    if os.path.exists(full_path):
        full_df = pd.read_csv(full_path, nrows=5)
        print(f"\n✅ Full dataset columns ({len(full_df.columns)}):")
        for col in full_df.columns:
            print(f"   - {col}")
        
        # Check for features we might be missing
        potential_features = [
            'Humidity_Deficit', 'Consecutive_Stress_Days', 'Humidity_Stress_Index',
            'Humidity_Stress_Class', 'Is_Low_Humidity', 'Is_High_Humidity',
            'Kg_Per_Worker_Potential', 'Calculated_Waste_Pct'
        ]
        
        missing_potential = []
        for f in potential_features:
            if f in full_df.columns and f not in X_train_cb.columns:
                missing_potential.append(f)
        
        if missing_potential:
            print(f"\n🚨 WE ARE MISSING POTENTIALLY IMPORTANT FEATURES:")
            for f in missing_potential:
                print(f"   - {f}")
                
except Exception as e:
    print(f"\n❌ Error: {e}")

print(f"\n" + "=" * 80)
print("RECOMMENDATION:")
print("=" * 80)
print(f"\n1. Our strongest feature correlation: {correlations[0][1]:.4f}")
print(f"   → Not enough for R² = 0.79")

print(f"\n2. We need to add more predictive features:")
print(f"   - Check what XGBoost actually used")
print(f"   - Add humidity stress indicators")
print(f"   - Add more lag features")
print(f"   - Add interaction terms")

print(f"\n3. Quick test: Let's calculate what R² we CAN achieve")
print(f"   with current features...")

# Calculate theoretical maximum R²
from sklearn.linear_model import RidgeCV

# Use Ridge regression with cross-validation
ridge = RidgeCV(alphas=[0.1, 1.0, 10.0])
X_train_numeric = X_train_cb.drop('Division_ID', axis=1)

ridge.fit(X_train_numeric, y_train_cb)

# Calculate R² on training data (theoretical maximum with linear model)
train_pred = ridge.predict(X_train_numeric)
train_r2 = np.corrcoef(y_train_cb, train_pred)[0, 1] ** 2

print(f"\n   Theoretical max R² (linear): {train_r2:.4f}")
print(f"   Gap to 0.79: {0.79 - train_r2:.4f}")

print(f"\n" + "=" * 80)
print("NEXT STEPS:")
print("=" * 80)
print(f"\n1. Check the EXACT features XGBoost used")
print(f"2. Add the missing features to our preprocessing")
print(f"3. Create interaction features (e.g., Crop × G_Pct)")
print(f"4. Add polynomial features")
print(f"5. Try different target transformation")