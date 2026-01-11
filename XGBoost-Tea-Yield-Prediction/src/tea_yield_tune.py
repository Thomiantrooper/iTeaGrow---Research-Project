"""
XGBOOST TUNING - EXACT CATBOOST MATCH
======================================
Tunes XGBoost on EXACT same data as CatBoost
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import optuna
from sklearn.metrics import r2_score, mean_absolute_error
import os
import joblib
import warnings
warnings.filterwarnings('ignore')

print("="*80)
print("XGBOOST HYPERPARAMETER TUNING - EXACT CATBOOST MATCH")
print("="*80)
print("Tunes XGBoost on IDENTICAL preprocessing as CatBoost")
print("="*80)

# ==========================================
# LOAD PROCESSED DATA (EXACT CATBOOST FORMAT)
# ==========================================
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Preprocessed_XGBoost_EXACT_CATBOOST")
RESULTS_DIR = os.path.join(PROJECT_ROOT, "Tuning_Results_XGBoost")
os.makedirs(RESULTS_DIR, exist_ok=True)

print(f"Loading data from: {PROCESSED_FOLDER}")

# Load features (44 features - EXACTLY like CatBoost)
X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
X_val = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"))
X_test = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"))

# Load LOG EFFICIENCY targets (EXACTLY like CatBoost)
y_train_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv")).iloc[:, 0]
y_val_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val_log.csv")).iloc[:, 0]
y_test_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test_log.csv")).iloc[:, 0]

# Load KG targets for evaluation (EXACTLY like CatBoost)
y_train_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"))
y_val_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"))
y_test_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"))

print(f"\n✅ DATA LOADED (EXACT CATBOOST REPLICA):")
print(f"Training samples: {X_train.shape[0]:,}")
print(f"Features: {X_train.shape[1]} (SAME as CatBoost)")
print(f"Target (log efficiency) mean: {y_train_log.mean():.4f}")

# ==========================================
# OPTUNA OPTIMIZATION FUNCTION (FOR LOG EFFICIENCY)
# ==========================================
def objective(trial):
    """Optimize XGBoost for log_efficiency prediction (EXACTLY like CatBoost)."""
    
    params = {
        'n_estimators': trial.suggest_int('n_estimators', 100, 1000),
        'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
        'max_depth': trial.suggest_int('max_depth', 3, 10),
        'subsample': trial.suggest_float('subsample', 0.6, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
        'colsample_bylevel': trial.suggest_float('colsample_bylevel', 0.6, 1.0),
        'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
        'gamma': trial.suggest_float('gamma', 0, 5),
        'reg_alpha': trial.suggest_float('reg_alpha', 1e-8, 10.0, log=True),
        'reg_lambda': trial.suggest_float('reg_lambda', 1e-8, 10.0, log=True),
        'random_state': 42,
        'n_jobs': -1,
        'objective': 'reg:squarederror',
    }

    # Train model on LOG EFFICIENCY (like CatBoost)
    model = xgb.XGBRegressor(**params)
    
    model.fit(
        X_train, y_train_log,
        eval_set=[(X_val, y_val_log)],
        early_stopping_rounds=50,
        verbose=False
    )
    
    # Predict log efficiency
    val_pred_log = model.predict(X_val)
    
    # Convert to KG for evaluation (EXACTLY like CatBoost)
    val_pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(val_pred_log))
    val_actual_kg = y_val_kg['Target_Usable_Yield_Kg'].values
    
    # Calculate R² in KG space (what matters - like CatBoost)
    r2_kg = r2_score(val_actual_kg, val_pred_kg)
    
    # Store metrics
    trial.set_user_attr("r2_log", r2_score(y_val_log, val_pred_log))
    trial.set_user_attr("r2_kg", r2_kg)
    trial.set_user_attr("mae_kg", mean_absolute_error(val_actual_kg, val_pred_kg))
    
    # Progress display
    if trial.number % 10 == 0:
        print(f"Trial {trial.number:03d} | Val R² (kg): {r2_kg:.4f}")
    
    # Return NEGATIVE R² because Optuna minimizes
    return -r2_kg

# ==========================================
# RUN OPTIMIZATION
# ==========================================
print("\n" + "="*80)
print("STARTING HYPERPARAMETER TUNING")
print("="*80)
print("Target: Match CatBoost (78% R²)")
print("Training on log_efficiency, evaluating on KG (like CatBoost)")
print("Running 50 trials...")

study = optuna.create_study(
    direction="minimize",
    study_name="xgboost_tea_yield_tuning_exact",
    sampler=optuna.samplers.TPESampler(seed=42)
)

# Add smart starting points based on CatBoost
starting_points = [
    {
        'n_estimators': 800,
        'learning_rate': 0.025,
        'max_depth': 7,
        'subsample': 0.85,
        'colsample_bytree': 0.9,
        'colsample_bylevel': 0.8,
        'gamma': 0.1,
        'min_child_weight': 3,
        'reg_alpha': 0.05,
        'reg_lambda': 0.8,
    },
    {
        'n_estimators': 500,
        'learning_rate': 0.05,
        'max_depth': 6,
        'subsample': 0.8,
        'colsample_bytree': 0.8,
        'colsample_bylevel': 0.8,
        'gamma': 0,
        'min_child_weight': 1,
        'reg_alpha': 0.1,
        'reg_lambda': 1.0,
    }
]

for params in starting_points:
    study.enqueue_trial(params)

study.optimize(objective, n_trials=50, show_progress_bar=True)

# ==========================================
# ANALYZE RESULTS
# ==========================================
print("\n" + "="*80)
print("TUNING RESULTS")
print("="*80)

best_trial = study.best_trial
best_r2_kg = -best_trial.value  # Convert back to positive

print(f"Best trial: #{best_trial.number}")
print(f"Best R² (KG): {best_r2_kg:.4f} ({best_r2_kg*100:.1f}%)")
print(f"Corresponding R² (log): {best_trial.user_attrs['r2_log']:.4f}")
print(f"Best MAE (KG): {best_trial.user_attrs['mae_kg']:.1f} kg")

print(f"\n🎯 Best parameters:")
for key, value in best_trial.params.items():
    print(f"  {key}: {value}")

# Analyze all trials
trials_df = study.trials_dataframe()
trials_df['r2_kg'] = -trials_df['value']  # Convert back to positive R²

print(f"\n📊 TRIAL ANALYSIS:")
print(f"Total trials: {len(trials_df)}")
print(f"Best R² achieved: {trials_df['r2_kg'].max():.4f}")
print(f"Average R²: {trials_df['r2_kg'].mean():.4f}")
print(f"Std R²: {trials_df['r2_kg'].std():.4f}")

# Find trials with R² > 0.75
good_trials = trials_df[trials_df['r2_kg'] > 0.75]
print(f"\n🏆 Trials with R² > 0.75: {len(good_trials)}")

if len(good_trials) > 0:
    print(f"Best among good trials: {good_trials['r2_kg'].max():.4f}")

# ==========================================
# TRAIN FINAL MODEL WITH BEST PARAMETERS
# ==========================================
print(f"\n" + "="*80)
print("TRAINING FINAL MODEL")
print("="*80)

best_params = best_trial.params.copy()
best_params.update({
    'random_state': 42,
    'n_jobs': -1,
    'objective': 'reg:squarederror',
})

print("Training final model with best parameters...")
final_model = xgb.XGBRegressor(**best_params)

# Combine train + val for final training (like CatBoost)
X_train_full = pd.concat([X_train, X_val], axis=0)
y_train_log_full = pd.concat([y_train_log, y_val_log], axis=0)

final_model.fit(
    X_train_full, y_train_log_full,
    verbose=100
)

print("✓ Final model trained")

# ==========================================
# FINAL EVALUATION (EXACTLY LIKE CATBOOST)
# ==========================================
print(f"\n" + "="*80)
print("FINAL EVALUATION")
print("="*80)

# Predict on test set (log efficiency)
test_pred_log = final_model.predict(X_test)

# Convert to KG (EXACTLY like CatBoost)
test_pred_kg = y_test_kg['Labor_Safe'] * (np.expm1(test_pred_log))
test_actual_kg = y_test_kg['Target_Usable_Yield_Kg'].values

# Calculate metrics
test_r2_log = r2_score(y_test_log, test_pred_log)
test_r2_kg = r2_score(test_actual_kg, test_pred_kg)
test_mae = mean_absolute_error(test_actual_kg, test_pred_kg)
test_rmse = np.sqrt(np.mean((test_actual_kg - test_pred_kg) ** 2))

print(f"\n📊 TEST SET PERFORMANCE (EXACTLY LIKE CATBOOST):")
print(f"  R² (log space): {test_r2_log:.4f} ({test_r2_log*100:.1f}%)")
print(f"  R² (KG space):  {test_r2_kg:.4f} ({test_r2_kg*100:.1f}%)")
print(f"  MAE:           {test_mae:.1f} kg")
print(f"  RMSE:          {test_rmse:.1f} kg")
print(f"  Mean actual:   {test_actual_kg.mean():.1f} kg")
print(f"  Mean predicted: {test_pred_kg.mean():.1f} kg")
print(f"  Error %:       {(test_mae/test_actual_kg.mean()*100):.1f}%")

# ==========================================
# COMPARE WITH CATBOOST
# ==========================================
print(f"\n" + "="*80)
print("COMPARISON WITH CATBOOST")
print("="*80)

catboost_r2 = 0.781
print(f"\nXGBoost (exact same preprocessing):")
print(f"  R²: {test_r2_kg:.4f} ({test_r2_kg*100:.1f}%)")
print(f"  MAE: {test_mae:.1f} kg")

print(f"\nCatBoost (your model):")
print(f"  R²: {catboost_r2:.4f} ({catboost_r2*100:.1f}%)")
print(f"  MAE: ~127.6 kg")

print(f"\n📈 COMPARISON:")
print(f"  R² difference: {abs(test_r2_kg - catboost_r2):.4f}")
print(f"  % difference: {abs(test_r2_kg - catboost_r2)/catboost_r2*100:.1f}%")

if test_r2_kg >= catboost_r2:
    print(f"\n🎉 EXCELLENT! XGBoost MATCHES or BEATS CatBoost!")
elif test_r2_kg >= 0.77:
    print(f"\n✅ GREAT! XGBoost very close to CatBoost")
elif test_r2_kg >= 0.75:
    print(f"\n👍 GOOD! XGBoost achieves 75%+ R²")
else:
    print(f"\n⚠️  Needs improvement")

# ==========================================
# FEATURE IMPORTANCE
# ==========================================
print(f"\n" + "="*80)
print("FEATURE IMPORTANCE ANALYSIS")
print("="*80)

importance = pd.DataFrame({
    'Feature': X_train.columns,
    'Importance': final_model.feature_importances_
}).sort_values('Importance', ascending=False)

print(f"\n🏆 TOP 10 MOST IMPORTANT FEATURES:")
top_10 = importance.head(10)
for i, row in top_10.iterrows():
    print(f"  {i+1:2d}. {row['Feature']:<35} {row['Importance']:.4f}")

# ==========================================
# SAVE RESULTS
# ==========================================
print(f"\n" + "="*80)
print("SAVING RESULTS")
print("="*80)

# Save study
joblib.dump(study, os.path.join(RESULTS_DIR, "optuna_study.pkl"))

# Save best parameters
best_params_df = pd.DataFrame([best_trial.params])
best_params_df.to_csv(os.path.join(RESULTS_DIR, "best_params.csv"), index=False)

# Save all trials
trials_df.to_csv(os.path.join(RESULTS_DIR, "all_trials.csv"), index=False)

# Save final model
joblib.dump(final_model, os.path.join(RESULTS_DIR, "xgboost_tuned_model.pkl"))

# Save predictions
predictions_df = pd.DataFrame({
    'Actual_kg': test_actual_kg,
    'Predicted_kg': test_pred_kg,
    'Error_kg': test_actual_kg - test_pred_kg,
    'Actual_log': y_test_log.values,
    'Predicted_log': test_pred_log,
    'Labor_Count': y_test_kg['Labor_Safe'].values
})
predictions_df.to_csv(os.path.join(RESULTS_DIR, "test_predictions.csv"), index=False)

# Save feature importance
importance.to_csv(os.path.join(RESULTS_DIR, "feature_importance.csv"), index=False)

# Save summary
summary = f"""
XGBOOST TUNING SUMMARY - EXACT CATBOOST MATCH
===================================================
Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}

PREPROCESSING:
- Features: {X_train.shape[1]} (identical to CatBoost)
- Labor scaling: NOT scaled (identical to CatBoost)
- Target: log_efficiency (identical to CatBoost)

OPTIMIZATION RESULTS:
- Best trial: #{best_trial.number}
- Best R² (KG): {best_r2_kg:.4f}
- Trials run: {len(trials_df)}

FINAL MODEL PERFORMANCE:
- Test R² (KG): {test_r2_kg:.4f} ({test_r2_kg*100:.1f}%)
- Test MAE: {test_mae:.1f} kg
- Test RMSE: {test_rmse:.1f} kg
- Error percentage: {test_mae/test_actual_kg.mean()*100:.1f}%

COMPARISON WITH CATBOOST:
- CatBoost R²: {catboost_r2:.4f}
- XGBoost R²: {test_r2_kg:.4f}
- Difference: {abs(test_r2_kg - catboost_r2):.4f}
- Status: {'✅ MATCHES/BEATS' if test_r2_kg >= catboost_r2 else '⚠️ BELOW'}

TOP 3 FEATURES:
1. {top_10.iloc[0]['Feature']}: {top_10.iloc[0]['Importance']:.4f}
2. {top_10.iloc[1]['Feature']}: {top_10.iloc[1]['Importance']:.4f}
3. {top_10.iloc[2]['Feature']}: {top_10.iloc[2]['Importance']:.4f}

CONCLUSION:
XGBoost {'successfully matches' if test_r2_kg >= catboost_r2 else 'does not fully match'} 
CatBoost performance with identical preprocessing.
"""

# Fix the save summary section (around line 368):
with open(os.path.join(RESULTS_DIR, "tuning_summary.txt"), 'w', encoding='utf-8') as f:
    f.write(summary)

print(summary)

print(f"\n" + "="*80)
print("TUNING COMPLETE!")
print("="*80)

print(f"\n📁 All results saved to: {RESULTS_DIR}")
print(f"📊 Final model: xgboost_tuned_model.pkl")
print(f"📈 Best parameters: best_params.csv")
print(f"📋 Summary: tuning_summary.txt")

print(f"\n🎯 RECOMMENDATION FOR THESIS:")
if test_r2_kg >= 0.78:
    print("✅ Use XGBoost with these parameters - matches CatBoost!")
elif test_r2_kg >= 0.75:
    print("⚠️  XGBoost is close but CatBoost slightly better")
else:
    print("❌ Use CatBoost as primary model")

print("\n" + "="*80)