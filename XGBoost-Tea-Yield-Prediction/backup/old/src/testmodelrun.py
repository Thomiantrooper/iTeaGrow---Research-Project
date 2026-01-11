# import pandas as pd
# import numpy as np
# import matplotlib.pyplot as plt
# import seaborn as sns
# import xgboost as xgb
# import shap
# from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
# import joblib
# import os
# import time

# # ==========================================
# # 1. CONFIGURATION AND VERSIONING
# # ==========================================
# project_root = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# processed_folder = os.path.join(project_root, "Pre_Processed_Version8") # Updated to v8
# dataset_folder = os.path.join(project_root, "dataset")
# artifacts_folder = os.path.join(project_root, "Model_Artifacts_Final")
# graphs_folder = os.path.join(project_root, "Graphs_Model_Analysis_Final")

# for folder in [artifacts_folder, graphs_folder]:
#     if not os.path.exists(folder):
#         os.makedirs(folder)
#         print(f"Created folder: {folder}")

# # ==========================================
# # 2. BEST HYPERPARAMETERS (From Trial 49)
# # ==========================================
# xgb_params = {
#     'booster': 'dart',
#     'n_estimators': 2300,
#     'learning_rate': 0.011524019386394083,
#     'max_depth': 6,
#     'subsample': 0.7387759406953051,
#     'colsample_bytree': 0.838215084402145,
#     'gamma': 0.28450830178175457,
#     'min_child_weight': 1,
#     'reg_alpha': 0.0006998740844082803,
#     'reg_lambda': 0.1153882143368494,
#     'n_jobs': -1,
#     'random_state': 42,
#     'objective': 'reg:squarederror'
# }

# # ==========================================
# # 3. LOAD DATA & ALIGN LABOR
# # ==========================================
# print("\nStep 1: Loading Processed Data (Version 8)...")
# try:
#     X_train = pd.read_csv(os.path.join(processed_folder, "X_train.csv"))
#     y_train = pd.read_csv(os.path.join(processed_folder, "y_train.csv")).iloc[:, 0]
#     X_val   = pd.read_csv(os.path.join(processed_folder, "X_val.csv"))
#     y_val   = pd.read_csv(os.path.join(processed_folder, "y_val.csv")).iloc[:, 0]
#     X_test  = pd.read_csv(os.path.join(processed_folder, "X_test.csv"))
#     y_test  = pd.read_csv(os.path.join(processed_folder, "y_test.csv")).iloc[:, 0]

#     # Align Labor_Total for final total yield metrics
#     test_raw = pd.read_csv(os.path.join(dataset_folder, "test_yield.csv"))
#     labor_test = test_raw.tail(len(X_test))['Labor_Total'].values
# except FileNotFoundError:
#     print("ERROR: Processed files not found. Run Preprocessing Version 8 first.")
#     exit()

# # ==========================================
# # 4. TRAIN XGBOOST
# # ==========================================
# print("\nStep 2: Training Champion DART Model...")
# start_time = time.time()

# model = xgb.XGBRegressor(**xgb_params)

# # DART does not support traditional early_stopping_rounds in the fit method.
# # We use the full n_estimators found by Optuna.
# model.fit(X_train, y_train, eval_set=[(X_val, y_val)], verbose=100)

# train_time = time.time() - start_time
# print(f"   - Training Complete in {train_time:.2f} seconds.")

# # ==========================================
# # 5. EVALUATION (CONVERTING LOG TO KG)
# # ==========================================
# print("\nStep 3: Evaluating and De-logging Predictions...")
# preds_log = model.predict(X_test)

# # Predicted and Actual Efficiency in Kg/Worker
# eff_pred = np.expm1(preds_log)
# eff_actual = np.expm1(y_test)

# # Total Yield in Kg
# total_pred = eff_pred * labor_test
# total_actual = eff_actual * labor_test

# r2 = r2_score(y_test, preds_log)
# mae_kg = mean_absolute_error(total_actual, total_pred)
# rmse_kg = np.sqrt(mean_squared_error(total_actual, total_pred))
# mape = np.mean(np.abs((total_actual - total_pred) / (total_actual + 1e-10))) * 100

# print("="*60)
# print("FINAL PERFORMANCE REPORT (Total Usable Yield kg)")
# print("="*60)
# print(f"1. Accuracy (R-Squared): {r2:.4f}")
# print(f"2. Reliability (RMSE):   {rmse_kg:.2f} kg")
# print(f"3. Precision (MAE):      {mae_kg:.2f} kg")
# print(f"4. Interpretability (MAPE): {mape:.2f}%")
# print("-" * 60)

# # ==========================================
# # 6. RESEARCH GRAPHS (PRESERVED)
# # ==========================================
# print("\nStep 4: Generating Research Graphs...")

# # --- Graph 1: Feature Importance ---
# plt.figure(figsize=(10, 8))
# xgb.plot_importance(model, importance_type='gain', max_num_features=15, height=0.5, color='teal', title='XGBoost Feature Importance (Gain)')
# plt.tight_layout()
# plt.savefig(os.path.join(graphs_folder, "XGB_Feature_Importance.png"))
# plt.close()

# # --- Graph 2: Actual vs Predicted (Total Yield) ---
# plt.figure(figsize=(10, 6))
# sns.scatterplot(x=total_actual, y=total_pred, alpha=0.5, color='purple')
# plt.plot([total_actual.min(), total_actual.max()], [total_actual.min(), total_actual.max()], 'r--', lw=2)
# plt.xlabel('Actual Usable Yield (kg)')
# plt.ylabel('Predicted Usable Yield (kg)')
# plt.title(f'Model Accuracy: Actual vs Predicted (R-Squared = {r2:.3f})')
# plt.grid(True, linestyle='--', alpha=0.5)
# plt.tight_layout()
# plt.savefig(os.path.join(graphs_folder, "XGB_Actual_vs_Predicted.png"))
# plt.close()

# # --- Graph 3: SHAP Summary Plot ---
# explainer = shap.Explainer(model)
# shap_values = explainer(X_test)
# plt.figure(figsize=(10, 8))
# shap.summary_plot(shap_values, X_test, show=False)
# plt.title("SHAP Summary: Drivers of Efficiency", fontsize=14)
# plt.tight_layout()
# plt.savefig(os.path.join(graphs_folder, "SHAP_Summary_Plot.png"))
# plt.close()

# # --- Graph 4: SHAP Dependence Plot (Quality vs Rain) ---
# # Updated interaction to match Version 8 columns
# feature_to_plot = "num__G_Pct" if "num__G_Pct" in X_test.columns else "G_Pct"
# interaction_feature = "num__Rain_Accum_14d" if "num__Rain_Accum_14d" in X_test.columns else "Rain_Accum_14d"

# if feature_to_plot in X_test.columns:
#     fig, ax = plt.subplots(figsize=(10, 6))
#     shap.dependence_plot(feature_to_plot, shap_values.values, X_test, interaction_index=interaction_feature, ax=ax, show=False)
#     plt.title("Impact of Quality (G_Pct) on Efficiency", fontsize=14)
#     plt.tight_layout()
#     plt.savefig(os.path.join(graphs_folder, "SHAP_Dependence_G_Pct.png"), bbox_inches='tight')
#     plt.close()

# # --- Graph 5: Residuals Plot ---
# residuals = total_actual - total_pred
# plt.figure(figsize=(10, 6))
# sns.scatterplot(x=total_pred, y=residuals, alpha=0.5, color='crimson')
# plt.axhline(0, color='black', linestyle='--', linewidth=2)
# plt.xlabel('Predicted Yield (kg)')
# plt.ylabel('Error (Actual - Predicted) [kg]')
# plt.title('Residual Plot: Homoscedasticity Check')
# plt.grid(True, linestyle='--', alpha=0.5)
# plt.tight_layout()
# plt.savefig(os.path.join(graphs_folder, "XGB_Residuals_Plot.png"))
# plt.close()

# # --- Graph 6: Error Distribution ---
# plt.figure(figsize=(10, 6))
# sns.histplot(residuals, kde=True, color='orange', bins=30)
# plt.axvline(0, color='black', linestyle='--', linewidth=2)
# plt.title('Distribution of Errors (Residuals)')
# plt.xlabel('Prediction Error (kg)')
# plt.tight_layout()
# plt.savefig(os.path.join(graphs_folder, "XGB_Error_Distribution.png"))
# plt.close()

# # ==========================================
# # 9. SAVE CHAMPION MODEL
# # ==========================================
# model_path = os.path.join(artifacts_folder, "champion_efficiency_model.pkl")
# joblib.dump(model, model_path)
# print(f"\nChampion Model saved to: {model_path}")
# print("="*60)