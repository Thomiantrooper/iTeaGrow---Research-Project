import pandas as pd
import numpy as np
from datetime import datetime
import joblib
import matplotlib.pyplot as plt
import seaborn as sns

# Import preprocessing
from preprocessing import preprocess_for_xgboost, augment_training_data

# ============================================
# LOAD BEST HYPERPARAMETERS
# ============================================
print("="*60)
print("XGBoost FINAL MODEL TRAINING - Tea Price Prediction")
print("="*60)

# Load tuning results
try:
    tuning_results = joblib.load('../results/tuning/hyperparameter_tuning_results.pkl')
    
    # Handle different result structures (Optuna vs Grid/Random)
    if 'optuna_best_params' in tuning_results:
        best_params = tuning_results['optuna_best_params']
        print("Loaded best parameters from Optuna Optimization")
        
        # Ensure n_estimators is passed correctly if it was part of tuning
        if 'n_estimators' not in best_params and 'num_boost_round' in best_params:
             best_params['n_estimators'] = best_params.pop('num_boost_round')

    elif 'grid_search' in tuning_results:
        best_params = tuning_results['grid_search']['best_params']
        print("Loaded best parameters from Grid Search")
    else:
        best_params = tuning_results['random_search']['best_params']
        print("Loaded best parameters from Random Search")

except Exception as e:
    print(f"Could not load tuning results: {e}")
    # Fallback to a reasonable default if file missing
    best_params = {
        'max_depth': 3,
        'learning_rate': 0.1,
        'n_estimators': 100
    }

print("\nUsing hyperparameters:")
for param, value in best_params.items():
    print(f"  {param}: {value}")

# ============================================
# LOAD AND PREPROCESS ALL DATA
# ============================================
df = pd.read_csv("../dataset/tea pricing.csv")
print(f"\nLoaded {len(df)} rows")

# Preprocess ALL data (no split yet)
X, y = preprocess_for_xgboost(df, is_training=True)

# Feature Pruning handled in preprocessing.py now

# ============================================
# FINAL TRAIN/VALIDATION/TEST SPLIT
# ============================================
print("\nCreating train/validation/test splits...")

# Time-based split (respecting chronological order)
train_size = int(len(X) * 0.7)
val_size = int(len(X) * 0.15)
test_size = len(X) - train_size - val_size

X_train = X.iloc[:train_size]
X_val = X.iloc[train_size:train_size+val_size]
X_test = X.iloc[train_size+val_size:]

y_train = y.iloc[:train_size]
y_val = y.iloc[train_size:train_size+val_size]
y_val = y.iloc[train_size:train_size+val_size]
y_test = y.iloc[train_size+val_size:]

# Apply Light Augmentation (Anti-Overfitting)
X_train, y_train = augment_training_data(X_train, y_train, num_copies=1, noise_level=0.08)

print(f"\nSplit sizes:")
print(f"  Train: {len(X_train)} rows ({X_train.index[0]} to {X_train.index[-1]})")
print(f"  Validation: {len(X_val)} rows ({X_val.index[0]} to {X_val.index[-1]})")
print(f"  Test: {len(X_test)} rows ({X_test.index[0]} to {X_test.index[-1]})")

# ============================================
# TRAIN FINAL MODEL
# ============================================
import xgboost as xgb
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import time

print("\nTraining final XGBoost model...")
start_time = time.time()

# Remove redundant parameters if present in best_params
for key in ['objective', 'n_jobs', 'random_state', 'verbosity', 'early_stopping_rounds', 'callbacks', 'eval_metric']:
    best_params.pop(key, None)

# Create model with best parameters
final_model = xgb.XGBRegressor(
    **best_params,
    objective='reg:squarederror',
    random_state=42,
    n_jobs=-1,
    early_stopping_rounds=50,
    eval_metric=['mae', 'rmse']
)

# Train with validation set for early stopping
final_model.fit(
    X_train, y_train,
    eval_set=[(X_train, y_train), (X_val, y_val)],
    verbose=100
)

training_time = time.time() - start_time
print(f"Training completed in {training_time:.2f} seconds")

# ============================================
# COMPREHENSIVE EVALUATION
# ============================================
print("\n" + "="*60)
print("FINAL MODEL EVALUATION")
print("="*60)

# Predictions on all sets
y_train_pred = final_model.predict(X_train)
y_val_pred = final_model.predict(X_val)
y_test_pred = final_model.predict(X_test)

# Metrics
def calculate_metrics(y_true, y_pred, dataset_name):
    mae = mean_absolute_error(y_true, y_pred)
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    r2 = r2_score(y_true, y_pred)
    mape = np.mean(np.abs((y_true - y_pred) / y_true)) * 100
    
    print(f"\n{dataset_name} SET:")
    print(f"  MAE: Rs. {mae:.2f}/kg")
    print(f"  RMSE: Rs. {rmse:.2f}/kg")
    print(f"  R² Score: {r2:.4f}")
    print(f"  MAPE: {mape:.2f}%")
    print(f"  Accuracy within Rs.10: {np.mean(np.abs(y_true - y_pred) < 10)*100:.1f}%")
    print(f"  Accuracy within Rs.20: {np.mean(np.abs(y_true - y_pred) < 20)*100:.1f}%")
    print(f"  Accuracy within Rs.30: {np.mean(np.abs(y_true - y_pred) < 30)*100:.1f}%")
    
    return {'mae': mae, 'rmse': rmse, 'r2': r2, 'mape': mape}

train_metrics = calculate_metrics(y_train, y_train_pred, "TRAIN")
val_metrics = calculate_metrics(y_val, y_val_pred, "VALIDATION")
test_metrics = calculate_metrics(y_test, y_test_pred, "TEST")

# Check for overfitting
print("\nOVERFITTING CHECK:")
print(f"  Train MAE: Rs. {train_metrics['mae']:.2f}/kg")
print(f"  Test MAE: Rs. {test_metrics['mae']:.2f}/kg")
print(f"  Difference: Rs. {abs(train_metrics['mae'] - test_metrics['mae']):.2f}/kg")
if abs(train_metrics['mae'] - test_metrics['mae']) < 5:
    print("  No overfitting detected!")
else:
    print("  Possible overfitting - consider regularization")

# ============================================
# FEATURE IMPORTANCE ANALYSIS
# ============================================
print("\n" + "="*60)
print("FEATURE IMPORTANCE ANALYSIS")
print("="*60)

# Get feature importance
importance_df = pd.DataFrame({
    'feature': X.columns,
    'importance': final_model.feature_importances_
}).sort_values('importance', ascending=False)

print("\nTop 15 Most Important Features:")
for idx, row in importance_df.head(15).iterrows():
    print(f"  {row['feature']}: {row['importance']:.4f}")

# Save feature importance
importance_df.to_csv('../results/final_model/feature_importance.csv', index=False)

# ============================================
# VISUALIZATIONS
# ============================================
print("\nGenerating visualizations...")

fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# 1. Feature Importance Plot
ax = axes[0, 0]
top_features = importance_df.head(10)
ax.barh(top_features['feature'], top_features['importance'])
ax.set_xlabel('Importance')
ax.set_title('Top 10 Feature Importance')
ax.invert_yaxis()

# 2. Actual vs Predicted (Test Set)
ax = axes[0, 1]
ax.scatter(y_test, y_test_pred, alpha=0.5)
ax.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--', lw=2)
ax.set_xlabel('Actual Price (Rs/kg)')
ax.set_ylabel('Predicted Price (Rs/kg)')
ax.set_title(f'Actual vs Predicted (Test Set)\nMAE: Rs. {test_metrics["mae"]:.2f}/kg')

# 3. Residuals Distribution
ax = axes[1, 0]
residuals = y_test - y_test_pred
ax.hist(residuals, bins=50, edgecolor='black')
ax.set_xlabel('Prediction Error (Rs/kg)')
ax.set_ylabel('Frequency')
ax.set_title(f'Residuals Distribution\nMean Error: {residuals.mean():.2f}, Std: {residuals.std():.2f}')
ax.axvline(x=0, color='r', linestyle='--')

# 4. Learning Curves
ax = axes[1, 1]
results = final_model.evals_result()
epochs = len(results['validation_0']['mae'])
x_axis = range(0, epochs)
ax.plot(x_axis, results['validation_0']['mae'], label='Train')
ax.plot(x_axis, results['validation_1']['mae'], label='Validation')
ax.set_xlabel('Boosting Rounds')
ax.set_ylabel('MAE')
ax.set_title('Learning Curves')
ax.legend()

plt.tight_layout()
plt.savefig('../results/final_model/xgboost_model_analysis.png', dpi=300)
plt.show()

# ============================================
# SAVE FINAL MODEL AND METADATA
# ============================================
print("\n" + "="*60)
print("SAVING FINAL MODEL")
print("="*60)

# Save model
joblib.dump(final_model, '../results/final_model/xgboost_final_tea_model.pkl')

# Save metadata
model_metadata = {
    'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'features': list(X.columns),
    'n_features': len(X.columns),
    'n_train_samples': len(X_train),
    'n_val_samples': len(X_val),
    'n_test_samples': len(X_test),
    'hyperparameters': best_params,
    'test_mae': test_metrics['mae'],
    'test_r2': test_metrics['r2'],
    'test_mape': test_metrics['mape'],
    'training_time_seconds': training_time
}

joblib.dump(model_metadata, '../results/final_model/model_metadata.pkl')

# Save as JSON for easy reading
import json
with open('../results/final_model/model_metadata.json', 'w') as f:
    json.dump({k: str(v) if isinstance(v, (np.integer, np.floating)) else v 
               for k, v in model_metadata.items()}, f, indent=2)

print("\nModel and metadata saved successfully!")
print(f"  Model: ../results/final_model/xgboost_final_tea_model.pkl")
print(f"  Metadata: ../results/final_model/model_metadata.pkl")
print(f"  Feature importance: ../results/final_model/feature_importance.csv")
print(f"  Visualization: ../results/final_model/xgboost_model_analysis.png")

# ============================================
# QUICK TEST PREDICTION
# ============================================
print("\n" + "="*60)
print("QUICK TEST PREDICTION")
print("="*60)

def quick_predict():
    """Test a single prediction"""
    
    # Sample inputs
    test_grade = "BOPF"
    test_confidence = 0.94
    test_user_inputs = {
        'color': 1.0,
        'aroma': 0.5,
        'age': 0.5,
        'quantity': 500
    }
    test_market = {
        'market_price': 1143,
        'rainfall_mm': 125,
        'season': 'Peak',
        'exchange_rate': 309
    }
    
    # Load encoders
    grade_encoder = joblib.load('../results/preprocessing/grade_encoder.pkl')
    season_encoder = joblib.load('../results/preprocessing/season_encoder.pkl')
    feature_names = joblib.load('../results/preprocessing/feature_names.pkl')
    
    # Create feature vector
    row = {
        'grade_encoded': grade_encoder[test_grade],
        'confidence': test_confidence,
        'color': test_user_inputs['color'],
        'aroma': test_user_inputs['aroma'],
        'age': test_user_inputs['age'],
        'quantity_kg': test_user_inputs['quantity'],
        'market_price': test_market['market_price'],
        'rainfall_mm': test_market['rainfall_mm'],
        'exchange_rate': test_market['exchange_rate'],
        'season_encoded': season_encoder[test_market['season']]
    }
    
    # Add derived features
    # Add derived features (Decomposed)
    row['grade_color'] = row['grade_encoded'] * row['color']
    row['grade_aroma'] = row['grade_encoded'] * row['aroma']
    row['grade_age'] = row['grade_encoded'] * row['age']
    
    row['market_rainfall_interaction'] = row['market_price'] * (row['rainfall_mm'] / 100)
    
    # Default values for other features
    row['price_momentum_3d'] = 0
    row['price_momentum_7d'] = 0
    row['price_ma_7d'] = row['market_price']
    row['price_std_7d'] = 0
    row['rainfall_lag_7d'] = row['rainfall_mm']
    row['rainfall_lag_14d'] = row['rainfall_mm']
    row['rainfall_lag_30d'] = row['rainfall_mm']
    row['rainfall_cum_30d'] = row['rainfall_mm'] * 30
    row['exchange_momentum_7d'] = 0
    row['month_sin'] = np.sin(2 * np.pi * datetime.now().month / 12)
    row['month_cos'] = np.cos(2 * np.pi * datetime.now().month / 12)
    
    # Create DataFrame
    X_pred = pd.DataFrame([row])
    
    # Ensure column order matches model
    # final_model might not have feature_names_in_ if loaded from pickle sometimes, but since we just trained it:
    if hasattr(final_model, 'feature_names_in_'):
        X_pred = X_pred[final_model.feature_names_in_]
    
    # Predict
    price = final_model.predict(X_pred)[0]
    
    print(f"\nTest Input:")
    print(f"  Grade: {test_grade} (confidence: {test_confidence})")
    print(f"  Quality: Color={test_user_inputs['color']}, Aroma={test_user_inputs['aroma']}, Age={test_user_inputs['age']}")
    print(f"  Quantity: {test_user_inputs['quantity']} kg")
    print(f"  Market Price: Rs. {test_market['market_price']}/kg")
    print(f"  Rainfall: {test_market['rainfall_mm']} mm")
    print(f"  Season: {test_market['season']}")
    print(f"  Exchange Rate: Rs. {test_market['exchange_rate']}/USD")
    
    print(f"\nPredicted Price: Rs. {price:.2f}/kg")
    print(f"Total Value: Rs. {price * test_user_inputs['quantity']:,.2f}")
    
    return price

test_price = quick_predict()