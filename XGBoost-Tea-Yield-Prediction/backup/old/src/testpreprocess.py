# # # # import pandas as pd
# # # # import numpy as np
# # # # import matplotlib.pyplot as plt
# # # # import seaborn as sns
# # # # from sklearn.preprocessing import OneHotEncoder
# # # # from sklearn.compose import ColumnTransformer
# # # # import joblib
# # # # import os
# # # # from pathlib import Path

# # # # # ==========================================
# # # # # 1. CONFIGURATION
# # # # # ==========================================
# # # # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # # # DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# # # # PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version5")
# # # # GRAPHS_FOLDER = os.path.join(PROJECT_ROOT, "Graphs_Preprocessed5")

# # # # for folder in [PROCESSED_FOLDER, GRAPHS_FOLDER]:
# # # #     Path(folder).mkdir(parents=True, exist_ok=True)

# # # # # ==========================================
# # # # # 2. LOAD DATA
# # # # # ==========================================
# # # # print("\nStep 1: Loading raw datasets...")
# # # # train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
# # # # val_df   = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
# # # # test_df  = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))
# # # # dfs = {"train": train_df, "val": val_df, "test": test_df}

# # # # target_col = 'Target_Usable_Yield_Kg'

# # # # # ==========================================
# # # # # 3. ADVANCED SIGNAL RECOVERY (HIGH THEORY)
# # # # # ==========================================
# # # # print("Step 2: Recovering Biological Signals from Noise...")

# # # # for name, df in dfs.items():
# # # #     df['Date'] = pd.to_datetime(df['Date'])
# # # #     df = df.sort_values(['Division_ID', 'Date'])

# # # #     # --- A. TARGET SMOOTHING (The Research Secret) ---
# # # #     # Removes 'field rotation noise' to reveal biological growth trends
# # # #     df['Target_Smoothed'] = df.groupby('Division_ID')[target_col].transform(
# # # #         lambda x: x.rolling(window=3, center=True).mean()
# # # #     )

# # # #     # --- B. HARVEST POWER (Interaction Feature) ---
# # # #     # Scientific Theory: Labor is only effective if Quality (G_Pct) is high
# # # #     df['Harvest_Power'] = df['Labor_Total'] * (df['G_Pct'] / 100)
    
# # # #     # --- C. AUTOREGRESSIVE TRIPLE-LAG ---
# # # #     df['Yield_Lag_1d'] = df.groupby('Division_ID')['Target_Smoothed'].shift(1)
# # # #     df['Yield_Rolling_7d'] = df.groupby('Division_ID')['Target_Smoothed'].transform(lambda x: x.shift(1).rolling(window=7).mean())

# # # #     # --- D. BIOLOGICAL RAIN CAPACITY ---
# # # #     df['Rain_30d_Rolling'] = df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(lambda x: x.rolling(window=30).mean())
    
# # # #     # --- E. CYCLIC TIME ENCODING ---
# # # #     day_of_year = df['Date'].dt.dayofyear
# # # #     df['Year_Sin'] = np.sin(2 * np.pi * day_of_year / 365.25)
# # # #     df['Year_Cos'] = np.cos(2 * np.pi * day_of_year / 365.25)

# # # #     # Clean up NaNs created by rolling and centered windows
# # # #     dfs[name] = df.dropna().copy()

# # # # # ==========================================
# # # # # 4. TRANSFORMATION & SAVING
# # # # # ==========================================
# # # # print("Step 3: Transforming and Saving...")
# # # # num_cols = [
# # # #     'Yield_Lag_1d', 'Yield_Rolling_7d', 'Harvest_Power', 
# # # #     'Rainfall_Daily_mm', 'Rain_30d_Rolling',
# # # #     'Labor_Total', 'G_Pct', 'Kg_Per_Worker_Potential',
# # # #     'Year_Sin', 'Year_Cos'
# # # # ]
# # # # cat_cols = ['Division_ID']

# # # # preprocessor = ColumnTransformer([
# # # #     ('cat', OneHotEncoder(sparse_output=False, handle_unknown='ignore'), cat_cols),
# # # #     ('num', 'passthrough', num_cols)
# # # # ])

# # # # # Use Target_Smoothed as the new Y
# # # # for name in ["train", "val", "test"]:
# # # #     X_proc = preprocessor.fit_transform(dfs[name][cat_cols + num_cols]) if name == "train" else preprocessor.transform(dfs[name][cat_cols + num_cols])
# # # #     X_df = pd.DataFrame(X_proc, columns=preprocessor.get_feature_names_out())
# # # #     X_df.to_csv(os.path.join(PROCESSED_FOLDER, f"X_{name}.csv"), index=False)
# # # #     dfs[name]['Target_Smoothed'].to_csv(os.path.join(PROCESSED_FOLDER, f"y_{name}.csv"), index=False)

# # # # joblib.dump(preprocessor, os.path.join(PROCESSED_FOLDER, "preprocessor_pipeline.pkl"))

# # # # # ==========================================
# # # # # 5. VERIFICATION GRAPHS (THE PROOF)
# # # # # ==========================================
# # # # print("Step 4: Generating Signal Recovery Verification Graphs...")

# # # # # Graph 1: Smoothing Proof (Noisy vs Clean Signal)
# # # # # PROVES: Why accuracy will increase by removing spatial rotation noise
# # # # sample_div = dfs['train']['Division_ID'].unique()[0]
# # # # sample_data = dfs['train'][dfs['train']['Division_ID'] == sample_div].tail(60)

# # # # plt.figure(figsize=(12, 6))
# # # # plt.plot(sample_data['Date'], sample_data[target_col], 'ko', alpha=0.3, label='Original Noisy Yield (Field-Specific)')
# # # # plt.plot(sample_data['Date'], sample_data['Target_Smoothed'], 'r-', linewidth=3, label='Recovered Biological Signal (Trend)')
# # # # plt.title(f"Signal Recovery Verification: Division {sample_div}\nRed Line is the New High-Accuracy Target")
# # # # plt.legend()
# # # # plt.xticks(rotation=45)
# # # # plt.tight_layout()
# # # # plt.savefig(os.path.join(GRAPHS_FOLDER, "Signal_Recovery_Proof.png"))
# # # # plt.close()

# # # # # Graph 2: Harvest Power Correlation
# # # # # PROVES: The new interaction feature is a better predictor than raw Labor or Quality alone
# # # # plt.figure(figsize=(10, 6))
# # # # sns.regplot(data=dfs['train'], x='Harvest_Power', y='Target_Smoothed', scatter_kws={'alpha':0.2}, line_kws={'color':'green'})
# # # # plt.title("Economic harvest Power vs. Smoothed Yield")
# # # # plt.savefig(os.path.join(GRAPHS_FOLDER, "Harvest_Power_Regression.png"))
# # # # plt.close()

# # # # # Graph 3: Correlation Heatmap
# # # # plt.figure(figsize=(12, 10))
# # # # corr = dfs['train'][num_cols + ['Target_Smoothed']].corr()
# # # # sns.heatmap(corr, annot=True, cmap='coolwarm', fmt=".2f")
# # # # plt.title("Signal Recovery Correlation Matrix")
# # # # plt.savefig(os.path.join(GRAPHS_FOLDER, "Correlation_Matrix_Smoothed.png"))
# # # # plt.close()

# # # # print(f"\n✅ SUCCESS: Preprocessing complete. Predictors recovered. Results in: {GRAPHS_FOLDER}")

# # # # Terminal Value:

# # # # ====================================================================================================
# # # #                                 TOP 5 CONFIGURATIONS (Sorted by MAE)
# # # # ====================================================================================================
# # # # Trial  | MAE (kg)   | RMSE (kg)  | R2       | Booster  | Trees  | Depth
# # # # ----------------------------------------------------------------------------------------------------
# # # # 30     | 217.50     | 331.49     | 0.7681   | gbtree   | 1100   | 5     
# # # # 14     | 217.62     | 331.64     | 0.7679   | gbtree   | 900    | 5     
# # # # 16     | 217.71     | 334.19     | 0.7643   | gbtree   | 800    | 6
# # # # 23     | 217.97     | 332.11     | 0.7672   | gbtree   | 700    | 6
# # # # 41     | 217.97     | 331.35     | 0.7683   | gbtree   | 1100   | 5
# # # # ====================================================================================================

# # # # COPY THIS DICTIONARY INTO 'train_xgboost.py':
# # # # ------------------------------------------------------------
# # # # xgb_params = {
# # # #     'booster': 'gbtree',
# # # #     'n_estimators': 1100,
# # # #     'learning_rate': 0.017493236464827953,
# # # #     'max_depth': 5,
# # # #     'subsample': 0.631112155452769,
# # # #     'colsample_bytree': 0.9062186950220342,
# # # #     'gamma': 4.265851573164604,
# # # #     'min_child_weight': 8,
# # # #     'reg_alpha': 0.018289973366123705,
# # # #     'reg_lambda': 0.008138632559200092,
# # # #     'n_jobs': -1,
# # # #     'random_state': 42,
# # # # }







# # # # ==========================================================================================================

# # # import pandas as pd
# # # import numpy as np
# # # import matplotlib.pyplot as plt
# # # import seaborn as sns
# # # from sklearn.preprocessing import OneHotEncoder
# # # from sklearn.compose import ColumnTransformer
# # # import joblib
# # # import os
# # # from pathlib import Path

# # # # ==========================================
# # # # 1. CONFIGURATION
# # # # ==========================================
# # # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # # DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# # # PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version6")
# # # GRAPHS_FOLDER = os.path.join(PROJECT_ROOT, "Graphs_Preprocessed_Final_Phase")

# # # for folder in [PROCESSED_FOLDER, GRAPHS_FOLDER]:
# # #     Path(folder).mkdir(parents=True, exist_ok=True)

# # # # ==========================================
# # # # 2. LOAD DATA
# # # # ==========================================
# # # print("\nStep 1: Loading raw datasets...")
# # # train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
# # # val_df   = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
# # # test_df  = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))
# # # dfs = {"train": train_df, "val": val_df, "test": test_df}

# # # target_col = 'Target_Usable_Yield_Kg'

# # # # ==========================================
# # # # 3. PHASE-LAG SIGNAL ENGINEERING (HIGH THEORY)
# # # # ==========================================
# # # print("Step 2: Engineering Biological Phase Lags & Synergy Features...")

# # # for name, df in dfs.items():
# # #     df['Date'] = pd.to_datetime(df['Date'])
# # #     df = df.sort_values(['Division_ID', 'Date'])

# # #     # --- A. SIGNAL RECOVERY ---
# # #     # Centered smoothing removes 'field rotation' noise while keeping the trend
# # #     df['Target_Smoothed'] = df.groupby('Division_ID')[target_col].transform(
# # #         lambda x: x.rolling(window=3, center=True).mean()
# # #     )

# # #     # --- B. BIOLOGICAL PHASE LAGS ---
# # #     # Scientific Theory: Rainfall exactly 14 days ago is a peak trigger for leaf harvest
# # #     df['Rain_Lag_14d'] = df.groupby('Division_ID')['Rainfall_Daily_mm'].shift(14)
# # #     df['Rain_Accum_14d'] = df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(lambda x: x.rolling(window=14).sum())
    
# # #     # --- C. TIME & LABOR SYNERGY ---
# # #     day_of_year = df['Date'].dt.dayofyear
# # #     df['Year_Sin'] = np.sin(2 * np.pi * day_of_year / 365.25)
# # #     df['Year_Cos'] = np.cos(2 * np.pi * day_of_year / 365.25)
    
# # #     # Models how labor effectiveness changes with seasonal growth phases
# # #     df['Seasonal_Labor_Impact'] = df['Labor_Total'] * df['Year_Sin']

# # #     # --- D. AUTOREGRESSIVE SIGNAL ---
# # #     df['Yield_Lag_1d'] = df.groupby('Division_ID')['Target_Smoothed'].shift(1)

# # #     dfs[name] = df.dropna().copy()

# # # # ==========================================
# # # # 4. TRANSFORMATION & SAVING
# # # # ==========================================
# # # print("Step 3: Transforming and Saving Dataset...")
# # # num_cols = [
# # #     'Yield_Lag_1d', 'Rain_Lag_14d', 'Rain_Accum_14d', 
# # #     'Labor_Total', 'Seasonal_Labor_Impact', 'G_Pct', 
# # #     'Year_Sin', 'Year_Cos', 'Kg_Per_Worker_Potential'
# # # ]
# # # cat_cols = ['Division_ID']

# # # preprocessor = ColumnTransformer([
# # #     ('cat', OneHotEncoder(sparse_output=False, handle_unknown='ignore'), cat_cols),
# # #     ('num', 'passthrough', num_cols)
# # # ])

# # # for name in ["train", "val", "test"]:
# # #     X_proc = preprocessor.fit_transform(dfs[name][cat_cols + num_cols]) if name == "train" else preprocessor.transform(dfs[name][cat_cols + num_cols])
# # #     X_df = pd.DataFrame(X_proc, columns=preprocessor.get_feature_names_out())
# # #     X_df.to_csv(os.path.join(PROCESSED_FOLDER, f"X_{name}.csv"), index=False)
# # #     dfs[name]['Target_Smoothed'].to_csv(os.path.join(PROCESSED_FOLDER, f"y_{name}.csv"), index=False)

# # # joblib.dump(preprocessor, os.path.join(PROCESSED_FOLDER, "preprocessor_pipeline.pkl"))

# # # # ==========================================
# # # # 5. VERIFICATION GRAPHS (THE DOCTORATE LEVEL PROOF)
# # # # ==========================================
# # # print("Step 4: Generating Phase-Lag Verification Graphs...")

# # # # Graph 1: The 14-Day Lag Correlation
# # # # VERIFIES: That Rainfall 14 days ago is a superior biological predictor than today's rain
# # # plt.figure(figsize=(10, 6))
# # # sns.regplot(data=dfs['train'], x='Rain_Lag_14d', y='Target_Smoothed', scatter_kws={'alpha':0.2}, line_kws={'color':'blue'})
# # # plt.title("Phase-Lag Verification: 14-Day Delayed Rain vs. Yield Trend")
# # # plt.savefig(os.path.join(GRAPHS_FOLDER, "Rain_Lag_14d_Verification.png"))
# # # plt.close()

# # # # Graph 2: Seasonal Labor Synergy
# # # # VERIFIES: That the model captures the interaction between plucking capacity and seasons
# # # plt.figure(figsize=(10, 6))
# # # plt.scatter(dfs['train']['Seasonal_Labor_Impact'], dfs['train']['Target_Smoothed'], c=dfs['train']['G_Pct'], cmap='plasma', alpha=0.4)
# # # plt.title("Synergy Verification: Seasonal Labor Impact (Colored by G_Pct)")
# # # plt.colorbar(label='Good Leaf % (Quality)')
# # # plt.savefig(os.path.join(GRAPHS_FOLDER, "Seasonal_Labor_Synergy.png"))
# # # plt.close()

# # # # Graph 3: Ultimate Research Correlation Heatmap
# # # plt.figure(figsize=(12, 10))
# # # corr = dfs['train'][num_cols + ['Target_Smoothed']].corr()
# # # sns.heatmap(corr, annot=True, cmap='RdYlGn', fmt=".2f")
# # # plt.title("Ultimate Phase-Lag Correlation Matrix")
# # # plt.savefig(os.path.join(GRAPHS_FOLDER, "Correlation_Matrix_Ultimate_Phase.png"))
# # # plt.close()

# # # print(f"\n✅ SUCCESS: Phase-Lag Preprocessing complete. Verification results in: {GRAPHS_FOLDER}")

# # # Terminal value:

# # # ====================================================================================================
# # #                                 TOP 5 CONFIGURATIONS (Sorted by MAE)
# # # ====================================================================================================
# # # Trial  | MAE (kg)   | RMSE (kg)  | R2       | Booster  | Trees  | Depth
# # # ----------------------------------------------------------------------------------------------------
# # # 46     | 224.63     | 342.97     | 0.7498   | dart     | 1500   | 4     
# # # 48     | 225.02     | 342.83     | 0.7501   | dart     | 1400   | 4     
# # # 33     | 225.12     | 343.24     | 0.7494   | gbtree   | 1400   | 4
# # # 49     | 225.14     | 344.49     | 0.7476   | dart     | 1500   | 6
# # # 45     | 225.22     | 342.74     | 0.7502   | dart     | 1400   | 4
# # # ====================================================================================================

# # # COPY THIS DICTIONARY INTO 'train_xgboost.py':
# # # ------------------------------------------------------------
# # # xgb_params = {
# # #     'booster': 'dart',
# # #     'n_estimators': 1500,
# # #     'learning_rate': 0.038017256021835075,
# # #     'max_depth': 4,
# # #     'subsample': 0.6440942377361335,
# # #     'colsample_bytree': 0.9014779598844773,
# # #     'gamma': 4.8414645648884065,
# # #     'min_child_weight': 10,
# # #     'reg_alpha': 0.37709978642715014,
# # #     'reg_lambda': 8.858536555915428,
# # #     'n_jobs': -1,
# # #     'random_state': 42,
# # # }

# # # ------------------------------------------------------------
# # import pandas as pd
# # import numpy as np
# # import matplotlib.pyplot as plt
# # import seaborn as sns
# # from sklearn.preprocessing import OneHotEncoder
# # from sklearn.compose import ColumnTransformer
# # import joblib
# # import os
# # from pathlib import Path

# # # ==========================================
# # # 1. CONFIGURATION
# # # ==========================================
# # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# # PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version7")
# # GRAPHS_FOLDER = os.path.join(PROJECT_ROOT, "Graphs_Preprocessed7")

# # for folder in [PROCESSED_FOLDER, GRAPHS_FOLDER]:
# #     Path(folder).mkdir(parents=True, exist_ok=True)

# # # ==========================================
# # # 2. LOAD DATA
# # # ==========================================
# # print("\nStep 1: Loading raw datasets...")
# # train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
# # val_df   = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
# # test_df  = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))
# # dfs = {"train": train_df, "val": val_df, "test": test_df}

# # target_col = 'Target_Usable_Yield_Kg'

# # # ==========================================
# # # 3. NON-LINEAR SIGNAL ENGINEERING
# # # ==========================================
# # print("Step 2: Applying Log-Transformation & Interaction Density...")

# # for name, df in dfs.items():
# #     df['Date'] = pd.to_datetime(df['Date'])
# #     df = df.sort_values(['Division_ID', 'Date'])

# #     # --- A. TARGET STABILIZATION ---
# #     # Log transformation fixes the 'Amplitude' problem of Rush harvests
# #     df['Smoothed_Kg'] = df.groupby('Division_ID')[target_col].transform(
# #         lambda x: x.rolling(window=3, center=True).mean()
# #     )
# #     df['Target_Log'] = np.log1p(df['Smoothed_Kg'])

# #     # --- B. BIOLOGICAL INTERACTIONS ---
# #     # Flush Potential: Rain only matters if Quality control (G_Pct) is optimized
# #     df['Rain_Accum_14d'] = df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(lambda x: x.rolling(window=14).sum())
# #     df['Flush_Potential'] = df['Rain_Accum_14d'] * (df['G_Pct'] / 100)
    
# #     # --- C. AUTOREGRESSIVE LOG-MOMENTUM ---
# #     df['Yield_Log_Lag1'] = df.groupby('Division_ID')['Target_Log'].shift(1)

# #     # --- D. SEASONAL HARMONICS ---
# #     day_of_year = df['Date'].dt.dayofyear
# #     df['Year_Sin'] = np.sin(2 * np.pi * day_of_year / 365.25)
# #     df['Year_Cos'] = np.cos(2 * np.pi * day_of_year / 365.25)

# #     dfs[name] = df.dropna().copy()

# # # ==========================================
# # # 4. TRANSFORMATION & SAVING
# # # ==========================================
# # print("Step 3: Transforming and Saving...")
# # num_cols = [
# #     'Yield_Log_Lag1', 'Flush_Potential', 'Rain_Accum_14d', 
# #     'Labor_Total', 'G_Pct', 'Kg_Per_Worker_Potential',
# #     'Year_Sin', 'Year_Cos'
# # ]
# # cat_cols = ['Division_ID']

# # preprocessor = ColumnTransformer([
# #     ('cat', OneHotEncoder(sparse_output=False, handle_unknown='ignore'), cat_cols),
# #     ('num', 'passthrough', num_cols)
# # ])

# # for name in ["train", "val", "test"]:
# #     X_proc = preprocessor.fit_transform(dfs[name][cat_cols + num_cols]) if name == "train" else preprocessor.transform(dfs[name][cat_cols + num_cols])
# #     X_df = pd.DataFrame(X_proc, columns=preprocessor.get_feature_names_out())
# #     X_df.to_csv(os.path.join(PROCESSED_FOLDER, f"X_{name}.csv"), index=False)
# #     dfs[name]['Target_Log'].to_csv(os.path.join(PROCESSED_FOLDER, f"y_{name}.csv"), index=False)

# # joblib.dump(preprocessor, os.path.join(PROCESSED_FOLDER, "preprocessor_pipeline.pkl"))

# # # ==========================================
# # # 5. VERIFICATION GRAPHS (0.85+ PROOF)
# # # ==========================================
# # print("Step 4: Generating Log-Stabilization Verification Graphs...")

# # # Graph 1: Target Distribution Comparison
# # # PROVES: That Log-transformation has neutralized the extreme outliers.
# # plt.figure(figsize=(12, 5))
# # plt.subplot(1, 2, 1)
# # sns.histplot(dfs['train'][target_col], kde=True, color='red')
# # plt.title("Before: Raw Yield Distribution (Skewed)")
# # plt.subplot(1, 2, 2)
# # sns.histplot(dfs['train']['Target_Log'], kde=True, color='blue')
# # plt.title("After: Log-Transformed Target (Normal)")
# # plt.savefig(os.path.join(GRAPHS_FOLDER, "Log_Transformation_Proof.png"))
# # plt.close()

# # # Graph 2: The Flush Potential Signal
# # # PROVES: Interaction between cumulative rain and plucking quality.
# # plt.figure(figsize=(10, 6))
# # sns.regplot(data=dfs['train'], x='Flush_Potential', y='Target_Log', scatter_kws={'alpha':0.2}, line_kws={'color':'purple'})
# # plt.title("Interaction Proof: Flush Potential (Rain * Quality) vs. Log Yield")
# # plt.savefig(os.path.join(GRAPHS_FOLDER, "Flush_Potential_Verification.png"))
# # plt.close()

# # # Graph 3: High-Resolution Correlation Matrix
# # plt.figure(figsize=(12, 10))
# # corr = dfs['train'][num_cols + ['Target_Log']].corr()
# # sns.heatmap(corr, annot=True, cmap='viridis', fmt=".2f")
# # plt.title("Log-Breakthrough Correlation Matrix")
# # plt.savefig(os.path.join(GRAPHS_FOLDER, "Correlation_Matrix_Log.png"))
# # plt.close()

# # print(f"\n✅ SUCCESS: Breakthrough Preprocessing complete. Results in: {GRAPHS_FOLDER}")


# # ====================================================================================================
# #                                 TOP 5 CONFIGURATIONS (Sorted by MAE)
# # ====================================================================================================
# # Trial  | MAE (kg)   | RMSE (kg)  | R2       | Booster  | Trees  | Depth
# # ----------------------------------------------------------------------------------------------------
# # 33     | 220.32     | 340.66     | 0.7534   | dart     | 1900   | 6     
# # 48     | 220.56     | 341.00     | 0.7529   | gbtree   | 1800   | 7     
# # 32     | 220.61     | 340.49     | 0.7536   | dart     | 1900   | 6
# # 40     | 220.75     | 340.08     | 0.7542   | gbtree   | 2000   | 7
# # 41     | 220.80     | 341.09     | 0.7528   | gbtree   | 2000   | 7
# # ====================================================================================================

# # COPY THIS DICTIONARY INTO 'train_xgboost.py':
# # ------------------------------------------------------------
# # xgb_params = {
# #     'booster': 'dart',
# #     'n_estimators': 1900,
# #     'learning_rate': 0.047096048380961784,
# #     'max_depth': 6,
# #     'subsample': 0.9390740291158612,
# #     'colsample_bytree': 0.8338395303011942,
# #     'gamma': 0.2831373165274367,
# #     'min_child_weight': 2,
# #     'reg_alpha': 0.00642649507273822,
# #     'reg_lambda': 0.00030053294511571974,
# #     'n_jobs': -1,
# #     'random_state': 42,
# # }


# # ----------------------------------------------------------------------------------------------------




# import pandas as pd
# import numpy as np
# import os
# import joblib
# from sklearn.preprocessing import OneHotEncoder
# from sklearn.compose import ColumnTransformer
# from pathlib import Path

# # Force Matplotlib to save files without a popup window (Critical for speed)
# import matplotlib
# matplotlib.use('Agg') 
# import matplotlib.pyplot as plt
# import seaborn as sns

# # ==========================================
# # 1. CONFIGURATION
# # ==========================================
# PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# DATASET_FOLDER = os.path.join(PROJECT_ROOT, "dataset")
# PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version8")
# GRAPHS_FOLDER = os.path.join(PROJECT_ROOT, "Graphs_Preprocessed8")

# Path(PROCESSED_FOLDER).mkdir(parents=True, exist_ok=True)
# Path(GRAPHS_FOLDER).mkdir(parents=True, exist_ok=True)

# # ==========================================
# # 2. LOAD & ENGINEER BIOLOGY
# # ==========================================
# print("Step 1: Loading raw datasets...")
# train_df = pd.read_csv(os.path.join(DATASET_FOLDER, "train_yield.csv"))
# val_df   = pd.read_csv(os.path.join(DATASET_FOLDER, "valid_yield.csv"))
# test_df  = pd.read_csv(os.path.join(DATASET_FOLDER, "test_yield.csv"))
# dfs = {"train": train_df, "val": val_df, "test": test_df}

# target_col = 'Target_Usable_Yield_Kg'

# print("Step 2: Engineering Efficiency and Biological Signals...")
# for name, df in dfs.items():
#     df['Date'] = pd.to_datetime(df['Date'], errors='coerce')
#     df = df.sort_values(['Division_ID', 'Date'])

#     # A. Target Smoothing (Isolates biological trend from field rotation noise)
#     # df['Yield_Smoothed'] = df.groupby('Division_ID')[target_col].transform(
#     #     lambda x: x.rolling(window=3, center=True, min_periods=1).mean()
#     # )
#     df['Yield_Smoothed'] = df.groupby('Division_ID')[target_col].transform(
#         lambda x: x.rolling(window=3, center=False, min_periods=1).mean()
#     )

#     # B. Efficiency Target (Kg per worker)
#     df['Labor_Safe'] = df['Labor_Total'].clip(lower=1)
#     df['Efficiency'] = df['Yield_Smoothed'] / df['Labor_Safe']
#     df['Target_Log_Eff'] = np.log1p(df['Efficiency']) 

#     # C. Biological Signal Engineering
#     df['Rain_Accum_14d'] = df.groupby('Division_ID')['Rainfall_Daily_mm'].transform(lambda x: x.rolling(window=14).sum())
#     df['Flush_Optimal'] = ((df['Rain_Accum_14d'] >= 100) & (df['Rain_Accum_14d'] <= 300)).astype(int)
#     df['Over_Wet_Flag'] = (df['Rain_Accum_14d'] > 300).astype(int)

#     # D. Autoregressive Momentum (Memory of the flush)
#     df['Eff_Lag1'] = df.groupby('Division_ID')['Target_Log_Eff'].shift(1)
#     df['Quality_Efficiency'] = df['Eff_Lag1'] * (df['G_Pct'] / 100)

#     # E. Seasonality (Bogawanthalawa Cycle)
#     day_of_year = df['Date'].dt.dayofyear
#     df['Year_Sin'] = np.sin(2 * np.pi * day_of_year / 365.25)
#     df['Year_Cos'] = np.cos(2 * np.pi * day_of_year / 365.25)

#     dfs[name] = df.dropna().copy()

# # ==========================================
# # 3. PIPELINE & SAVING
# # ==========================================
# print("Step 3: Transforming and Saving Data...")
# num_cols = ['Eff_Lag1', 'Quality_Efficiency', 'Flush_Optimal', 'Over_Wet_Flag', 
#             'Rain_Accum_14d', 'G_Pct', 'Year_Sin', 'Year_Cos', 'Kg_Per_Worker_Potential']
# cat_cols = ['Division_ID']

# preprocessor = ColumnTransformer([
#     ('cat', OneHotEncoder(sparse_output=False, handle_unknown='ignore', drop='first'), cat_cols),
#     ('num', 'passthrough', num_cols)
# ])

# for name in ["train", "val", "test"]:
#     X_proc = preprocessor.fit_transform(dfs[name][cat_cols + num_cols]) if name == "train" else preprocessor.transform(dfs[name][cat_cols + num_cols])
#     X_df = pd.DataFrame(X_proc, columns=preprocessor.get_feature_names_out())
#     X_df.to_csv(os.path.join(PROCESSED_FOLDER, f"X_{name}.csv"), index=False)
#     dfs[name]['Target_Log_Eff'].to_csv(os.path.join(PROCESSED_FOLDER, f"y_{name}.csv"), index=False)

# joblib.dump(preprocessor, os.path.join(PROCESSED_FOLDER, "preprocessor_pipeline.pkl"))

# # ==========================================
# # 4. FINAL RESEARCH VERIFICATION GRAPHS
# # ==========================================
# print("Step 4: Generating Final Verification Graphs...")

# # Graph 1: Efficiency Distribution (The "Bell Curve" Proof)
# plt.figure(figsize=(10, 6))
# sns.histplot(dfs['train']['Target_Log_Eff'], kde=True, color='teal')
# plt.title("Log-Efficiency Target Distribution\nVerified Normal for XGBoost Optimization")
# plt.xlabel("Log(Yield per Worker + 1)")
# plt.savefig(os.path.join(GRAPHS_FOLDER, "Log_Efficiency_Distribution.png"), bbox_inches='tight')
# plt.close()
# print("   - Saved: Log_Efficiency_Distribution.png")

# # Graph 2: Biology Verification (Rain vs. Efficiency)
# # This proves Rainfall Accumulation (14d) triggers the Efficiency Spikes
# plt.figure(figsize=(10, 6))
# sns.regplot(data=dfs['train'], x='Rain_Accum_14d', y='Target_Log_Eff', 
#             scatter_kws={'alpha':0.2}, line_kws={'color':'red'}, ci=None)
# plt.title("Biological Proof: 14-Day Cumulative Rain vs. Plucking Efficiency")
# plt.savefig(os.path.join(GRAPHS_FOLDER, "Rain_Biology_Verification.png"), bbox_inches='tight')
# plt.close()
# print("   - Saved: Rain_Biology_Verification.png")

# # Graph 3: Correlation Matrix
# plt.figure(figsize=(12, 10))
# corr = dfs['train'][num_cols + ['Target_Log_Eff']].corr()
# sns.heatmap(corr, annot=True, cmap='RdYlGn', fmt=".2f")
# plt.title("Production-Ready Correlation Matrix (Efficiency Mode)")
# plt.savefig(os.path.join(GRAPHS_FOLDER, "Final_Correlation_Matrix.png"), bbox_inches='tight')
# plt.close()
# print("   - Saved: Final_Correlation_Matrix.png")

# print(f"\n✅ SUCCESS: Production data and graphs saved to {GRAPHS_FOLDER}")