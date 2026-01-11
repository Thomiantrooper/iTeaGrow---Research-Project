"""
CATBOOST TUNING 
============================================
"""

import pandas as pd
import numpy as np
import os
import optuna
from catboost import CatBoostRegressor
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
import json

# ==========================================
# CONFIG
# ==========================================
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction"
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Preprocessed_CatBoost_XGBoost_Complete")
RESULTS_FOLDER = os.path.join(PROJECT_ROOT, "Tuning_Results_XGBoost_Complete")
os.makedirs(RESULTS_FOLDER, exist_ok=True)

N_TRIALS = 40  # More trials for better optimization
RANDOM_SEED = 42

print("=" * 80)
print("CATBOOST TUNING - WITH ALL XGBOOST FEATURES")
print("=" * 80)
print(f"Using {N_TRIALS} trials to find optimal parameters")
print("=" * 80)

# ==========================================
# LOAD DATA
# ==========================================
print("\n Loading data...")

X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
X_val = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"))
X_test = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"))

y_train_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv")).iloc[:, 0]
y_val_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val_log.csv")).iloc[:, 0]
y_test_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test_log.csv")).iloc[:, 0]

y_train_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"))
y_val_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"))
y_test_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"))

print(f"   X_train shape: {X_train.shape}")
print(f"   Features: {X_train.shape[1]}")
print(f"   Target mean: {y_train_log.mean():.4f}")

# ==========================================
# QUICK TEST BEFORE OPTUNA
# ==========================================
print("\n Quick test: Can we reach >0.50 R² with default params?")
model_test = CatBoostRegressor(
    iterations=1000,
    learning_rate=0.05,
    depth=8,
    random_seed=RANDOM_SEED,
    verbose=False
)
model_test.fit(X_train, y_train_log)
pred_log = model_test.predict(X_val)
pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(pred_log))
quick_r2 = r2_score(y_val_kg['Target_Usable_Yield_Kg'], pred_kg)
print(f"   Default CatBoost R²: {quick_r2:.4f}")

if quick_r2 > 0.50:
    print(f"    Good baseline! Proceeding with Optuna...")
else:
    print(f"    Low baseline. Checking feature importance...")
    importance = model_test.feature_importances_
    top_features = pd.DataFrame({
        'feature': X_train.columns,
        'importance': importance
    }).sort_values('importance', ascending=False).head(10)
    print(f"\n   Top 10 features:")
    for idx, row in top_features.iterrows():
        print(f"      {row['feature']}: {row['importance']:.4f}")

# ==========================================
# OPTUNA OPTIMIZATION
# ==========================================
def objective(trial):
    params = {
        'iterations': trial.suggest_int('iterations', 1000, 3000),
        'learning_rate': trial.suggest_float('learning_rate', 0.005, 0.1, log=True),
        'depth': trial.suggest_int('depth', 6, 12),
        'l2_leaf_reg': trial.suggest_float('l2_leaf_reg', 1.0, 10.0),
        'random_strength': trial.suggest_float('random_strength', 0.5, 2.0),
        'bagging_temperature': trial.suggest_float('bagging_temperature', 0.0, 1.0),
        'bootstrap_type': 'MVS',
        'grow_policy': trial.suggest_categorical('grow_policy', ['SymmetricTree', 'Depthwise', 'Lossguide']),
        'eval_metric': 'R2',
        'random_seed': RANDOM_SEED,
        'verbose': False,
        'early_stopping_rounds': 100
    }
    
    model = CatBoostRegressor(**params)
    model.fit(
        X_train, y_train_log,
        eval_set=(X_val, y_val_log),
        verbose=False
    )
    
    # Predict and convert to KG
    pred_log = model.predict(X_val)
    pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(pred_log))
    actual_kg = y_val_kg['Target_Usable_Yield_Kg'].values
    
    # Calculate R² in KG space
    r2_kg = r2_score(actual_kg, pred_kg)
    
    # Store metrics
    trial.set_user_attr('mae_kg', mean_absolute_error(actual_kg, pred_kg))
    trial.set_user_attr('rmse_kg', np.sqrt(mean_squared_error(actual_kg, pred_kg)))
    
    return r2_kg

print(f"\nStarting Optuna optimization ({N_TRIALS} trials)...")
print("   Target: R² ≥ 0.75 (matching XGBoost)")
print("   This will take 20-30 minutes...\n")

study = optuna.create_study(direction="maximize")
study.optimize(objective, n_trials=N_TRIALS, show_progress_bar=True)

# ==========================================
# RESULTS
# ==========================================
print("\n" + "=" * 80)
print(" OPTIMIZATION RESULTS")
print("=" * 80)

best = study.best_trial
print(f"\n Best trial: #{best.number}")
print(f"   R² (KG space): {best.value:.4f}")
print(f"   MAE: {best.user_attrs['mae_kg']:.2f} kg")
print(f"   RMSE: {best.user_attrs['rmse_kg']:.2f} kg")

print(f"\n Best parameters:")
for k, v in best.params.items():
    print(f"   {k}: {v}")

# ==========================================
# FINAL MODEL
# ==========================================
print("\n Training final model with best parameters...")

best_params = best.params.copy()
best_params.update({
    'bootstrap_type': 'MVS',
    'eval_metric': 'R2',
    'random_seed': RANDOM_SEED,
    'verbose': 100
})

model = CatBoostRegressor(**best_params)
model.fit(
    X_train, y_train_log,
    eval_set=(X_val, y_val_log),
    verbose=100
)

def evaluate_set(X, y_log, y_kg_df, name):
    """Evaluate model on a dataset"""
    pred_log = model.predict(X)
    pred_kg = y_kg_df['Labor_Safe'] * (np.expm1(pred_log))
    actual_kg = y_kg_df['Target_Usable_Yield_Kg'].values
    
    r2_log = r2_score(y_log, pred_log)
    r2_kg = r2_score(actual_kg, pred_kg)
    mae = mean_absolute_error(actual_kg, pred_kg)
    rmse = np.sqrt(mean_squared_error(actual_kg, pred_kg))
    
    print(f"\n    {name} Set:")
    print(f"      R² (log space): {r2_log:.4f}")
    print(f"      R² (KG space):  {r2_kg:.4f}")
    print(f"      MAE:           {mae:.2f} kg")
    print(f"      RMSE:          {rmse:.2f} kg")
    
    return {'dataset': name, 'r2_log': r2_log, 'r2_kg': r2_kg, 'mae_kg': mae, 'rmse_kg': rmse}

print("\n FINAL EVALUATION:")
train_metrics = evaluate_set(X_train, y_train_log, y_train_kg, "Train")
val_metrics = evaluate_set(X_val, y_val_log, y_val_kg, "Validation")
test_metrics = evaluate_set(X_test, y_test_log, y_test_kg, "Test")

# ==========================================
# SAVE RESULTS
# ==========================================
print("\n Saving results...")

# Save best parameters
with open(os.path.join(RESULTS_FOLDER, "best_params.json"), 'w') as f:
    json.dump(best.params, f, indent=4)

# Save model
model.save_model(os.path.join(RESULTS_FOLDER, "catboost_model.cbm"))

# Save metrics
pd.DataFrame([train_metrics, val_metrics, test_metrics]).to_csv(
    os.path.join(RESULTS_FOLDER, "metrics.csv"), index=False)

# Save feature importance
pd.DataFrame({
    'feature': X_train.columns,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False).to_csv(
    os.path.join(RESULTS_FOLDER, "feature_importance.csv"), index=False)

print(f"   ✓ Results saved to: {RESULTS_FOLDER}")

# ==========================================
# FINAL COMPARISON
# ==========================================
print("\n" + "=" * 80)
print(" FINAL COMPARISON WITH XGBOOST")
print("=" * 80)

print(f"\n   XGBoost (reference):")
print(f"      R² (KG space): 0.792")

print(f"\n   Our CatBoost (with all XGBoost features):")
print(f"      Validation R²: {val_metrics['r2_kg']:.4f}")
print(f"      Test R²:       {test_metrics['r2_kg']:.4f}")

print(f"\n   Feature count:")
print(f"      XGBoost: 34 features")
print(f"      Our CatBoost: {X_train.shape[1]} features")

print(f"\n" + "=" * 80)
if test_metrics['r2_kg'] >= 0.75:
    print("🎉 SUCCESS! Achieved R² ≥ 0.75!")
    if test_metrics['r2_kg'] >= 0.792:
        print(" EXCELLENT! Beat XGBoost!")
    else:
        print(f" Matching XGBoost performance (gap: {0.792 - test_metrics['r2_kg']:.4f})")
else:
    print(f" Still below target: {test_metrics['r2_kg']:.4f}")
    print(f"   Gap to target: {0.75 - test_metrics['r2_kg']:.4f}")

print("=" * 80)