# ============================================
# OPTUNA HYPERPARAMETER TUNING (Native API)
# ============================================
import optuna
import xgboost as xgb
import pandas as pd
import numpy as np
import joblib
import warnings
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import KFold, train_test_split

# Import your preprocessing function
from preprocessing import preprocess_for_xgboost, augment_training_data

warnings.filterwarnings('ignore')

# ============================================
# LOAD AND PREPROCESS DATA
# ============================================
print("\n" + "="*60)
print("XGBoost OPTUNA TUNING (Native API) - Tea Price Prediction")
print("="*60)

# Load data first
df = pd.read_csv('../dataset/tea pricing.csv', dayfirst=True)

# Load data using the preprocessing pipeline
X, y = preprocess_for_xgboost(
    df=df, 
    is_training=True
)

# Feature Pruning handled in preprocessing.py now

# Split into Initial Train/Test (Hold-out Test Set)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Apply Light Augmentation (Anti-Overfitting)
X_train, y_train = augment_training_data(X_train, y_train, num_copies=1, noise_level=0.08)

print(f"\nData shapes:")
print(f"  X_train: {X_train.shape}")
print(f"  X_test: {X_test.shape}")

# ============================================
# OPTUNA OBJECTIVE FUNCTION
# ============================================
def objective(trial):
    # Define hyperparameter search space (Stricter Regularization)
    params = {
        'objective': 'reg:squarederror',
        'eval_metric': 'mae',
        'n_jobs': 1,
        'verbosity': 0,
        'random_state': 42,
        
        # Hyperparameters (Conservative Anti-Overfitting)
        'max_depth': trial.suggest_int('max_depth', 2, 3),  # Shallow trees only
        'learning_rate': trial.suggest_float('learning_rate', 0.02, 0.05), # Slow learning
        'subsample': trial.suggest_float('subsample', 0.6, 0.8),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 0.7),
        'min_child_weight': trial.suggest_int('min_child_weight', 10, 20), # Conservative splits
        'gamma': trial.suggest_float('gamma', 2.0, 5.0), # High penalty
        'alpha': trial.suggest_float('alpha', 5.0, 10.0),  # Strong L1
        'lambda': trial.suggest_float('lambda', 3.0, 8.0)  # Strong L2
    }
    
    # Pruning callback
    pruning_callback = optuna.integration.XGBoostPruningCallback(trial, "validation-mae")
    
    # K-Fold Cross Validation
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    mae_scores = []
    
    for train_idx, val_idx in kf.split(X_train):
        X_tr, X_val = X_train.iloc[train_idx], X_train.iloc[val_idx]
        y_tr, y_val = y_train.iloc[train_idx], y_train.iloc[val_idx]
        
        # Create DMatrix for native API
        dtrain = xgb.DMatrix(X_tr, label=y_tr)
        dval = xgb.DMatrix(X_val, label=y_val)
        
        # Train using native API
        model = xgb.train(
            params,
            dtrain,
            num_boost_round=trial.suggest_int('n_estimators', 200, 600),
            evals=[(dval, 'validation')],
            callbacks=[pruning_callback],
            verbose_eval=False,
            early_stopping_rounds=20
        )
        
        # Predict on validation set
        preds = model.predict(dval)
        mae = mean_absolute_error(y_val, preds)
        mae_scores.append(mae)
    
    return np.mean(mae_scores)

# ============================================
# RUN OPTIMIZATION
# ============================================
print("\nRunning Optuna Optimization (50 trials)...")
study = optuna.create_study(direction='minimize')
study.optimize(objective, n_trials=50, show_progress_bar=True)

print("\nBest Parameters (Optuna):")
best_params = study.best_params
print(best_params)

print(f"\nBest MAE (CV): Rs. {study.best_value:.2f}/kg")

# ============================================
# TRAIN FINAL MODEL WITH BEST PARAMS
# ============================================
print("\nTraining final model with best parameters...")

# Re-map params for final training if needed (n_estimators is specialized)
target_n_estimators = best_params.pop('n_estimators')
best_params['objective'] = 'reg:squarederror'
best_params['eval_metric'] = 'mae'
best_params['n_jobs'] = 1
best_params['verbosity'] = 0
best_params['random_state'] = 42
# Note: 'alpha' and 'lambda' are handled directly by native API

# Full Training Set
dtrain_full = xgb.DMatrix(X_train, label=y_train)
dtest = xgb.DMatrix(X_test, label=y_test)

final_model = xgb.train(
    best_params,
    dtrain_full,
    num_boost_round=target_n_estimators,
    evals=[(dtest, 'test')],
    verbose_eval=False
)

# Evaluate on Test Set
test_preds = final_model.predict(dtest)
test_mae = mean_absolute_error(y_test, test_preds)
test_r2 = r2_score(y_test, test_preds)
accuracy_within_20 = np.mean(np.abs(y_test - test_preds) <= 20)

print("\nTest Set Performance:")
print(f"  MAE: Rs. {test_mae:.2f}/kg")
print(f"  R²: {test_r2:.4f}")
print(f"  Accuracy within Rs.20: {accuracy_within_20*100:.1f}%")

# ============================================
# SAVE RESULTS
# ============================================
# We need to save a sklearn-compatible wrapper for compatibility with modeltraining.py
# or adjust modeltraining.py. Since we want to drop-in replace, let's wrap it back.
best_params['n_estimators'] = target_n_estimators

# Create sklearn wrapper for saving
sklearn_model = xgb.XGBRegressor(**best_params)
sklearn_model.fit(X_train, y_train)

joblib.dump(sklearn_model, '../results/tuning/xgboost_best_model.pkl')
print("\nBest model saved (wrapped): ../results/tuning/xgboost_best_model.pkl")

# Save tuning results
tuning_results = {
    'optuna_best_params': best_params,
    'optuna_best_value': study.best_value,
    'test_mae': test_mae,
    'test_r2': test_r2
}
joblib.dump(tuning_results, '../results/tuning/hyperparameter_tuning_results.pkl')
print("Tuning results saved: ../results/tuning/hyperparameter_tuning_results.pkl")