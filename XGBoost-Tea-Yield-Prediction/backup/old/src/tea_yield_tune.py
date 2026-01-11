# # # import pandas as pd
# # # import numpy as np
# # # import xgboost as xgb
# # # import optuna
# # # import json
# # # import os
# # # import time
# # # from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error

# # # # ==========================================
# # # # 1. CONFIGURATION
# # # # ==========================================
# # # class TuneConfig:
# # #     PROJECT_NAME = "xgboost_yield_optimization"
# # #     N_TRIALS = 50        # Maximum number of trials (CPU-optimized)
# # #     TIMEOUT = 3600 * 2   # Stop after 2 hours

# # #     # Paths
# # #     PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # #     PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version8")
# # #     RESULTS_DIR = os.path.join(PROJECT_ROOT, "tuning_results7")
# # #     DB_NAME = "xgboost_tuning.db"

# # # # Ensure output directories exist
# # # os.makedirs(TuneConfig.RESULTS_DIR, exist_ok=True)

# # # # ==========================================
# # # # 2. LOAD DATA
# # # # ==========================================
# # # print("[INFO] Loading Processed Data for Tuning...")
# # # try:
# # #     X_train = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "X_train.csv"))
# # #     y_train = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "y_train.csv")).iloc[:, 0]

# # #     X_val   = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "X_val.csv"))
# # #     y_val   = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "y_val.csv")).iloc[:, 0]
# # # except FileNotFoundError:
# # #     print("CRITICAL ERROR: Data not found. Run Preprocessing.py first.")
# # #     exit()

# # # print(f"   - Train Rows: {len(X_train)}")
# # # print(f"   - Val Rows:   {len(X_val)}")

# # # # ==========================================
# # # # 3. LOGGING UTILITIES
# # # # ==========================================
# # # def save_trial_results(trial, params, metrics, model):
# # #     """Saves JSON stats and Model binary for every trial."""
# # #     trial_dir = os.path.join(TuneConfig.RESULTS_DIR, f"trial_{trial.number:03d}")
# # #     os.makedirs(trial_dir, exist_ok=True)

# # #     results = {
# # #         "trial_id": trial.number,
# # #         "status": "COMPLETED",
# # #         "metrics": metrics,
# # #         "hyperparameters": params
# # #     }

# # #     with open(os.path.join(trial_dir, "trial_stats.json"), "w") as f:
# # #         json.dump(results, f, indent=4)

# # #     model.save_model(os.path.join(trial_dir, "model.json"))

# # # def print_summary_table(study):
# # #     """Prints a professional summary table of the top 5 trials."""
# # #     print("\n" + "="*100)
# # #     print(f"{'TOP 5 CONFIGURATIONS (Sorted by MAE)':^100}")
# # #     print("="*100)
# # #     print(f"{'Trial':<6} | {'MAE (kg)':<10} | {'RMSE (kg)':<10} | {'R2':<8} | {'Booster':<8} | {'Trees':<6} | {'Depth':<6}")
# # #     print("-" * 100)

# # #     best_trials = sorted(study.trials, key=lambda t: t.value if t.value else float('inf'))[:5]

# # #     for t in best_trials:
# # #         if t.state != optuna.trial.TrialState.COMPLETE: continue
# # #         p = t.params
# # #         mae = t.value
# # #         rmse = t.user_attrs.get('rmse', 0)
# # #         r2 = t.user_attrs.get('r2', 0)

# # #         print(f"{t.number:<6} | {mae:<10.2f} | {rmse:<10.2f} | {r2:<8.4f} | "
# # #               f"{p['booster']:<8} | {p['n_estimators']:<6} | {p['max_depth']:<6}")
# # #     print("="*100 + "\n")

# # # # ==========================================
# # # # 4. OBJECTIVE FUNCTION
# # # # ==========================================
# # # # def objective(trial):
# # # #     # --- A. Search Space (CPU-optimized for research)
# # # #     params = {
# # # #         # Architecture
# # # #         'booster': trial.suggest_categorical('booster', ['gbtree', 'dart']),
# # # #         'n_estimators': trial.suggest_int('n_estimators', 500, 1500, step=100),  # CPU cap
# # # #         'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.1, log=True),
# # # #         'max_depth': trial.suggest_int('max_depth', 4, 8),

# # # #         # Regularization
# # # #         'subsample': trial.suggest_float('subsample', 0.6, 1.0),
# # # #         'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
# # # #         'gamma': trial.suggest_float('gamma', 0, 5.0),
# # # #         'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
# # # #         'reg_alpha': trial.suggest_float('reg_alpha', 1e-5, 10.0, log=True),
# # # #         'reg_lambda': trial.suggest_float('reg_lambda', 1e-5, 10.0, log=True),

# # # #         # CPU & reproducibility
# # # #         'n_jobs': -1,
# # # #         'random_state': 42,
# # # #         'objective': 'reg:squarederror'
# # # #     }

# # # #     # --- B. Train (XGBoost 2.0+ fix: early_stopping_rounds in constructor)
# # # #     model = xgb.XGBRegressor(**params, early_stopping_rounds=50)

# # # #     model.fit(
# # # #         X_train, y_train,
# # # #         eval_set=[(X_val, y_val)],
# # # #         verbose=False
# # # #     )

# # # #     # --- C. Evaluate (manual RMSE for sklearn ≥1.4)
# # # #     preds = model.predict(X_val)
# # # #     mae = mean_absolute_error(y_val, preds)
# # # #     mse = mean_squared_error(y_val, preds)
# # # #     rmse = np.sqrt(mse)
# # # #     r2 = r2_score(y_val, preds)

# # # #     trial.set_user_attr("rmse", rmse)
# # # #     trial.set_user_attr("r2", r2)

# # # #     # --- D. Save results
# # # #     metrics = {"mae": mae, "rmse": rmse, "r2": r2}
# # # #     save_trial_results(trial, params, metrics, model)

# # # #     print(f"[Trial {trial.number:02d}] {params['booster']:<6} | MAE: {mae:.2f} | RMSE: {rmse:.2f} | R2: {r2:.4f}")

# # # #     return mae  # Minimize MAE


# # # # ==========================================
# # # # 4. OBJECTIVE FUNCTION (Updated for Log-Target) (new)
# # # # ==========================================
# # # def objective(trial):
# # #     params = {
# # #         'booster': trial.suggest_categorical('booster', ['gbtree', 'dart']),
# # #         'n_estimators': trial.suggest_int('n_estimators', 800, 2000, step=100), # Increased for Log-Signal
# # #         'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.1, log=True),
# # #         'max_depth': trial.suggest_int('max_depth', 4, 10), # Expanded range for complex interactions
# # #         'subsample': trial.suggest_float('subsample', 0.6, 1.0),
# # #         'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
# # #         'gamma': trial.suggest_float('gamma', 0, 5.0),
# # #         'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
# # #         'reg_alpha': trial.suggest_float('reg_alpha', 1e-5, 10.0, log=True),
# # #         'reg_lambda': trial.suggest_float('reg_lambda', 1e-5, 10.0, log=True),
# # #         'n_jobs': -1,
# # #         'random_state': 42,
# # #         'objective': 'reg:squarederror'
# # #     }

# # #     model = xgb.XGBRegressor(**params, early_stopping_rounds=50)
    
# # #     model.fit(
# # #         X_train, y_train,
# # #         eval_set=[(X_val, y_val)],
# # #         verbose=False
# # #     )

# # #     # --- CRITICAL ADJUSTMENT FOR LOG-TRANSFORMATION ---
# # #     preds_log = model.predict(X_val)
    
# # #     # Convert Log back to Kilograms for meaningful MAE
# # #     preds_kg = np.expm1(preds_log) 
# # #     y_val_kg = np.expm1(y_val)
    
# # #     # Calculate real-world metrics
# # #     mae = mean_absolute_error(y_val_kg, preds_kg)
# # #     mse = mean_squared_error(y_val_kg, preds_kg)
# # #     rmse = np.sqrt(mse) 
# # #     r2 = r2_score(y_val_kg, preds_kg)
    
# # #     # Store attributes in DB
# # #     trial.set_user_attr("rmse", rmse)
# # #     trial.set_user_attr("r2", r2)

# # #     metrics = {"mae": mae, "rmse": rmse, "r2": r2}
# # #     save_trial_results(trial, params, metrics, model)
    
# # #     print(f"[Trial {trial.number:02d}] {params['booster']:<6} | MAE: {mae:.2f}kg | RMSE: {rmse:.2f}kg | R2: {r2:.4f}")

# # #     return mae # Optuna will minimize the error in Kilograms

# # # # ==========================================
# # # # 5. RUNNER
# # # # ==========================================
# # # if __name__ == "__main__":
# # #     print(f"\n[INFO] Starting Optuna Optimization...")
# # #     print(f"       Trials:  {TuneConfig.N_TRIALS}")
# # #     print(f"       Timeout: {TuneConfig.TIMEOUT} seconds")
# # #     print(f"       Storage: {os.path.join(TuneConfig.RESULTS_DIR, TuneConfig.DB_NAME)}")

# # #     db_path = os.path.join(TuneConfig.RESULTS_DIR, TuneConfig.DB_NAME)
# # #     storage_url = f"sqlite:///{db_path}"

# # #     study = optuna.create_study(
# # #         direction="minimize",
# # #         storage=storage_url,
# # #         study_name=TuneConfig.PROJECT_NAME,
# # #         load_if_exists=True
# # #     )

# # #     try:
# # #         study.optimize(
# # #             objective,
# # #             n_trials=TuneConfig.N_TRIALS,
# # #             timeout=TuneConfig.TIMEOUT
# # #         )
# # #     except KeyboardInterrupt:
# # #         print("\n[INFO] Tuning paused by user. Progress saved.")

# # #     print_summary_table(study)

# # #     print("COPY THIS DICTIONARY INTO 'train_xgboost.py':")
# # #     print("-" * 60)

# # #     best_params = study.best_params
# # #     best_params['n_jobs'] = -1
# # #     best_params['random_state'] = 42

# # #     print("xgb_params = {")
# # #     for k, v in best_params.items():
# # #         if isinstance(v, str):
# # #             print(f"    '{k}': '{v}',")
# # #         else:
# # #             print(f"    '{k}': {v},")
# # #     print("}")
# # #     print("-" * 60)



# # import pandas as pd
# # import numpy as np
# # import xgboost as xgb
# # import optuna
# # import json
# # import os
# # import time
# # from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error

# # # ==========================================
# # # 1. CONFIGURATION
# # # ==========================================
# # class TuneConfig:
# #     PROJECT_NAME = "xgboost_efficiency_optimization"
# #     N_TRIALS = 50        
# #     TIMEOUT = 3600 * 2   

# #     # Updated to your Final Version folder
# #     PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# #     PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version8")
# #     RESULTS_DIR = os.path.join(PROJECT_ROOT, "tuning_results8")
# #     DB_NAME = "xgboost_tuning.db"

# # os.makedirs(TuneConfig.RESULTS_DIR, exist_ok=True)

# # # ==========================================
# # # 2. LOAD DATA
# # # ==========================================
# # print("[INFO] Loading Processed Efficiency Data...")
# # try:
# #     X_train = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "X_train.csv"))
# #     y_train = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "y_train.csv")).iloc[:, 0]

# #     X_val   = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "X_val.csv"))
# #     y_val   = pd.read_csv(os.path.join(TuneConfig.PROCESSED_FOLDER, "y_val.csv")).iloc[:, 0]
# # except FileNotFoundError:
# #     print("CRITICAL ERROR: Data not found. Run the latest Preprocessing.py first.")
# #     exit()

# # print(f"   - Train Rows: {len(X_train)}")
# # print(f"   - Val Rows:   {len(X_val)}")
# # print(f"   - Target:     Yield Efficiency (kg/worker)")

# # # ==========================================
# # # 3. LOGGING UTILITIES
# # # ==========================================
# # def save_trial_results(trial, params, metrics, model):
# #     trial_dir = os.path.join(TuneConfig.RESULTS_DIR, f"trial_{trial.number:03d}")
# #     os.makedirs(trial_dir, exist_ok=True)
# #     results = {
# #         "trial_id": trial.number,
# #         "metrics": metrics,
# #         "hyperparameters": params
# #     }
# #     with open(os.path.join(trial_dir, "trial_stats.json"), "w") as f:
# #         json.dump(results, f, indent=4)
# #     model.save_model(os.path.join(trial_dir, "model.json"))

# # def print_summary_table(study):
# #     print("\n" + "="*100)
# #     print(f"{'TOP 5 CONFIGURATIONS (Efficiency Optimized)':^100}")
# #     print("="*100)
# #     print(f"{'Trial':<6} | {'MAE (kg/w)':<10} | {'RMSE (kg/w)':<10} | {'R2':<8} | {'Booster':<8} | {'Trees':<6} | {'Depth':<6}")
# #     print("-" * 100)
# #     best_trials = sorted(study.trials, key=lambda t: t.value if t.value else float('inf'))[:5]
# #     for t in best_trials:
# #         if t.state != optuna.trial.TrialState.COMPLETE: continue
# #         p = t.params
# #         print(f"{t.number:<6} | {t.value:<10.2f} | {t.user_attrs.get('rmse', 0):<10.2f} | "
# #               f"{t.user_attrs.get('r2', 0):<8.4f} | {p['booster']:<8} | {p['n_estimators']:<6} | {p['max_depth']:<6}")
# #     print("="*100 + "\n")

# # # ==========================================
# # # 4. OBJECTIVE FUNCTION (Linear Efficiency)
# # # ==========================================
# # def objective(trial):
# #     params = {
# #         'booster': trial.suggest_categorical('booster', ['gbtree', 'dart']),
# #         'n_estimators': trial.suggest_int('n_estimators', 1000, 2500, step=100), 
# #         'learning_rate': trial.suggest_float('learning_rate', 0.005, 0.05, log=True),
# #         'max_depth': trial.suggest_int('max_depth', 3, 8),
# #         'subsample': trial.suggest_float('subsample', 0.7, 1.0),
# #         'colsample_bytree': trial.suggest_float('colsample_bytree', 0.7, 1.0),
# #         'gamma': trial.suggest_float('gamma', 0, 2.0),
# #         'min_child_weight': trial.suggest_int('min_child_weight', 1, 15),
# #         'reg_alpha': trial.suggest_float('reg_alpha', 1e-5, 5.0, log=True),
# #         'reg_lambda': trial.suggest_float('reg_lambda', 1e-5, 5.0, log=True),
# #         'n_jobs': -1,
# #         'random_state': 42,
# #         'objective': 'reg:squarederror'
# #     }

# #     # XGBoost 2.0 Early Stopping fix
# #     model = xgb.XGBRegressor(**params, early_stopping_rounds=50)
    
# #     model.fit(
# #         X_train, y_train,
# #         eval_set=[(X_val, y_val)],
# #         verbose=False
# #     )

# #     preds = model.predict(X_val)
    
# #     # NO LOG CONVERSION: Metrics are calculated directly in kg/worker
# #     mae = mean_absolute_error(y_val, preds)
# #     mse = mean_squared_error(y_val, preds)
# #     rmse = np.sqrt(mse) 
# #     r2 = r2_score(y_val, preds)
    
# #     trial.set_user_attr("rmse", rmse)
# #     trial.set_user_attr("r2", r2)

# #     save_trial_results(trial, params, {"mae": mae, "rmse": rmse, "r2": r2}, model)
    
# #     print(f"[Trial {trial.number:02d}] {params['booster']:<6} | MAE: {mae:.4f}kg/w | R2: {r2:.4f}")

# #     return mae

# # # ==========================================
# # # 5. RUNNER
# # # ==========================================
# # if __name__ == "__main__":
# #     print(f"\n[INFO] Starting Efficiency-Based Optimization...")
# #     db_path = os.path.join(TuneConfig.RESULTS_DIR, TuneConfig.DB_NAME)
# #     storage_url = f"sqlite:///{db_path}"

# #     study = optuna.create_study(
# #         direction="minimize",
# #         storage=storage_url,
# #         study_name=TuneConfig.PROJECT_NAME,
# #         load_if_exists=True
# #     )

# #     try:
# #         study.optimize(objective, n_trials=TuneConfig.N_TRIALS, timeout=TuneConfig.TIMEOUT)
# #     except KeyboardInterrupt:
# #         print("\n[INFO] Tuning paused.")

# #     print_summary_table(study)
    
# #     print("COPY THIS DICTIONARY INTO 'train_xgboost.py':")
# #     print("-" * 60)
# #     best_params = study.best_params
# #     best_params['n_jobs'] = -1
# #     best_params['random_state'] = 42
    
# #     print("xgb_params = {")
# #     for k, v in best_params.items():
# #         print(f"    '{k}': '{v}',") if isinstance(v, str) else print(f"    '{k}': {v},")
# #     print("}")
# #     print("-" * 60)






# # import pandas as pd
# # import numpy as np
# # import xgboost as xgb
# # import optuna
# # import os
# # import joblib
# # from sklearn.model_selection import TimeSeriesSplit
# # from sklearn.metrics import mean_absolute_error, r2_score

# # # ==========================================
# # # 1. CONFIGURATION
# # # ==========================================
# # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed_Version8")
# # RESULTS_DIR = os.path.join(PROJECT_ROOT, "tuning_results8")
# # GRAPHS_DIR = os.path.join(PROJECT_ROOT, "Graphs_Tuning_Analysis8")

# # os.makedirs(RESULTS_DIR, exist_ok=True)
# # os.makedirs(GRAPHS_DIR, exist_ok=True)

# # # Load Data
# # print("[INFO] Loading Production-Efficiency Data...")
# # X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
# # y_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train.csv")).iloc[:, 0]

# # print(f"[INFO] Data loaded: {len(X_train):,} rows")
# # print(f"[INFO] Target (log-eff) range: min {y_train.min():.4f}, max {y_train.max():.4f}, mean {y_train.mean():.4f}")

# # # ==========================================
# # # 2. OBJECTIVE FUNCTION
# # # ==========================================
# # def objective(trial):
# #     params = {
# #         'booster': trial.suggest_categorical('booster', ['gbtree', 'dart']),
# #         'n_estimators': trial.suggest_int('n_estimators', 1000, 2500, step=100),
# #         'learning_rate': trial.suggest_float('learning_rate', 0.005, 0.08, log=True),
# #         'max_depth': trial.suggest_int('max_depth', 3, 10),
# #         'subsample': trial.suggest_float('subsample', 0.6, 0.9),
# #         'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 0.9),
# #         'gamma': trial.suggest_float('gamma', 0, 5.0),
# #         'min_child_weight': trial.suggest_int('min_child_weight', 1, 20),
# #         'reg_alpha': trial.suggest_float('reg_alpha', 1e-5, 10.0, log=True),
# #         'reg_lambda': trial.suggest_float('reg_lambda', 1e-5, 10.0, log=True),
# #         'n_jobs': -1,
# #         'random_state': 42,
# #         'objective': 'reg:squarederror'
# #     }

# #     # TimeSeriesSplit ensures no future-data leakage
# #     tscv = TimeSeriesSplit(n_splits=5)
# #     cv_mae_log = []
# #     cv_mae_kg = []
# #     cv_r2 = []

# #     for train_idx, val_idx in tscv.split(X_train):
# #         X_tr, X_vl = X_train.iloc[train_idx], X_train.iloc[val_idx]
# #         y_tr, y_vl = y_train.iloc[train_idx], y_train.iloc[val_idx]

# #         model = xgb.XGBRegressor(**params, early_stopping_rounds=50)
# #         model.fit(X_tr, y_tr, eval_set=[(X_vl, y_vl)], verbose=False)
        
# #         preds_log = model.predict(X_vl)
        
# #         cv_mae_log.append(mean_absolute_error(y_vl, preds_log))
# #         cv_mae_kg.append(mean_absolute_error(np.expm1(y_vl), np.expm1(preds_log)))
# #         cv_r2.append(r2_score(y_vl, preds_log))

# #     # Real-world metric for application tracking
# #     mean_mae_kg = np.mean(cv_mae_kg)
# #     mean_r2 = np.mean(cv_r2)
# #     trial.set_user_attr("mae_kg", mean_mae_kg)
# #     trial.set_user_attr("mae_log", np.mean(cv_mae_log))
# #     trial.set_user_attr("r2_avg", mean_r2)
    
# #     print(f"Trial {trial.number:03d} | Log-MAE: {np.mean(cv_mae_log):.4f} | Real-MAE: {mean_mae_kg:.2f} kg/w | R2: {mean_r2:.4f}")
# #     return np.mean(cv_mae_log)

# # # ==========================================
# # # 3. RUN OPTIMIZATION
# # # ==========================================
# # if __name__ == "__main__":
# #     print(f"\n[INFO] Starting Time-Aware Optimization (80 Trials)...")
# #     study = optuna.create_study(direction="minimize", study_name="tea_efficiency_final")
# #     study.optimize(objective, n_trials=80) 

# #     joblib.dump(study, os.path.join(RESULTS_DIR, "optuna_study_final.pkl"))

# #     print("[INFO] Exporting Verification Visualizations...")
# #     try:
# #         optuna.visualization.plot_optimization_history(study).write_html(os.path.join(GRAPHS_DIR, "1_History.html"))
# #         optuna.visualization.plot_param_importances(study).write_html(os.path.join(GRAPHS_DIR, "2_Importance.html"))
# #         optuna.visualization.plot_parallel_coordinate(study).write_html(os.path.join(GRAPHS_DIR, "3_Params_Interaction.html"))
# #         optuna.visualization.plot_slice(study).write_html(os.path.join(GRAPHS_DIR, "4_Search_Space.html"))
# #         print(f"✅ Visualizations saved to: {GRAPHS_DIR}")
# #     except Exception as e:
# #         print(f"⚠️ Visualization error: {e}")

# #     print("\n" + "="*60)
# #     print("🏆 FINAL BEST PARAMETERS (Copy to train_xgboost.py):")
# #     print("-" * 60)
# #     print(study.best_params)
# #     print(f"Best Real-World Error: {study.best_trial.user_attrs['mae_kg']:.2f} kg/worker")
# #     print(f"Average R2 Score: {study.best_trial.user_attrs['r2_avg']:.4f}")
# #     print("="*60)

# # import pandas as pd
# # import numpy as np
# # import xgboost as xgb
# # import optuna
# # import os
# # import joblib
# # import matplotlib.pyplot as plt
# # from sklearn.model_selection import TimeSeriesSplit
# # from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error
# # from sklearn.preprocessing import StandardScaler

# # # ==========================================
# # # 1. CONFIGURATION
# # # ==========================================
# # PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# # PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Pre_Processed11")  # Your actual folder
# # RESULTS_DIR = os.path.join(PROJECT_ROOT, "tuning_results11")
# # GRAPHS_DIR = os.path.join(PROJECT_ROOT, "Graphs_Tuning11")

# # os.makedirs(RESULTS_DIR, exist_ok=True)
# # os.makedirs(GRAPHS_DIR, exist_ok=True)

# # # Load Data
# # print("[INFO] Loading Processed Weekly Data...")
# # X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
# # y_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train.csv")).iloc[:, 0]

# # print(f"[INFO] Training samples: {len(X_train):,}")
# # print(f"[INFO] Features: {X_train.shape[1]}")

# # # Filter for humidity-related features (most important based on your analysis)
# # humidity_features = [col for col in X_train.columns if 'humidity' in col.lower() or 'Humidity' in col]
# # print(f"[INFO] Humidity-related features: {len(humidity_features)}")
# # print(f"Top humidity features: {humidity_features[:10]}")

# # # ==========================================
# # # 2. HUMIDITY-FOCUSED OBJECTIVE FUNCTION
# # # ==========================================
# # def objective(trial):
# #     # Core parameters optimized for weekly data
# #     params = {
# #         'booster': 'gbtree',
# #         'n_estimators': trial.suggest_int('n_estimators', 200, 600, step=50),
# #         'learning_rate': trial.suggest_float('learning_rate', 0.005, 0.1, log=True),
        
# #         # SHALLOWER TREES for weekly aggregated data
# #         'max_depth': trial.suggest_int('max_depth', 3, 5),
        
# #         # Regularization - CRITICAL for modest signals
# #         'subsample': trial.suggest_float('subsample', 0.6, 0.9),
# #         'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 0.9),
# #         'colsample_bylevel': trial.suggest_float('colsample_bylevel', 0.6, 0.9),
        
# #         # Tree complexity control
# #         'gamma': trial.suggest_float('gamma', 0, 1.5),
# #         'min_child_weight': trial.suggest_int('min_child_weight', 1, 8),
        
# #         # L1/L2 regularization
# #         'reg_alpha': trial.suggest_float('reg_alpha', 1e-3, 2.0, log=True),
# #         'reg_lambda': trial.suggest_float('reg_lambda', 0.5, 3.0),
        
# #         # XGBoost settings
# #         'n_jobs': -1,
# #         'random_state': 42,
# #         'objective': 'reg:squarederror',
        
# #         # NEW: Monotonic constraints for humidity features
# #         # Positive for optimal humidity, negative for extreme humidity
# #         'monotone_constraints': get_monotone_constraints(X_train.columns),
        
# #         # NEW: Early stopping patience
# #         'early_stopping_rounds': 50
# #     }

# #     # Time series cross-validation
# #     tscv = TimeSeriesSplit(n_splits=3)
# #     cv_scores = {
# #         'mae_log': [],
# #         'r2': [],
# #         'mae_kg': [],
# #         'rmse_kg': []
# #     }
    
# #     fold_importances = []

# #     for fold, (train_idx, val_idx) in enumerate(tscv.split(X_train)):
# #         X_tr, X_vl = X_train.iloc[train_idx], X_train.iloc[val_idx]
# #         y_tr, y_vl = y_train.iloc[train_idx], y_train.iloc[val_idx]
        
# #         # Scale features for better convergence
# #         scaler = StandardScaler()
# #         X_tr_scaled = scaler.fit_transform(X_tr)
# #         X_vl_scaled = scaler.transform(X_vl)
        
# #         model = xgb.XGBRegressor(**params)
# #         model.fit(
# #             X_tr_scaled, y_tr,
# #             eval_set=[(X_vl_scaled, y_vl)],
# #             verbose=False
# #         )
        
# #         # Predictions
# #         preds_log = model.predict(X_vl_scaled)
        
# #         # Log-space metrics
# #         cv_scores['mae_log'].append(mean_absolute_error(y_vl, preds_log))
# #         cv_scores['r2'].append(r2_score(y_vl, preds_log))
        
# #         # Real-space metrics (kg/worker)
# #         y_vl_kg = np.expm1(y_vl)
# #         preds_kg = np.expm1(preds_log)
        
# #         cv_scores['mae_kg'].append(mean_absolute_error(y_vl_kg, preds_kg))
# #         cv_scores['rmse_kg'].append(np.sqrt(mean_squared_error(y_vl_kg, preds_kg)))
        
# #         # Collect feature importances
# #         fold_importances.append(model.feature_importances_)
    
# #     # Calculate metrics
# #     mean_r2 = np.mean(cv_scores['r2'])
# #     mean_mae_kg = np.mean(cv_scores['mae_kg'])
    
# #     # Store in trial
# #     trial.set_user_attr("r2_avg", mean_r2)
# #     trial.set_user_attr("mae_kg", mean_mae_kg)
# #     trial.set_user_attr("rmse_kg", np.mean(cv_scores['rmse_kg']))
    
# #     # Calculate humidity feature importance
# #     humidity_importance = calculate_humidity_importance(X_train.columns, fold_importances)
# #     trial.set_user_attr("humidity_importance", humidity_importance)
    
# #     print(f"Trial {trial.number:03d} | R²: {mean_r2:.4f} | MAE: {mean_mae_kg:.2f} kg/w | Humidity Imp: {humidity_importance:.3f}")
    
# #     # Primary objective: minimize MAE in log space
# #     # Secondary: maximize R² (handled via trial attributes)
# #     return np.mean(cv_scores['mae_log'])

# # def get_monotone_constraints(feature_names):
# #     """Apply monotonic constraints based on feature names"""
# #     constraints = []
# #     for name in feature_names:
# #         if 'humidity' in name.lower():
# #             if 'mean' in name.lower() or 'avg' in name.lower():
# #                 # Positive: Higher average humidity (within range) is better
# #                 constraints.append(1)
# #             elif 'stress' in name.lower() or 'deficit' in name.lower() or 'std' in name.lower():
# #                 # Negative: Higher stress/deficit/volatility is worse
# #                 constraints.append(-1)
# #             else:
# #                 constraints.append(0)
# #         elif 'temp' in name.lower():
# #             if 'heat' in name.lower():
# #                 constraints.append(-1)  # Heat stress is bad
# #             else:
# #                 constraints.append(0)
# #         else:
# #             constraints.append(0)
# #     return tuple(constraints)

# # def calculate_humidity_importance(feature_names, fold_importances):
# #     """Calculate what % of feature importance comes from humidity features"""
# #     humidity_indices = [i for i, name in enumerate(feature_names) 
# #                        if 'humidity' in name.lower() or 'Humidity' in name]
    
# #     if not humidity_indices:
# #         return 0.0
    
# #     total_importance = 0
# #     humidity_importance = 0
    
# #     for imp_array in fold_importances:
# #         total_importance += imp_array.sum()
# #         humidity_importance += imp_array[humidity_indices].sum()
    
# #     return humidity_importance / total_importance if total_importance > 0 else 0

# # # ==========================================
# # # 3. RUN OPTIMIZATION WITH SMART START
# # # ==========================================
# # if __name__ == "__main__":
# #     print("\n" + "="*60)
# #     print("🚀 STARTING HUMIDITY-FOCUSED XGBOOST OPTIMIZATION")
# #     print("="*60)
    
# #     study = optuna.create_study(
# #         direction="minimize",
# #         study_name="tea_weekly_humidity_focused",
# #         sampler=optuna.samplers.TPESampler(
# #             n_startup_trials=25,
# #             consider_prior=True,
# #             prior_weight=1.0,
# #             seed=42
# #         ),
# #         pruner=optuna.pruners.MedianPruner(
# #             n_startup_trials=10,
# #             n_warmup_steps=5
# #         )
# #     )

# #     # Smart initial parameters based on your correlation analysis
# #     study.enqueue_trial({
# #         'n_estimators': 350,
# #         'learning_rate': 0.03,
# #         'max_depth': 4,
# #         'subsample': 0.75,
# #         'colsample_bytree': 0.75,
# #         'colsample_bylevel': 0.75,
# #         'gamma': 0.2,
# #         'min_child_weight': 4,
# #         'reg_alpha': 0.3,
# #         'reg_lambda': 1.5
# #     })

# #     # Add another good starting point
# #     study.enqueue_trial({
# #         'n_estimators': 400,
# #         'learning_rate': 0.02,  # Slower learning for subtle signals
# #         'max_depth': 3,  # Very shallow for weekly data
# #         'subsample': 0.8,
# #         'colsample_bytree': 0.8,
# #         'colsample_bylevel': 0.7,
# #         'gamma': 0.5,  # More regularization
# #         'min_child_weight': 6,
# #         'reg_alpha': 0.5,
# #         'reg_lambda': 2.0
# #     })

# #     # Optimization with progress monitoring
# #     def print_best_trial_info(study, trial):
# #         if trial.number % 10 == 0:
# #             print(f"\n📊 Progress Update (Trial {trial.number}):")
# #             print(f"   Best R² so far: {study.best_trial.user_attrs['r2_avg']:.4f}")
# #             print(f"   Best MAE (kg): {study.best_trial.user_attrs['mae_kg']:.2f}")
# #             print(f"   Humidity Importance: {study.best_trial.user_attrs['humidity_importance']:.3f}")

# #     study.optimize(
# #         objective, 
# #         n_trials=80,  # Fewer trials due to modest signals
# #         callbacks=[print_best_trial_info],
# #         show_progress_bar=True
# #     )

# #     # Save results
# #     joblib.dump(study, os.path.join(RESULTS_DIR, "optuna_study_humidity_focused.pkl"))
    
# #     # Save best model configuration
# #     best_config = {
# #         'params': study.best_params,
# #         'metrics': {
# #             'r2': study.best_trial.user_attrs['r2_avg'],
# #             'mae_kg': study.best_trial.user_attrs['mae_kg'],
# #             'rmse_kg': study.best_trial.user_attrs['rmse_kg'],
# #             'humidity_importance': study.best_trial.user_attrs['humidity_importance']
# #         },
# #         'features': list(X_train.columns)
# #     }
    
# #     joblib.dump(best_config, os.path.join(RESULTS_DIR, "best_model_config.pkl"))

# #     # ==========================================
# #     # 4. ANALYSIS AND VISUALIZATION
# #     # ==========================================
# #     print("\n" + "="*60)
# #     print("🏆 FINAL RESULTS")
# #     print("="*60)
    
# #     print(f"\nBest Parameters:")
# #     for key, value in study.best_params.items():
# #         print(f"  {key}: {value}")
    
# #     print(f"\nPerformance Metrics:")
# #     print(f"  R² Score: {study.best_trial.user_attrs['r2_avg']:.4f}")
# #     print(f"  MAE (kg/worker): {study.best_trial.user_attrs['mae_kg']:.2f}")
# #     print(f"  RMSE (kg/worker): {study.best_trial.user_attrs['rmse_kg']:.2f}")
# #     print(f"  Humidity Feature Importance: {study.best_trial.user_attrs['humidity_importance']:.3f}")
    
# #     # Train final model with best parameters
# #     print("\n🎯 Training Final Model...")
    
# #     # Scale features
# #     scaler = StandardScaler()
# #     X_train_scaled = scaler.fit_transform(X_train)
    
# #     final_model = xgb.XGBRegressor(**study.best_params)
# #     final_model.fit(X_train_scaled, y_train)
    
# #     # Save model and scaler
# #     joblib.dump(final_model, os.path.join(RESULTS_DIR, "final_xgb_model.pkl"))
# #     joblib.dump(scaler, os.path.join(RESULTS_DIR, "feature_scaler.pkl"))
    
# #     # Feature importance plot
# #     plt.figure(figsize=(12, 8))
# #     importance_df = pd.DataFrame({
# #         'feature': X_train.columns,
# #         'importance': final_model.feature_importances_
# #     }).sort_values('importance', ascending=False).head(20)
    
# #     colors = ['green' if 'humidity' in f.lower() else 'blue' for f in importance_df['feature']]
# #     plt.barh(range(len(importance_df)), importance_df['importance'], color=colors)
# #     plt.yticks(range(len(importance_df)), importance_df['feature'])
# #     plt.xlabel('Feature Importance')
# #     plt.title('Top 20 Features (Green = Humidity-related)')
# #     plt.gca().invert_yaxis()
# #     plt.tight_layout()
# #     plt.savefig(os.path.join(GRAPHS_DIR, "feature_importance.png"), dpi=300)
    
# #     # Optimization history
# #     fig = optuna.visualization.plot_optimization_history(study)
# #     fig.write_html(os.path.join(GRAPHS_DIR, "optimization_history.html"))
    
# #     # Parameter importance
# #     fig = optuna.visualization.plot_param_importances(study)
# #     fig.write_html(os.path.join(GRAPHS_DIR, "parameter_importance.html"))
    
# #     print(f"\n✅ Optimization Complete!")
# #     print(f"   Results saved to: {RESULTS_DIR}")
# #     print(f"   Graphs saved to: {GRAPHS_DIR}")
    
# #     # Performance expectations
# #     print(f"\n📈 EXPECTED PERFORMANCE:")
# #     print(f"   • Humidity explains ~{study.best_trial.user_attrs['humidity_importance']*100:.1f}% of model decisions")
# #     print(f"   • Model accuracy: ±{study.best_trial.user_attrs['mae_kg']:.1f} kg/worker")
# #     print(f"   • R² of {study.best_trial.user_attrs['r2_avg']:.3f} suggests humidity is a")
# #     print(f"     MODERATE but SIGNIFICANT driver in your high-humidity region")

# """
# FINAL THESIS TUNING CODE - USING SUCCESSFUL DATA
# =================================================
# Fixed version that uses your proven successful data (R² = 0.792)
# """

# import pandas as pd
# import numpy as np
# import xgboost as xgb
# import optuna
# import os
# import joblib
# import matplotlib.pyplot as plt
# import seaborn as sns
# from sklearn.model_selection import TimeSeriesSplit
# from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error, mean_absolute_percentage_error
# import warnings
# warnings.filterwarnings('ignore')

# # ==========================================
# # 1. CONFIGURATION - USE SUCCESSFUL DATA
# # ==========================================
# PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
# PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Thesis_Processed_Final")  # USE YOUR SUCCESSFUL DATA!
# RESULTS_DIR = os.path.join(PROJECT_ROOT, "Final_Thesis_Results")
# GRAPHS_DIR = os.path.join(PROJECT_ROOT, "Final_Thesis_Graphs")
# MODEL_DIR = os.path.join(PROJECT_ROOT, "Final_Thesis_Models")

# for folder in [RESULTS_DIR, GRAPHS_DIR, MODEL_DIR]:
#     os.makedirs(folder, exist_ok=True)

# # ==========================================
# # 2. LOAD PROVEN SUCCESSFUL DATA
# # ==========================================
# print("="*80)
# print("TEA YIELD PREDICTION - FINAL THESIS TUNING")
# print("="*80)
# print("\nUsing your proven successful data (R² = 0.792)")

# # Load successful data
# X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
# X_val = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"))
# X_test = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"))

# y_train_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train.csv")).iloc[:, 0]
# y_val_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val.csv")).iloc[:, 0]
# y_test_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test.csv")).iloc[:, 0]

# print(f"\n[INFO] Data loaded successfully!")
# print(f"  Training samples: {len(X_train):,}")
# print(f"  Validation samples: {len(X_val):,}")
# print(f"  Test samples: {len(X_test):,}")
# print(f"  Features: {X_train.shape[1]}")
# print(f"  Target: Log Efficiency (kg/worker)")
# print(f"  Log efficiency - Mean: {y_train_log.mean():.3f}, Std: {y_train_log.std():.3f}")

# # Convert to kg for practical interpretation
# y_train_kg = np.expm1(y_train_log)
# y_val_kg = np.expm1(y_val_log)
# y_test_kg = np.expm1(y_test_log)

# print(f"  Yield (kg) - Mean: {y_train_kg.mean():.1f}, Range: {y_train_kg.min():.1f}-{y_train_kg.max():.1f}")

# # Analyze humidity features
# humidity_features = [col for col in X_train.columns if 'humidity' in col.lower()]
# print(f"\n[INFO] Humidity analysis:")
# print(f"  Humidity features: {len(humidity_features)}")
# if humidity_features:
#     print(f"  Top 3: {humidity_features[:3]}")

# # ==========================================
# # 3. OPTIMIZATION OBJECTIVE
# # ==========================================
# def objective(trial):
#     """Objective function for final thesis tuning."""
    
#     # Optimized parameters based on your success
#     params = {
#         'booster': 'gbtree',
#         'n_estimators': trial.suggest_int('n_estimators', 100, 300),
#         'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.1, log=True),
#         'max_depth': trial.suggest_int('max_depth', 3, 5),
#         'subsample': trial.suggest_float('subsample', 0.7, 0.95),
#         'colsample_bytree': trial.suggest_float('colsample_bytree', 0.7, 0.95),
#         'colsample_bylevel': trial.suggest_float('colsample_bylevel', 0.7, 0.9),
#         'gamma': trial.suggest_float('gamma', 0, 1.0),
#         'min_child_weight': trial.suggest_int('min_child_weight', 1, 5),
#         'reg_alpha': trial.suggest_float('reg_alpha', 0.001, 1.0, log=True),
#         'reg_lambda': trial.suggest_float('reg_lambda', 0.5, 2.0),
#         'n_jobs': -1,
#         'random_state': 42,
#         'objective': 'reg:squarederror',
#     }

#     # Time series cross-validation
#     tscv = TimeSeriesSplit(n_splits=3)
#     cv_scores = {
#         'r2_log': [],
#         'mae_log': [],
#         'r2_kg': [],
#         'mae_kg': [],
#         'mape_kg': []
#     }
    
#     humidity_importances = []

#     for fold, (train_idx, val_idx) in enumerate(tscv.split(X_train)):
#         X_tr, X_vl = X_train.iloc[train_idx], X_train.iloc[val_idx]
#         y_tr, y_vl = y_train_log.iloc[train_idx], y_train_log.iloc[val_idx]
        
#         model = xgb.XGBRegressor(**params)
#         model.fit(
#             X_tr, y_tr,
#             eval_set=[(X_vl, y_vl)],
#             verbose=False,
#             early_stopping_rounds=20
#         )
        
#         # Predictions in log space
#         preds_log = model.predict(X_vl)
        
#         # Log-space metrics
#         cv_scores['r2_log'].append(r2_score(y_vl, preds_log))
#         cv_scores['mae_log'].append(mean_absolute_error(y_vl, preds_log))
        
#         # Convert to kg for practical metrics
#         y_vl_kg = np.expm1(y_vl)
#         preds_kg = np.expm1(preds_log)
        
#         # Kg-space metrics
#         cv_scores['r2_kg'].append(r2_score(y_vl_kg, preds_kg))
#         cv_scores['mae_kg'].append(mean_absolute_error(y_vl_kg, preds_kg))
        
#         # Calculate MAPE (avoid division by zero)
#         valid_mask = y_vl_kg > 0
#         if valid_mask.any():
#             mape = np.mean(np.abs((y_vl_kg[valid_mask] - preds_kg[valid_mask]) / y_vl_kg[valid_mask])) * 100
#         else:
#             mape = 0
#         cv_scores['mape_kg'].append(mape)
        
#         # Humidity importance
#         humidity_idx = [i for i, col in enumerate(X_train.columns) 
#                        if 'humidity' in col.lower()]
#         if humidity_idx:
#             total_imp = model.feature_importances_.sum()
#             humidity_imp = model.feature_importances_[humidity_idx].sum()
#             humidity_importances.append(humidity_imp / total_imp if total_imp > 0 else 0)
    
#     # Calculate averages
#     mean_r2_log = np.mean(cv_scores['r2_log'])
#     mean_r2_kg = np.mean(cv_scores['r2_kg'])
#     mean_mae_kg = np.mean(cv_scores['mae_kg'])
#     mean_mape_kg = np.mean(cv_scores['mape_kg'])
#     mean_humidity_imp = np.mean(humidity_importances) if humidity_importances else 0
    
#     # Store metrics
#     trial.set_user_attr("r2_log", mean_r2_log)
#     trial.set_user_attr("r2_kg", mean_r2_kg)
#     trial.set_user_attr("mae_kg", mean_mae_kg)
#     trial.set_user_attr("mape_kg", mean_mape_kg)
#     trial.set_user_attr("humidity_importance", mean_humidity_imp)
    
#     # Progress display
#     print(f"Trial {trial.number:03d} | R²(log): {mean_r2_log:.4f} | R²(kg): {mean_r2_kg:.4f} | "
#           f"MAE: {mean_mae_kg:.1f} kg | Humidity: {mean_humidity_imp:.3f}")
    
#     # Primary objective: maximize R² in log space
#     return -mean_r2_log  # Negative because Optuna minimizes

# # ==========================================
# # 4. OPTIMIZATION WITH SMART STARTING POINTS
# # ==========================================
# if __name__ == "__main__":
#     print("\n" + "="*80)
#     print("🚀 STARTING FINAL THESIS OPTIMIZATION")
#     print("="*80)
    
#     # Create study
#     study = optuna.create_study(
#         direction="minimize",
#         study_name="final_thesis_tuning",
#         sampler=optuna.samplers.TPESampler(
#             n_startup_trials=15,
#             consider_prior=True,
#             prior_weight=1.5,
#             seed=42
#         ),
#         pruner=optuna.pruners.MedianPruner(
#             n_startup_trials=5,
#             n_warmup_steps=3
#         )
#     )

#     # Smart starting points based on your success
#     print("\n[INFO] Starting with proven parameters...")
    
#     study.enqueue_trial({
#         'n_estimators': 200,
#         'learning_rate': 0.05,
#         'max_depth': 4,
#         'subsample': 0.8,
#         'colsample_bytree': 0.8,
#         'colsample_bylevel': 0.8,
#         'gamma': 0.1,
#         'min_child_weight': 3,
#         'reg_alpha': 0.1,
#         'reg_lambda': 1.0
#     })
    
#     study.enqueue_trial({
#         'n_estimators': 150,
#         'learning_rate': 0.1,
#         'max_depth': 3,
#         'subsample': 0.9,
#         'colsample_bytree': 0.9,
#         'colsample_bylevel': 0.8,
#         'gamma': 0.2,
#         'min_child_weight': 4,
#         'reg_alpha': 0.05,
#         'reg_lambda': 1.5
#     })

#     # Progress callback
#     def print_best_trial_info(study, trial):
#         if trial.number % 10 == 0 or trial.number == 1:
#             print(f"\n📊 Progress Update (Trial {trial.number}):")
#             print(f"   Best R²(log): {-study.best_value:.4f}")
#             print(f"   Best R²(kg): {study.best_trial.user_attrs['r2_kg']:.4f}")
#             print(f"   Best MAE: {study.best_trial.user_attrs['mae_kg']:.1f} kg")
#             print(f"   Humidity Importance: {study.best_trial.user_attrs['humidity_importance']:.3f}")

#     # Run optimization
#     print("\n[INFO] Running optimization...")
#     study.optimize(
#         objective, 
#         n_trials=30,  # Fewer trials since we're starting close to optimum
#         callbacks=[print_best_trial_info],
#         show_progress_bar=True
#     )

#     # ==========================================
#     # 5. TRAIN FINAL MODEL
#     # ==========================================
#     print("\n" + "="*80)
#     print("🎯 TRAINING FINAL THESIS MODEL")
#     print("="*80)
    
#     print(f"\n[INFO] Best trial found:")
#     print(f"  R²(log): {-study.best_value:.4f}")
#     print(f"  R²(kg): {study.best_trial.user_attrs['r2_kg']:.4f}")
#     print(f"  MAE: {study.best_trial.user_attrs['mae_kg']:.1f} kg")
#     print(f"  MAPE: {study.best_trial.user_attrs['mape_kg']:.1f}%")
#     print(f"  Humidity Importance: {study.best_trial.user_attrs['humidity_importance']:.3f}")
    
#     print("\n[INFO] Best parameters:")
#     for key, value in study.best_params.items():
#         print(f"  {key}: {value}")
    
#     # Train final model
#     print("\n[INFO] Training final model...")
    
#     final_params = study.best_params.copy()
#     final_params['n_jobs'] = -1
#     final_params['random_state'] = 42
#     final_params['objective'] = 'reg:squarederror'
    
#     final_model = xgb.XGBRegressor(**final_params)
#     final_model.fit(
#         X_train, y_train_log,
#         eval_set=[(X_val, y_val_log)],
#         verbose=True,
#         early_stopping_rounds=20
#     )
    
#     # Predictions
#     train_preds_log = final_model.predict(X_train)
#     val_preds_log = final_model.predict(X_val)
#     test_preds_log = final_model.predict(X_test)
    
#     # Convert to kg for practical interpretation
#     train_preds_kg = np.expm1(train_preds_log)
#     val_preds_kg = np.expm1(val_preds_log)
#     test_preds_kg = np.expm1(test_preds_log)
    
#     train_actual_kg = np.expm1(y_train_log)
#     val_actual_kg = np.expm1(y_val_log)
#     test_actual_kg = np.expm1(y_test_log)
    
#     # Calculate comprehensive metrics
#     def calculate_metrics(y_true, y_pred, name):
#         valid_mask = y_true > 0
#         if valid_mask.any():
#             y_true_valid = y_true[valid_mask]
#             y_pred_valid = y_pred[valid_mask]
#             mape = np.mean(np.abs((y_true_valid - y_pred_valid) / y_true_valid)) * 100
#         else:
#             mape = 0
            
#         return {
#             'dataset': name,
#             'r2': r2_score(y_true, y_pred),
#             'mae': mean_absolute_error(y_true, y_pred),
#             'rmse': np.sqrt(mean_squared_error(y_true, y_pred)),
#             'mape': mape,
#             'mean_actual': y_true.mean(),
#             'mean_predicted': y_pred.mean(),
#             'std_actual': y_true.std(),
#             'std_predicted': y_pred.std()
#         }
    
#     metrics = [
#         calculate_metrics(train_actual_kg, train_preds_kg, 'Training'),
#         calculate_metrics(val_actual_kg, val_preds_kg, 'Validation'),
#         calculate_metrics(test_actual_kg, test_preds_kg, 'Test')
#     ]
    
#     metrics_df = pd.DataFrame(metrics)
    
#     # ==========================================
#     # 6. SAVE RESULTS (FIXED VERSION)
#     # ==========================================
#     print("\n" + "="*80)
#     print("💾 SAVING FINAL RESULTS")
#     print("="*80)
    
#     # Save study
#     joblib.dump(study, os.path.join(RESULTS_DIR, "final_study.pkl"))
    
#     # Save model
#     joblib.dump(final_model, os.path.join(MODEL_DIR, "final_model.pkl"))
    
#     # Save predictions - FIXED: Ensure all arrays have same length
#     max_len = max(len(train_actual_kg), len(val_actual_kg), len(test_actual_kg))
    
#     predictions_data = {}
    
#     # Training data
#     predictions_data['train_actual_kg'] = np.pad(train_actual_kg.values, 
#                                                (0, max_len - len(train_actual_kg)), 
#                                                constant_values=np.nan)
#     predictions_data['train_predicted_kg'] = np.pad(train_preds_kg, 
#                                                    (0, max_len - len(train_preds_kg)), 
#                                                    constant_values=np.nan)
#     predictions_data['train_actual_log'] = np.pad(y_train_log.values, 
#                                                  (0, max_len - len(y_train_log)), 
#                                                  constant_values=np.nan)
#     predictions_data['train_predicted_log'] = np.pad(train_preds_log, 
#                                                     (0, max_len - len(train_preds_log)), 
#                                                     constant_values=np.nan)
    
#     # Validation data
#     predictions_data['val_actual_kg'] = np.pad(val_actual_kg.values, 
#                                               (0, max_len - len(val_actual_kg)), 
#                                               constant_values=np.nan)
#     predictions_data['val_predicted_kg'] = np.pad(val_preds_kg, 
#                                                  (0, max_len - len(val_preds_kg)), 
#                                                  constant_values=np.nan)
#     predictions_data['val_actual_log'] = np.pad(y_val_log.values, 
#                                                (0, max_len - len(y_val_log)), 
#                                                constant_values=np.nan)
#     predictions_data['val_predicted_log'] = np.pad(val_preds_log, 
#                                                   (0, max_len - len(val_preds_log)), 
#                                                   constant_values=np.nan)
    
#     # Test data
#     predictions_data['test_actual_kg'] = np.pad(test_actual_kg.values, 
#                                                (0, max_len - len(test_actual_kg)), 
#                                                constant_values=np.nan)
#     predictions_data['test_predicted_kg'] = np.pad(test_preds_kg, 
#                                                   (0, max_len - len(test_preds_kg)), 
#                                                   constant_values=np.nan)
#     predictions_data['test_actual_log'] = np.pad(y_test_log.values, 
#                                                 (0, max_len - len(y_test_log)), 
#                                                 constant_values=np.nan)
#     predictions_data['test_predicted_log'] = np.pad(test_preds_log, 
#                                                    (0, max_len - len(test_preds_log)), 
#                                                    constant_values=np.nan)
    
#     predictions_df = pd.DataFrame(predictions_data)
#     predictions_df.to_csv(os.path.join(RESULTS_DIR, "final_predictions.csv"), index=False)
    
#     # Save metrics
#     metrics_df.to_csv(os.path.join(RESULTS_DIR, "final_metrics.csv"), index=False)
    
#     # Save feature importance
#     importance_df = pd.DataFrame({
#         'feature': X_train.columns,
#         'importance': final_model.feature_importances_
#     }).sort_values('importance', ascending=False)
#     importance_df.to_csv(os.path.join(RESULTS_DIR, "final_feature_importance.csv"), index=False)
    
#     # ==========================================
#     # 7. CREATE VISUALIZATIONS
#     # ==========================================
#     print("\n" + "="*80)
#     print("📊 CREATING FINAL VISUALIZATIONS")
#     print("="*80)
    
#     # 1. Feature Importance
#     plt.figure(figsize=(12, 6))
#     top_features = importance_df.head(15)
    
#     colors = []
#     for f in top_features['feature']:
#         f_lower = f.lower()
#         if 'humidity' in f_lower:
#             colors.append('#3498db')  # Blue for humidity
#         elif 'temp' in f_lower:
#             colors.append('#e74c3c')  # Red for temperature
#         elif 'rain' in f_lower:
#             colors.append('#27ae60')  # Green for rainfall
#         elif 'labor' in f_lower:
#             colors.append('#f39c12')  # Orange for labor
#         else:
#             colors.append('#95a5a6')  # Gray for others
    
#     plt.barh(range(len(top_features)), top_features['importance'], color=colors)
#     plt.yticks(range(len(top_features)), top_features['feature'])
#     plt.xlabel('Feature Importance')
#     plt.title('Top 15 Features for Tea Yield Prediction', fontsize=14, fontweight='bold')
#     plt.gca().invert_yaxis()
#     plt.grid(True, alpha=0.3, axis='x')
#     plt.tight_layout()
#     plt.savefig(os.path.join(GRAPHS_DIR, "final_feature_importance.png"), dpi=300, bbox_inches='tight')
#     plt.close()
    
#     # 2. Actual vs Predicted
#     fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
#     datasets = [
#         (train_actual_kg, train_preds_kg, 'Training', 'blue', metrics_df.loc[0, 'r2'], metrics_df.loc[0, 'mae']),
#         (val_actual_kg, val_preds_kg, 'Validation', 'green', metrics_df.loc[1, 'r2'], metrics_df.loc[1, 'mae']),
#         (test_actual_kg, test_preds_kg, 'Test', 'red', metrics_df.loc[2, 'r2'], metrics_df.loc[2, 'mae'])
#     ]
    
#     for idx, (actual, pred, title, color, r2, mae) in enumerate(datasets):
#         axes[idx].scatter(actual, pred, alpha=0.5, s=10, color=color)
#         axes[idx].plot([actual.min(), actual.max()], 
#                       [actual.min(), actual.max()], 'k--', alpha=0.8, linewidth=1)
#         axes[idx].set_xlabel('Actual Yield (kg)', fontsize=11)
#         axes[idx].set_ylabel('Predicted Yield (kg)', fontsize=11)
#         axes[idx].set_title(f'{title} Set\nR² = {r2:.3f}, MAE = {mae:.1f} kg', fontsize=12)
#         axes[idx].grid(True, alpha=0.3)
    
#     plt.suptitle('Tea Yield Prediction Performance - Final Thesis Model', fontsize=14, fontweight='bold')
#     plt.tight_layout()
#     plt.savefig(os.path.join(GRAPHS_DIR, "final_prediction_performance.png"), dpi=300, bbox_inches='tight')
#     plt.close()
    
#     # 3. Humidity Analysis
#     humidity_imp = importance_df[importance_df['feature'].str.contains('humidity', case=False)]
#     if len(humidity_imp) > 0:
#         plt.figure(figsize=(10, 5))
#         humidity_imp = humidity_imp.sort_values('importance', ascending=True)
        
#         plt.barh(range(len(humidity_imp)), humidity_imp['importance'], color='#3498db')
#         plt.yticks(range(len(humidity_imp)), humidity_imp['feature'])
#         plt.xlabel('Feature Importance')
#         plt.title(f'Humidity Features Contribution\nTotal Humidity Importance: {study.best_trial.user_attrs["humidity_importance"]*100:.1f}%', 
#                  fontsize=12, fontweight='bold')
#         plt.grid(True, alpha=0.3, axis='x')
#         plt.tight_layout()
#         plt.savefig(os.path.join(GRAPHS_DIR, "final_humidity_contribution.png"), dpi=300, bbox_inches='tight')
#         plt.close()
    
#     # ==========================================
#     # 8. FINAL THESIS REPORT
#     # ==========================================
#     print("\n" + "="*80)
#     print("📋 FINAL THESIS MODEL REPORT")
#     print("="*80)
    
#     print(f"\n🎯 MODEL PERFORMANCE:")
#     print(metrics_df.to_string(index=False, formatters={
#         'r2': lambda x: f'{x:.4f}',
#         'mae': lambda x: f'{x:.1f}',
#         'rmse': lambda x: f'{x:.1f}',
#         'mape': lambda x: f'{x:.1f}%',
#         'mean_actual': lambda x: f'{x:.1f} kg',
#         'mean_predicted': lambda x: f'{x:.1f} kg'
#     }))
    
#     print(f"\n🌧️ HUMIDITY ANALYSIS:")
#     print(f"  Humidity explains {study.best_trial.user_attrs['humidity_importance']*100:.1f}% of predictions")
#     if len(humidity_imp) > 0:
#         top_humidity = humidity_imp.iloc[0]['feature']
#         print(f"  Most important humidity feature: {top_humidity}")
    
#     print(f"\n📊 FEATURE ANALYSIS:")
#     print(f"  Total features used: {X_train.shape[1]}")
#     print(f"  Humidity features: {len(humidity_features)}")
#     print(f"  Top 5 features overall:")
#     for i in range(min(5, len(importance_df))):
#         feat = importance_df.iloc[i]['feature']
#         imp = importance_df.iloc[i]['importance']
#         print(f"    {i+1}. {feat}: {imp:.4f}")
    
#     print(f"\n💡 PRACTICAL IMPLICATIONS FOR PLANTATION MANAGERS:")
#     print(f"  1. Model predicts yield with ±{metrics_df.loc[2, 'mae']:.0f} kg accuracy")
#     print(f"  2. {metrics_df.loc[2, 'mape']:.1f}% error rate")
#     print(f"  3. Model explains {metrics_df.loc[2, 'r2']*100:.1f}% of yield variability")
#     print(f"  4. Humidity management impacts {study.best_trial.user_attrs['humidity_importance']*100:.1f}% of yield")
    
#     print(f"\n📁 FILES SAVED FOR THESIS:")
#     print(f"  Results: {RESULTS_DIR}/")
#     print(f"  Models: {MODEL_DIR}/")
#     print(f"  Graphs: {GRAPHS_DIR}/")
    
#     print(f"\n✅ FINAL THESIS TUNING COMPLETE!")
#     print(f"   Expected R²: {-study.best_value:.3f} (log), {metrics_df.loc[2, 'r2']:.3f} (kg)")
#     print(f"   Ready for thesis writing and defense!")





"""
FINAL THESIS TUNING CODE - USING SUCCESSFUL DATA
=================================================
Fixed version that uses your proven successful data (R² = 0.792)
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import optuna
import os
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error, mean_absolute_percentage_error
import warnings
warnings.filterwarnings('ignore')

# ==========================================
# 1. CONFIGURATION - USE SUCCESSFUL DATA
# ==========================================
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Thesis_Processed_Final")  # USE YOUR SUCCESSFUL DATA!
RESULTS_DIR = os.path.join(PROJECT_ROOT, "Final_Thesis_Results")
GRAPHS_DIR = os.path.join(PROJECT_ROOT, "Final_Thesis_Graphs")
MODEL_DIR = os.path.join(PROJECT_ROOT, "Final_Thesis_Models")

for folder in [RESULTS_DIR, GRAPHS_DIR, MODEL_DIR]:
    os.makedirs(folder, exist_ok=True)

# ==========================================
# 2. LOAD PROVEN SUCCESSFUL DATA
# ==========================================
print("="*80)
print("TEA YIELD PREDICTION - FINAL THESIS TUNING")
print("="*80)
print("\nUsing your proven successful data (R² = 0.792)")
print("34 comprehensive features including advanced humidity metrics")

# Load successful data
X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
X_val = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"))
X_test = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"))

y_train_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train.csv")).iloc[:, 0]
y_val_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val.csv")).iloc[:, 0]
y_test_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test.csv")).iloc[:, 0]

print(f"\n[INFO] Data loaded successfully!")
print(f"  Training samples: {len(X_train):,}")
print(f"  Validation samples: {len(X_val):,}")
print(f"  Test samples: {len(X_test):,}")
print(f"  Features: {X_train.shape[1]}")
print(f"  Target: Log Efficiency (kg/worker)")
print(f"  Log efficiency - Mean: {y_train_log.mean():.3f}, Std: {y_train_log.std():.3f}")

# Convert to kg for practical interpretation
y_train_kg = np.expm1(y_train_log)
y_val_kg = np.expm1(y_val_log)
y_test_kg = np.expm1(y_test_log)

print(f"  Yield (kg) - Mean: {y_train_kg.mean():.1f}, Range: {y_train_kg.min():.1f}-{y_train_kg.max():.1f}")

# Analyze humidity features
humidity_features = [col for col in X_train.columns if 'humid' in col.lower()]
print(f"\n[INFO] Humidity analysis:")
print(f"  Total humidity features: {len(humidity_features)}")
print(f"  Key humidity features:")
for i, feat in enumerate(humidity_features[:5]):
    print(f"    {i+1}. {feat}")

# ==========================================
# 3. OPTIMIZATION OBJECTIVE
# ==========================================
def objective(trial):
    """Objective function for final thesis tuning."""
    
    # Optimized parameters based on your success
    params = {
        'booster': 'gbtree',
        'n_estimators': trial.suggest_int('n_estimators', 100, 300),
        'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.1, log=True),
        'max_depth': trial.suggest_int('max_depth', 3, 5),
        'subsample': trial.suggest_float('subsample', 0.7, 0.95),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.7, 0.95),
        'colsample_bylevel': trial.suggest_float('colsample_bylevel', 0.7, 0.9),
        'gamma': trial.suggest_float('gamma', 0, 1.0),
        'min_child_weight': trial.suggest_int('min_child_weight', 1, 5),
        'reg_alpha': trial.suggest_float('reg_alpha', 0.001, 1.0, log=True),
        'reg_lambda': trial.suggest_float('reg_lambda', 0.5, 2.0),
        'n_jobs': -1,
        'random_state': 42,
        'objective': 'reg:squarederror',
    }

    # Time series cross-validation
    tscv = TimeSeriesSplit(n_splits=3)
    cv_scores = {
        'r2_log': [],
        'mae_log': [],
        'r2_kg': [],
        'mae_kg': [],
        'mape_kg': []
    }
    
    humidity_importances = []

    for fold, (train_idx, val_idx) in enumerate(tscv.split(X_train)):
        X_tr, X_vl = X_train.iloc[train_idx], X_train.iloc[val_idx]
        y_tr, y_vl = y_train_log.iloc[train_idx], y_train_log.iloc[val_idx]
        
        model = xgb.XGBRegressor(**params)
        model.fit(
            X_tr, y_tr,
            eval_set=[(X_vl, y_vl)],
            verbose=False,
            early_stopping_rounds=20
        )
        
        # Predictions in log space
        preds_log = model.predict(X_vl)
        
        # Log-space metrics
        cv_scores['r2_log'].append(r2_score(y_vl, preds_log))
        cv_scores['mae_log'].append(mean_absolute_error(y_vl, preds_log))
        
        # Convert to kg for practical metrics
        y_vl_kg = np.expm1(y_vl)
        preds_kg = np.expm1(preds_log)
        
        # Kg-space metrics
        cv_scores['r2_kg'].append(r2_score(y_vl_kg, preds_kg))
        cv_scores['mae_kg'].append(mean_absolute_error(y_vl_kg, preds_kg))
        
        # Calculate MAPE (avoid division by zero)
        valid_mask = y_vl_kg > 0
        if valid_mask.any():
            mape = np.mean(np.abs((y_vl_kg[valid_mask] - preds_kg[valid_mask]) / y_vl_kg[valid_mask])) * 100
        else:
            mape = 0
        cv_scores['mape_kg'].append(mape)
        
        # Humidity importance
        humidity_idx = [i for i, col in enumerate(X_train.columns) 
                       if 'humid' in col.lower()]
        if humidity_idx:
            total_imp = model.feature_importances_.sum()
            humidity_imp = model.feature_importances_[humidity_idx].sum()
            humidity_importances.append(humidity_imp / total_imp if total_imp > 0 else 0)
    
    # Calculate averages
    mean_r2_log = np.mean(cv_scores['r2_log'])
    mean_r2_kg = np.mean(cv_scores['r2_kg'])
    mean_mae_kg = np.mean(cv_scores['mae_kg'])
    mean_mape_kg = np.mean(cv_scores['mape_kg'])
    mean_humidity_imp = np.mean(humidity_importances) if humidity_importances else 0
    
    # Store metrics
    trial.set_user_attr("r2_log", mean_r2_log)
    trial.set_user_attr("r2_kg", mean_r2_kg)
    trial.set_user_attr("mae_kg", mean_mae_kg)
    trial.set_user_attr("mape_kg", mean_mape_kg)
    trial.set_user_attr("humidity_importance", mean_humidity_imp)
    
    # Progress display
    print(f"Trial {trial.number:03d} | R²(log): {mean_r2_log:.4f} | R²(kg): {mean_r2_kg:.4f} | "
          f"MAE: {mean_mae_kg:.1f} kg | Humidity: {mean_humidity_imp:.3f}")
    
    # Primary objective: maximize R² in log space
    return -mean_r2_log  # Negative because Optuna minimizes

# ==========================================
# 4. OPTIMIZATION WITH SMART STARTING POINTS
# ==========================================
if __name__ == "__main__":
    print("\n" + "="*80)
    print("🚀 STARTING FINAL THESIS OPTIMIZATION")
    print("="*80)
    
    # Create study
    study = optuna.create_study(
        direction="minimize",
        study_name="final_thesis_tuning",
        sampler=optuna.samplers.TPESampler(
            n_startup_trials=15,
            consider_prior=True,
            prior_weight=1.5,
            seed=42
        ),
        pruner=optuna.pruners.MedianPruner(
            n_startup_trials=5,
            n_warmup_steps=3
        )
    )

    # Smart starting points based on your success
    print("\n[INFO] Starting with proven parameters...")
    
    study.enqueue_trial({
        'n_estimators': 200,
        'learning_rate': 0.05,
        'max_depth': 4,
        'subsample': 0.8,
        'colsample_bytree': 0.8,
        'colsample_bylevel': 0.8,
        'gamma': 0.1,
        'min_child_weight': 3,
        'reg_alpha': 0.1,
        'reg_lambda': 1.0
    })
    
    study.enqueue_trial({
        'n_estimators': 150,
        'learning_rate': 0.1,
        'max_depth': 3,
        'subsample': 0.9,
        'colsample_bytree': 0.9,
        'colsample_bylevel': 0.8,
        'gamma': 0.2,
        'min_child_weight': 4,
        'reg_alpha': 0.05,
        'reg_lambda': 1.5
    })

    # Progress callback
    def print_best_trial_info(study, trial):
        if trial.number % 10 == 0 or trial.number == 1:
            print(f"\n📊 Progress Update (Trial {trial.number}):")
            print(f"   Best R²(log): {-study.best_value:.4f}")
            print(f"   Best R²(kg): {study.best_trial.user_attrs['r2_kg']:.4f}")
            print(f"   Best MAE: {study.best_trial.user_attrs['mae_kg']:.1f} kg")
            print(f"   Humidity Importance: {study.best_trial.user_attrs['humidity_importance']:.3f}")

    # Run optimization
    print("\n[INFO] Running optimization...")
    study.optimize(
        objective, 
        n_trials=30,  # Fewer trials since we're starting close to optimum
        callbacks=[print_best_trial_info],
        show_progress_bar=True
    )

    # ==========================================
    # 5. TRAIN FINAL MODEL
    # ==========================================
    print("\n" + "="*80)
    print("🎯 TRAINING FINAL THESIS MODEL")
    print("="*80)
    
    print(f"\n[INFO] Best trial found:")
    print(f"  R²(log): {-study.best_value:.4f}")
    print(f"  R²(kg): {study.best_trial.user_attrs['r2_kg']:.4f}")
    print(f"  MAE: {study.best_trial.user_attrs['mae_kg']:.1f} kg")
    print(f"  MAPE: {study.best_trial.user_attrs['mape_kg']:.1f}%")
    print(f"  Humidity Importance: {study.best_trial.user_attrs['humidity_importance']:.3f}")
    
    print("\n[INFO] Best parameters:")
    for key, value in study.best_params.items():
        print(f"  {key}: {value}")
    
    # Train final model
    print("\n[INFO] Training final model...")
    
    final_params = study.best_params.copy()
    final_params['n_jobs'] = -1
    final_params['random_state'] = 42
    final_params['objective'] = 'reg:squarederror'
    
    final_model = xgb.XGBRegressor(**final_params)
    final_model.fit(
        X_train, y_train_log,
        eval_set=[(X_val, y_val_log)],
        verbose=True,
        early_stopping_rounds=20
    )
    
    # Predictions
    train_preds_log = final_model.predict(X_train)
    val_preds_log = final_model.predict(X_val)
    test_preds_log = final_model.predict(X_test)
    
    # Convert to kg for practical interpretation
    train_preds_kg = np.expm1(train_preds_log)
    val_preds_kg = np.expm1(val_preds_log)
    test_preds_kg = np.expm1(test_preds_log)
    
    train_actual_kg = np.expm1(y_train_log)
    val_actual_kg = np.expm1(y_val_log)
    test_actual_kg = np.expm1(y_test_log)
    
    # Calculate comprehensive metrics
    def calculate_metrics(y_true, y_pred, name):
        valid_mask = y_true > 0
        if valid_mask.any():
            y_true_valid = y_true[valid_mask]
            y_pred_valid = y_pred[valid_mask]
            mape = np.mean(np.abs((y_true_valid - y_pred_valid) / y_true_valid)) * 100
        else:
            mape = 0
            
        return {
            'dataset': name,
            'r2': r2_score(y_true, y_pred),
            'mae': mean_absolute_error(y_true, y_pred),
            'rmse': np.sqrt(mean_squared_error(y_true, y_pred)),
            'mape': mape,
            'mean_actual': y_true.mean(),
            'mean_predicted': y_pred.mean(),
            'std_actual': y_true.std(),
            'std_predicted': y_pred.std()
        }
    
    metrics = [
        calculate_metrics(train_actual_kg, train_preds_kg, 'Training'),
        calculate_metrics(val_actual_kg, val_preds_kg, 'Validation'),
        calculate_metrics(test_actual_kg, test_preds_kg, 'Test')
    ]
    
    metrics_df = pd.DataFrame(metrics)
    
    # ==========================================
    # 6. SAVE RESULTS
    # ==========================================
    print("\n" + "="*80)
    print("💾 SAVING FINAL RESULTS")
    print("="*80)
    
    # Save study
    joblib.dump(study, os.path.join(RESULTS_DIR, "final_study.pkl"))
    
    # Save model
    joblib.dump(final_model, os.path.join(MODEL_DIR, "final_model.pkl"))
    
    # Save predictions - simple version without padding
    predictions_data = {}
    
    # Training data (4376 samples)
    predictions_data['train_actual_kg'] = train_actual_kg.values
    predictions_data['train_predicted_kg'] = train_preds_kg
    predictions_data['train_actual_log'] = y_train_log.values
    predictions_data['train_predicted_log'] = train_preds_log
    
    # Validation data (544 samples)
    predictions_data['val_actual_kg'] = val_actual_kg.values
    predictions_data['val_predicted_kg'] = val_preds_kg
    predictions_data['val_actual_log'] = y_val_log.values
    predictions_data['val_predicted_log'] = val_preds_log
    
    # Test data (548 samples)
    predictions_data['test_actual_kg'] = test_actual_kg.values
    predictions_data['test_predicted_kg'] = test_preds_kg
    predictions_data['test_actual_log'] = y_test_log.values
    predictions_data['test_predicted_log'] = test_preds_log
    
    # Create separate DataFrames for each dataset
    train_df = pd.DataFrame({
        'actual_kg': predictions_data['train_actual_kg'],
        'predicted_kg': predictions_data['train_predicted_kg'],
        'actual_log': predictions_data['train_actual_log'],
        'predicted_log': predictions_data['train_predicted_log']
    })
    
    val_df = pd.DataFrame({
        'actual_kg': predictions_data['val_actual_kg'],
        'predicted_kg': predictions_data['val_predicted_kg'],
        'actual_log': predictions_data['val_actual_log'],
        'predicted_log': predictions_data['val_predicted_log']
    })
    
    test_df = pd.DataFrame({
        'actual_kg': predictions_data['test_actual_kg'],
        'predicted_kg': predictions_data['test_predicted_kg'],
        'actual_log': predictions_data['test_actual_log'],
        'predicted_log': predictions_data['test_predicted_log']
    })
    
    # Save to CSV
    train_df.to_csv(os.path.join(RESULTS_DIR, "train_predictions.csv"), index=False)
    val_df.to_csv(os.path.join(RESULTS_DIR, "val_predictions.csv"), index=False)
    test_df.to_csv(os.path.join(RESULTS_DIR, "test_predictions.csv"), index=False)
    
    # Save metrics
    metrics_df.to_csv(os.path.join(RESULTS_DIR, "final_metrics.csv"), index=False)
    
    # Save feature importance
    importance_df = pd.DataFrame({
        'feature': X_train.columns,
        'importance': final_model.feature_importances_
    }).sort_values('importance', ascending=False)
    importance_df.to_csv(os.path.join(RESULTS_DIR, "final_feature_importance.csv"), index=False)
    
    # ==========================================
    # 7. CREATE VISUALIZATIONS
    # ==========================================
    print("\n" + "="*80)
    print("📊 CREATING FINAL VISUALIZATIONS")
    print("="*80)
    
    # 1. Feature Importance
    plt.figure(figsize=(12, 8))
    top_features = importance_df.head(15)
    
    colors = []
    for f in top_features['feature']:
        f_lower = f.lower()
        if 'humid' in f_lower:
            colors.append('#3498db')  # Blue for humidity
        elif 'temp' in f_lower:
            colors.append('#e74c3c')  # Red for temperature
        elif 'rain' in f_lower:
            colors.append('#27ae60')  # Green for rainfall
        elif 'labor' in f_lower:
            colors.append('#f39c12')  # Orange for labor
        else:
            colors.append('#95a5a6')  # Gray for others
    
    plt.barh(range(len(top_features)), top_features['importance'], color=colors)
    plt.yticks(range(len(top_features)), top_features['feature'])
    plt.xlabel('Feature Importance', fontsize=12)
    plt.title('Top 15 Features for Tea Yield Prediction', fontsize=14, fontweight='bold')
    plt.gca().invert_yaxis()
    plt.grid(True, alpha=0.3, axis='x')
    plt.tight_layout()
    plt.savefig(os.path.join(GRAPHS_DIR, "final_feature_importance.png"), dpi=300, bbox_inches='tight')
    plt.close()
    
    # 2. Actual vs Predicted
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    datasets = [
        (train_actual_kg, train_preds_kg, 'Training', 'blue', metrics_df.loc[0, 'r2'], metrics_df.loc[0, 'mae']),
        (val_actual_kg, val_preds_kg, 'Validation', 'green', metrics_df.loc[1, 'r2'], metrics_df.loc[1, 'mae']),
        (test_actual_kg, test_preds_kg, 'Test', 'red', metrics_df.loc[2, 'r2'], metrics_df.loc[2, 'mae'])
    ]
    
    for idx, (actual, pred, title, color, r2, mae) in enumerate(datasets):
        axes[idx].scatter(actual, pred, alpha=0.5, s=10, color=color)
        axes[idx].plot([actual.min(), actual.max()], 
                      [actual.min(), actual.max()], 'k--', alpha=0.8, linewidth=1)
        axes[idx].set_xlabel('Actual Yield (kg)', fontsize=11)
        axes[idx].set_ylabel('Predicted Yield (kg)', fontsize=11)
        axes[idx].set_title(f'{title} Set\nR² = {r2:.3f}, MAE = {mae:.1f} kg', fontsize=12)
        axes[idx].grid(True, alpha=0.3)
    
    plt.suptitle('Tea Yield Prediction Performance - Final Thesis Model', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(os.path.join(GRAPHS_DIR, "final_prediction_performance.png"), dpi=300, bbox_inches='tight')
    plt.close()
    
    # 3. Humidity Analysis
    humidity_imp = importance_df[importance_df['feature'].str.contains('humid', case=False)]
    if len(humidity_imp) > 0:
        plt.figure(figsize=(10, 6))
        humidity_imp = humidity_imp.sort_values('importance', ascending=True).tail(10)
        
        plt.barh(range(len(humidity_imp)), humidity_imp['importance'], color='#3498db')
        plt.yticks(range(len(humidity_imp)), humidity_imp['feature'])
        plt.xlabel('Feature Importance', fontsize=12)
        plt.title(f'Humidity Features Contribution\nTotal Humidity Importance: {study.best_trial.user_attrs["humidity_importance"]*100:.1f}%', 
                 fontsize=12, fontweight='bold')
        plt.grid(True, alpha=0.3, axis='x')
        plt.tight_layout()
        plt.savefig(os.path.join(GRAPHS_DIR, "final_humidity_contribution.png"), dpi=300, bbox_inches='tight')
        plt.close()
    
    # 4. Error Distribution
    plt.figure(figsize=(10, 6))
    errors = test_actual_kg - test_preds_kg
    plt.hist(errors, bins=50, alpha=0.7, color='purple', edgecolor='black')
    plt.axvline(x=0, color='red', linestyle='--', linewidth=2, label='Zero Error')
    plt.xlabel('Prediction Error (kg)', fontsize=12)
    plt.ylabel('Frequency', fontsize=12)
    plt.title(f'Test Set Error Distribution\nMean Error = {errors.mean():.1f} kg, Std = {errors.std():.1f} kg', fontsize=12, fontweight='bold')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(GRAPHS_DIR, "final_error_distribution.png"), dpi=300, bbox_inches='tight')
    plt.close()
    
    # ==========================================
    # 8. FINAL THESIS REPORT
    # ==========================================
    print("\n" + "="*80)
    print("📋 FINAL THESIS MODEL REPORT")
    print("="*80)
    
    print(f"\n🎯 MODEL PERFORMANCE:")
    print(metrics_df.to_string(index=False, formatters={
        'r2': lambda x: f'{x:.4f}',
        'mae': lambda x: f'{x:.1f}',
        'rmse': lambda x: f'{x:.1f}',
        'mape': lambda x: f'{x:.1f}%',
        'mean_actual': lambda x: f'{x:.1f}',
        'mean_predicted': lambda x: f'{x:.1f}'
    }))
    
    print(f"\n🌧️ HUMIDITY ANALYSIS:")
    print(f"  Humidity explains {study.best_trial.user_attrs['humidity_importance']*100:.1f}% of predictions")
    print(f"  Number of humidity features: {len(humidity_features)}")
    if len(humidity_imp) > 0:
        top_humidity = humidity_imp.iloc[-1]['feature']  # Most important (sorted ascending)
        print(f"  Most important humidity feature: {top_humidity}")
    
    print(f"\n📊 FEATURE ANALYSIS:")
    print(f"  Total features used: {X_train.shape[1]}")
    print(f"  Top 5 features overall:")
    for i in range(min(5, len(importance_df))):
        feat = importance_df.iloc[i]['feature']
        imp = importance_df.iloc[i]['importance']
        print(f"    {i+1}. {feat}: {imp:.4f}")
    
    print(f"\n💡 PRACTICAL IMPLICATIONS FOR PLANTATION MANAGERS:")
    print(f"  1. Model predicts yield with ±{metrics_df.loc[2, 'mae']:.0f} kg accuracy")
    print(f"  2. {metrics_df.loc[2, 'mape']:.1f}% error rate")
    print(f"  3. Model explains {metrics_df.loc[2, 'r2']*100:.1f}% of yield variability")
    print(f"  4. Humidity management impacts {study.best_trial.user_attrs['humidity_importance']*100:.1f}% of yield")
    
    print(f"\n📁 FILES SAVED FOR THESIS:")
    print(f"  Results: {RESULTS_DIR}/")
    print(f"  Models: {MODEL_DIR}/")
    print(f"  Graphs: {GRAPHS_DIR}/")
    
    # # Save detailed report
    # report = f"""
    # TEA YIELD PREDICTION SYSTEM - FINAL THESIS MODEL REPORT
    # ========================================================
    
    # Based on: Your proven successful approach (R² = 0.792 for log efficiency prediction)
    # Features: 34 comprehensive features including 15 humidity metrics
    
    # MODEL PERFORMANCE:
    # -----------------
    # Dataset           R²      MAE (kg)   RMSE (kg)   MAPE (%)   Mean Yield (kg)
    # {metrics_df.to_string(index=False, formatters={{
    #     'r2': lambda x: f'{x:.4f}',
    #     'mae': lambda x: f'{x:.1f}',
    #     'rmse': lambda x: f'{x:.1f}',
    #     'mape': lambda x: f'{x:.1f}',
    #     'mean_actual': lambda x: f'{x:.1f}'
    # }}).replace('\n', '\n    ')}
    
    # HUMIDITY IMPACT:
    # ---------------
    # Total Humidity Importance: {study.best_trial.user_attrs['humidity_importance']*100:.1f}%
    # Humidity Features Used: {len(humidity_features)}
    
    # TOP 5 FEATURES:
    # --------------
    # {importance_df.head(5).to_string(index=False, formatters={{
    #     'importance': lambda x: f'{x:.4f}'
    # }}).replace('\n', '\n    ')}
    
    # MODEL CONFIGURATION:
    # -------------------
    # Features: {X_train.shape[1]}
    # Training Samples: {len(X_train):,}
    # Validation Samples: {len(X_val):,}
    # Test Samples: {len(X_test):,}
    
    # BEST HYPERPARAMETERS:
    # --------------------
    # {chr(10).join(f'    {k}: {v}' for k, v in study.best_params.items())}
    
    # PRACTICAL APPLICATIONS:
    # ----------------------
    # 1. Yield Prediction Accuracy: ±{metrics_df.loc[2, 'mae']:.0f} kg
    # 2. Error Rate: {metrics_df.loc[2, 'mape']:.1f}%
    # 3. Humidity Impact: {study.best_trial.user_attrs['humidity_importance']*100:.1f}% of yield variability
    # 4. Applications: Labor planning, harvest scheduling, resource allocation
    
    # Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}
    # """

        # Format the metrics string separately
    metrics_formatted = metrics_df.to_string(index=False, formatters={
        'r2': lambda x: f'{x:.4f}',
        'mae': lambda x: f'{x:.1f}',
        'rmse': lambda x: f'{x:.1f}',
        'mape': lambda x: f'{x:.1f}',
        'mean_actual': lambda x: f'{x:.1f}'
    }).replace('\n', '\n    ')
    
    importance_formatted = importance_df.head(5).to_string(index=False, formatters={
        'importance': lambda x: f'{x:.4f}'
    }).replace('\n', '\n    ')
    
    report = f"""
    TEA YIELD PREDICTION SYSTEM - FINAL THESIS MODEL REPORT
    ========================================================
    
    Based on: Your proven successful approach (R² = 0.792 for log efficiency prediction)
    Features: 34 comprehensive features including 15 humidity metrics
    
    MODEL PERFORMANCE:
    -----------------
    Dataset           R²      MAE (kg)   RMSE (kg)   MAPE (%)   Mean Yield (kg)
    {metrics_formatted}
    
    HUMIDITY IMPACT:
    ---------------
    Total Humidity Importance: {study.best_trial.user_attrs['humidity_importance']*100:.1f}%
    Humidity Features Used: {len(humidity_features)}
    
    TOP 5 FEATURES:
    --------------
    {importance_formatted}
    
    MODEL CONFIGURATION:
    -------------------
    Features: {X_train.shape[1]}
    Training Samples: {len(X_train):,}
    Validation Samples: {len(X_val):,}
    Test Samples: {len(X_test):,}
    
    BEST HYPERPARAMETERS:
    --------------------
    {chr(10).join(f'    {k}: {v}' for k, v in study.best_params.items())}
    
    PRACTICAL APPLICATIONS:
    ----------------------
    1. Yield Prediction Accuracy: ±{metrics_df.loc[2, 'mae']:.0f} kg
    2. Error Rate: {metrics_df.loc[2, 'mape']:.1f}%
    3. Humidity Impact: {study.best_trial.user_attrs['humidity_importance']*100:.1f}% of yield variability
    4. Applications: Labor planning, harvest scheduling, resource allocation
    
    Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}
    """
    
    with open(os.path.join(RESULTS_DIR, "final_thesis_report.txt"), 'w') as f:
        f.write(report)
    
    print(f"\n✅ FINAL THESIS TUNING COMPLETE!")
    print(f"   Expected R²: {-study.best_value:.3f} (log), {metrics_df.loc[2, 'r2']:.3f} (kg)")
    print(f"   Ready for thesis writing and defense!")