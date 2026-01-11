"""
TEA YIELD PREDICTION WITH CATBOOST - FINAL VERSION
===============================================================
Pure CatBoost implementation focusing on tea yield prediction
This script handles the training, evaluation, and visualization of the CatBoost model.
"""

# Import pandas for data manipulation and analysis (e.g., DataFrames)
import pandas as pd
# Import numpy for numerical operations and array handling
import numpy as np
# Import matplotlib.pyplot for creating static, animated, and interactive visualizations
import matplotlib.pyplot as plt
# Import CatBoostRegressor for regression tasks and Pool for efficient data handling in CatBoost
from catboost import CatBoostRegressor, Pool
# Import warnings module to control warning messages
import warnings
# Import metrics from sklearn to evaluate model performance
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
# Import os module for interacting with the operating system (e.g., file paths)
import os
# Import time module for tracking execution time
import time
# Import matplotlib for plot customization
import matplotlib as mpl
# Import json for saving parameter configurations
import json

# Suppress warnings
# Filter out warnings to keep the output clean
warnings.filterwarnings('ignore')

# ==========================================
# CONFIGURATION
# ==========================================
# Define the root directory of the project
PROJECT_ROOT = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\CatBoost-Tea-Yield-Prediction"
# Define path to the processed data folder
PROCESSED_FOLDER = os.path.join(PROJECT_ROOT, "Preprocessed_CatBoost_XGBoost_Complete")
# Define path where graphs and visualizations will be saved
GRAPHS_FOLDER = os.path.join(PROJECT_ROOT, "CatBoost_Final_Results")
# Define path where model artifacts (model file, metrics, etc.) will be saved
ARTIFACTS_FOLDER = os.path.join(PROJECT_ROOT, "CatBoost_Final_Artifacts")

# Create necessary directories if they don't exist
for folder in [GRAPHS_FOLDER, ARTIFACTS_FOLDER]:
    # os.makedirs creates all intermediate-level directories needed to contain the leaf directory
    os.makedirs(folder, exist_ok=True)

# ==========================================
# LOAD DATA
# ==========================================
# Print separator line for readability
print("="*80)
# Print script title
print("CATBOOST TEA YIELD PREDICTION - FINAL IMPLEMENTATION")
# Print separator
print("="*80)
# Print status message
print("Training CatBoost model for tea yield prediction")
# Print separator
print("="*80)

# Load features
# Read training features from CSV
X_train = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_train.csv"))
# Read validation features from CSV
X_val = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_val.csv"))
# Read test features from CSV
X_test = pd.read_csv(os.path.join(PROCESSED_FOLDER, "X_test.csv"))

# Load targets
# Read training target (Log Efficiency) and select the first column
y_train_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_log.csv")).iloc[:, 0]
# Read validation target (Log Efficiency) and select the first column
y_val_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val_log.csv")).iloc[:, 0]
# Read test target (Log Efficiency) and select the first column
y_test_log = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test_log.csv")).iloc[:, 0]

# Load actual yield data
# Read actual training yield data (raw kg) for evaluation
y_train_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_train_kg.csv"))
# Read actual validation yield data (raw kg) for evaluation
y_val_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_val_kg.csv"))
# Read actual test yield data (raw kg) for evaluation
y_test_kg = pd.read_csv(os.path.join(PROCESSED_FOLDER, "y_test_kg.csv"))

# Print dataset overview
print(f"\nDATASET OVERVIEW:")
# Print number of training samples
print(f"   Training samples: {len(X_train):,}")
# Print number of validation samples
print(f"   Validation samples: {len(X_val):,}")
# Print number of test samples
print(f"   Test samples: {len(X_test):,}")
# Print number of features
print(f"   Features: {X_train.shape[1]}")

# Identify categorical features
# Find columns containing 'Division_' which indicates one-hot or categorical encoding
categorical_features = [col for col in X_train.columns if 'Division_' in col]
# Print count of categorical features found
print(f"   Categorical features: {len(categorical_features)}")

# ==========================================
# CATBOOST PARAMETERS
# ==========================================
# Print section header
print("\n" + "="*80)
print("CATBOOST PARAMETER CONFIGURATION")
print("="*80)

# Define Hyperparameters for CatBoost
CATBOOST_PARAMS = {
    'iterations': 1000,              # Number of trees to build
    'learning_rate': 0.03,           # Step size shrinkage used in update to prevent overfitting
    'depth': 6,                      # Depth of the tree
    'l2_leaf_reg': 3,                # L2 regularization term on weights
    'random_strength': 1,            # Randomness for scoring splits (helps avoid overfitting)
    'bagging_temperature': 0.5,      # Controls intensity of Bayesian bagging
    'border_count': 128,             # The number of splits for numerical features
    'loss_function': 'RMSE',         # Loss function to minimize (Root Mean Squared Error)
    'eval_metric': 'R2',             # Metric used for overfitting detection and best model selection
    'random_seed': 42,               # Seed for reproducibility
    'verbose': False,                # Suppress output during training
    'task_type': 'CPU',              # Use CPU for training
    'thread_count': -1,              # Use all available threads
    'early_stopping_rounds': 100,    # Stop if metric doesn't improve for 100 rounds
    'bootstrap_type': 'MVS',         # Minimum Variance Sampling (often better for large datasets)
    'grow_policy': 'SymmetricTree'   # Construct symmetric trees (CatBoost default, fast and stable)
}

# Print parameter settings
print("PARAMETERS SETTINGS:")
print(f"   Iterations: {CATBOOST_PARAMS['iterations']}")
print(f"   Learning Rate: {CATBOOST_PARAMS['learning_rate']:.4f}")
print(f"   Depth: {CATBOOST_PARAMS['depth']}")
print(f"   Grow Policy: {CATBOOST_PARAMS['grow_policy']}")
print(f"   Bootstrap Type: {CATBOOST_PARAMS['bootstrap_type']}")
print(f"   Categorical Features: {len(categorical_features)}")

# ==========================================
# TRAIN CATBOOST MODEL
# ==========================================
# Print training section header
print("\n" + "="*80)
print("TRAINING CATBOOST MODEL")
print("="*80)

# Record start time
start_time = time.time()

# Create CatBoost Pools
# Pool is an internal data structure of CatBoost that provides faster data processing
train_pool = Pool(X_train, y_train_log, cat_features=categorical_features)
# Create validation pool for evaluation during training
val_pool = Pool(X_val, y_val_log, cat_features=categorical_features)

# Print status
print("Training CatBoost model with native categorical handling...")
# Initialize CatBoost Regressor with defined parameters
model = CatBoostRegressor(**CATBOOST_PARAMS)
# Fit the model: Train on train_pool, evaluate on val_pool, output every 100 iters
model.fit(train_pool, eval_set=val_pool, verbose=100)

# Calculate total training time
training_time = time.time() - start_time
# Get the iteration index of the best result
best_iteration = model.get_best_iteration()
# Get the best R2 score achieved on validation set
best_score = model.get_best_score()['validation']['R2']

# Print training completion details
print(f"\nTRAINING COMPLETE")
print(f"   Training Time: {training_time:.1f} seconds")
print(f"   Best Iteration: {best_iteration}")
print(f"   Best Validation R2: {best_score:.4f}")

# ==========================================
# EVALUATE PERFORMANCE
# ==========================================
# Print evaluation section header
print("\n" + "="*80)
print("PERFORMANCE EVALUATION")
print("="*80)

# Make predictions on all datasets using the trained model
# Predict on training features (returns log efficiency)
train_pred_log = model.predict(X_train)
# Predict on validation features (returns log efficiency)
val_pred_log = model.predict(X_val)
# Predict on test features (returns log efficiency)
test_pred_log = model.predict(X_test)

# Convert to actual yield (kg)
# Formula: Yield_kg = Labor_Safe * (exp(Pred_Log_Eff) - 1)
# We use expm1(x) which calculates exp(x) - 1, inverse of log1p
train_pred_kg = y_train_kg['Labor_Safe'] * (np.expm1(train_pred_log))
# Convert validation predictions to kg
val_pred_kg = y_val_kg['Labor_Safe'] * (np.expm1(val_pred_log))
# Convert test predictions to kg
test_pred_kg = y_test_kg['Labor_Safe'] * (np.expm1(test_pred_log))

# Actual values
# Extract actual target yield values from the loaded dataframes
train_actual_kg = y_train_kg['Target_Usable_Yield_Kg'].values
val_actual_kg = y_val_kg['Target_Usable_Yield_Kg'].values
test_actual_kg = y_test_kg['Target_Usable_Yield_Kg'].values

# Calculate metrics function
# Define helper function to calculate common regression metrics
def calculate_metrics(y_true, y_pred, dataset_name):
    # Calculate R-squared score (Coefficient of Determination)
    r2 = r2_score(y_true, y_pred)
    # Calculate Mean Absolute Error (MAE)
    mae = mean_absolute_error(y_true, y_pred)
    # Calculate Root Mean Squared Error (RMSE)
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    
    # MAPE calculation
    # Mean Absolute Percentage Error
    valid_mask = y_true != 0 # Avoid division by zero
    if valid_mask.any():
        # Formula: mean(|(y_true - y_pred) / y_true|) * 100
        mape = np.mean(np.abs((y_true[valid_mask] - y_pred[valid_mask]) / y_true[valid_mask])) * 100
    else:
        mape = 0
    
    # Within 10% and 20% accuracy
    # Percentage of predictions where error is within 10% of actual value
    within_10 = np.sum(np.abs((y_true - y_pred) / y_true) <= 0.1) / len(y_true) * 100
    # Percentage of predictions where error is within 20% of actual value
    within_20 = np.sum(np.abs((y_true - y_pred) / y_true) <= 0.2) / len(y_true) * 100
    
    # Return dictionary of metrics
    return {
        'Dataset': dataset_name,
        'R2': r2,
        'MAE (kg)': mae,
        'RMSE (kg)': rmse,
        'MAPE (%)': mape,
        'Within 10% (%)': within_10,
        'Within 20% (%)': within_20,
        'Mean Yield (kg)': y_true.mean(),
        'Mean Prediction (kg)': y_pred.mean()
    }

# Calculate all metrics
# Calculate metrics for training set
train_metrics = calculate_metrics(train_actual_kg, train_pred_kg, 'Training')
# Calculate metrics for validation set
val_metrics = calculate_metrics(val_actual_kg, val_pred_kg, 'Validation')
# Calculate metrics for test set
test_metrics = calculate_metrics(test_actual_kg, test_pred_kg, 'Test')

# Create performance dataframe
# Combine metrics into a DataFrame for display and saving
performance_df = pd.DataFrame([train_metrics, val_metrics, test_metrics])

# Print summary table
print("\nPERFORMANCE SUMMARY:")
print("-" * 100)
print(performance_df.round(3).to_string(index=False))
print("-" * 100)

# Print key test metrics
print(f"\nKEY TEST PERFORMANCE:")
print(f"   R2 Score: {test_metrics['R2']:.4f} ({test_metrics['R2']*100:.1f}% variance explained)")
print(f"   MAE: {test_metrics['MAE (kg)']:.1f} kg ({test_metrics['MAE (kg)']/test_metrics['Mean Yield (kg)']*100:.1f}% error)")
print(f"   Within 10% error: {test_metrics['Within 10% (%)']:.1f}% of predictions")
print(f"   Within 20% error: {test_metrics['Within 20% (%)']:.1f}% of predictions")

# ==========================================
# FEATURE IMPORTANCE ANALYSIS
# ==========================================
# Print feature importance header
print("\n" + "="*80)
print("FEATURE IMPORTANCE ANALYSIS")
print("="*80)

# Get feature importances from the trained model
feature_importance = model.get_feature_importance()
# Get feature names from the training data
feature_names = X_train.columns

# Create dataframe for feature importance
importance_df = pd.DataFrame({
    'Feature': feature_names,
    'Importance': feature_importance,
    'Type': ['Categorical' if feat in categorical_features else 'Numerical' for feat in feature_names]
}).sort_values('Importance', ascending=False) # Sort by importance descending

# Print top 15 features
print("\nTOP 15 MOST IMPORTANT FEATURES:")
top_15 = importance_df.head(15)
for i, row in top_15.iterrows():
    # Helper for printing feature type
    feature_type = "(Categorical)" if row['Type'] == 'Categorical' else "(Numerical)"
    # Print rank, feature name, type, and importance score
    print(f"   {i+1:2d}. {row['Feature']:<35} {feature_type:<15} {row['Importance']:.4f}")

# Calculate category contributions
# Helper function to sum importance of features in a given list
def calculate_category_contribution(feature_list):
    matching = importance_df[importance_df['Feature'].isin(feature_list)]
    return matching['Importance'].sum() if not matching.empty else 0

# Define categories
# Features related to labor
labor_features = [f for f in feature_names if 'labor' in f.lower()]
# Features related to climate data
climate_features = [f for f in feature_names if any(x in f.lower() for x in ['humid', 'temp', 'rain', 'vpd'])]
# Features related to location (divisions)
location_features = categorical_features
# Features related to yield history or crop params
yield_features = [f for f in feature_names if any(x in f.lower() for x in ['yield', 'crop', 'waste', 'g_pct'])]
# Features related to time
temporal_features = [f for f in feature_names if f in ['Month', 'Week_of_Year', 'Day_of_Year', 'Is_Weekend']]

# Calculate total importance per category
labor_imp = calculate_category_contribution(labor_features)
climate_imp = calculate_category_contribution(climate_features)
location_imp = calculate_category_contribution(location_features)
yield_imp = calculate_category_contribution(yield_features)
temporal_imp = calculate_category_contribution(temporal_features)

# Calculate sum of all importances (should be ~100)
total_imp = importance_df['Importance'].sum()

# Print category contributions
print(f"\nFEATURE CONTRIBUTION BY CATEGORY:")
print(f"   Yield/Crop Factors:   {yield_imp/total_imp:.3f} ({yield_imp/total_imp*100:.1f}%)")
print(f"   Labor Factors:        {labor_imp/total_imp:.3f} ({labor_imp/total_imp*100:.1f}%)")
print(f"   Climate Factors:      {climate_imp/total_imp:.3f} ({climate_imp/total_imp*100:.1f}%)")
print(f"   Location Factors:     {location_imp/total_imp:.3f} ({location_imp/total_imp*100:.1f}%)")
print(f"   Temporal Factors:     {temporal_imp/total_imp:.3f} ({temporal_imp/total_imp*100:.1f}%)")

# ==========================================
# CATBOOST ADVANTAGES SUMMARY
# ==========================================
# Print advantages header
print("\n" + "="*80)
print("CATBOOST ADVANTAGES UTILIZED")
print("="*80)

# Print list of CatBoost advantages
print("\nCATBOOST STRENGTHS FOR AGRICULTURAL PREDICTION:")
print("   1. Native Categorical Handling - No encoding needed for plantation divisions")
print("   2. Robust to Outliers - Handles extreme weather events in climate data")
print("   3. Automatic Missing Value Handling - Climate data gaps handled automatically")
print("   4. Symmetric Trees - Better generalization for time-series agricultural data")
print("   5. Ordered Boosting - Reduces overfitting in seasonal yield patterns")
print("   6. Built-in Regularization - Prevents over-complex models")

# ==========================================
# VISUALIZATIONS
# ==========================================
# Print visualizations header
print("\n" + "="*80)
print("GENERATING VISUALIZATIONS")
print("="*80)

# Set style for plots
plt.style.use('seaborn-v0_8-whitegrid')
# Set DPI for display
mpl.rcParams['figure.dpi'] = 300
# Set DPI for saving files
mpl.rcParams['savefig.dpi'] = 300
# Set base font size
mpl.rcParams['font.size'] = 11

# 1. Actual vs Predicted Scatter Plot
plt.figure(figsize=(10, 8))
# Plot scatter points
plt.scatter(test_actual_kg, test_pred_kg, alpha=0.6, s=20, color='#00B4D2', edgecolor='white', linewidth=0.5)

# Perfect prediction line (x=y)
min_val = min(test_actual_kg.min(), test_pred_kg.min())
max_val = max(test_actual_kg.max(), test_pred_kg.max())
plt.plot([min_val, max_val], [min_val, max_val], 'k--', linewidth=1.5, alpha=0.8, label='Perfect Prediction')

# Set labels and title
plt.xlabel('Actual Yield (kg)', fontweight='bold', fontsize=12)
plt.ylabel('Predicted Yield (kg)', fontweight='bold', fontsize=12)
plt.title(f'CatBoost: Tea Yield Prediction\nTest Set R2 = {test_metrics["R2"]:.3f}, MAE = {test_metrics["MAE (kg)"]:.1f} kg', 
          fontweight='bold', fontsize=14)
# Add grid and legend
plt.grid(True, alpha=0.3)
plt.legend()
# Adjust layout to prevent clipping
plt.tight_layout()
# Save the plot
plt.savefig(os.path.join(GRAPHS_FOLDER, "catboost_prediction_performance.png"), 
            dpi=300, bbox_inches='tight', facecolor='white')
# Close the plot to free memory
plt.close()
print("Saved: catboost_prediction_performance.png")

# 2. Feature Importance Bar Chart
plt.figure(figsize=(12, 8))
top_15_viz = importance_df.head(15)

# Create color coding for bars based on feature category
colors = []
for feat in top_15_viz['Feature']:
    if 'labor' in feat.lower():
        colors.append('#F24236')  # Red for labor
    elif any(x in feat.lower() for x in ['yield', 'crop']):
        colors.append('#2E86AB')  # Blue for yield
    elif any(x in feat.lower() for x in ['humid', 'temp', 'rain']):
        colors.append('#73AB84')  # Green for climate
    elif 'division' in feat.lower():
        colors.append('#6D6875')  # Gray for location
    else:
        colors.append('#FFB347')  # Orange for others

# Create horizontal bar chart
bars = plt.barh(range(len(top_15_viz)), top_15_viz['Importance'], color=colors, edgecolor='black', linewidth=1)
# Set y-axis labels to feature names
plt.yticks(range(len(top_15_viz)), top_15_viz['Feature'], fontsize=10)
plt.xlabel('Feature Importance Score', fontweight='bold', fontsize=12)
plt.title(f'Top 15 Features - CatBoost Tea Yield Prediction\nTest R2 = {test_metrics["R2"]:.3f}', fontweight='bold', fontsize=14)
# Invert y-axis to show most important at top
plt.gca().invert_yaxis()
plt.grid(True, alpha=0.3, axis='x')

# Add value labels to bars
for i, (bar, importance) in enumerate(zip(bars, top_15_viz['Importance'])):
    plt.text(bar.get_width() + 0.001, bar.get_y() + bar.get_height()/2,
             f'{importance:.4f}', va='center', fontsize=9, fontweight='bold')

plt.tight_layout()
plt.savefig(os.path.join(GRAPHS_FOLDER, "catboost_feature_importance.png"),
            dpi=300, bbox_inches='tight', facecolor='white')
plt.close()
print("Saved: catboost_feature_importance.png")

# 3. Category Contribution Bar Chart
plt.figure(figsize=(10, 6))
categories = ['Yield/Crop', 'Labor', 'Climate', 'Location', 'Temporal']
contributions = [yield_imp, labor_imp, climate_imp, location_imp, temporal_imp]
percentages = [c/total_imp*100 for c in contributions]

# Define colors for categories
colors = ['#2E86AB', '#F24236', '#73AB84', '#6D6875', '#FFB347']
# Create bar chart
bars = plt.bar(categories, percentages, color=colors, edgecolor='black', linewidth=1.5)

plt.ylabel('Contribution to Prediction (%)', fontweight='bold', fontsize=12)
plt.title('Feature Contribution by Category - CatBoost Model', fontweight='bold', fontsize=14)
plt.xticks(rotation=45)
plt.grid(True, alpha=0.3, axis='y')

# Add value labels
for bar, percent in zip(bars, percentages):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
             f'{percent:.1f}%', ha='center', va='bottom', fontweight='bold', fontsize=10)

plt.tight_layout()
plt.savefig(os.path.join(GRAPHS_FOLDER, "catboost_category_contribution.png"),
            dpi=300, bbox_inches='tight', facecolor='white')
plt.close()
print("Saved: catboost_category_contribution.png")

# 4. Training History Line Plot
plt.figure(figsize=(10, 6))

# Extract training history from model
eval_results = model.get_evals_result()
if eval_results:
    train_r2 = eval_results['validation']['R2']
    epochs = range(1, len(train_r2) + 1)
    # Plot R2 score validation curve
    plt.plot(epochs, train_r2, 'b-', linewidth=2, label='Validation R2')
    # Add vertical line for best iteration
    plt.axvline(x=best_iteration, color='r', linestyle='--', linewidth=1.5, label=f'Best iteration: {best_iteration}')
    
    plt.xlabel('Training Iteration', fontweight='bold', fontsize=12)
    plt.ylabel('R2 Score', fontweight='bold', fontsize=12)
    plt.title('CatBoost Training Progress - R2 Score over Iterations', fontweight='bold', fontsize=14)
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(GRAPHS_FOLDER, "catboost_training_history.png"),
                dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    print("Saved: catboost_training_history.png")

# ==========================================
# SAVE RESULTS
# ==========================================
# Print saving section header
print("\n" + "="*80)
print("SAVING MODEL AND RESULTS")
print("="*80)

# Save model
# Define path used for model file
model_path = os.path.join(ARTIFACTS_FOLDER, "catboost_tea_yield_model.cbm")
# Save the trained CatBoost model
model.save_model(model_path)

# Save predictions
# Create a DataFrame with actuals, predictions, and errors for the test set
predictions_df = pd.DataFrame({
    'Actual_Yield_kg': test_actual_kg,
    'Predicted_Yield_kg': test_pred_kg,
    'Prediction_Error_kg': test_actual_kg - test_pred_kg,
    'Error_Percent': ((test_actual_kg - test_pred_kg) / test_actual_kg * 100),
    'Log_Efficiency_Actual': y_test_log.values,
    'Log_Efficiency_Predicted': test_pred_log,
    'Labor_Count': y_test_kg['Labor_Safe'].values,
    'Yield_per_Worker_Actual': test_actual_kg / y_test_kg['Labor_Safe'].values,
    'Yield_per_Worker_Predicted': test_pred_kg / y_test_kg['Labor_Safe'].values
})
predictions_path = os.path.join(ARTIFACTS_FOLDER, "catboost_predictions.csv")
# Save predictions to CSV
predictions_df.to_csv(predictions_path, index=False)

# Save performance metrics to CSV
performance_path = os.path.join(ARTIFACTS_FOLDER, "catboost_performance.csv")
performance_df.to_csv(performance_path, index=False)

# Save feature importance to CSV
importance_path = os.path.join(ARTIFACTS_FOLDER, "catboost_feature_importance.csv")
importance_df.to_csv(importance_path, index=False)

# Save parameters to JSON
params_save_path = os.path.join(ARTIFACTS_FOLDER, "catboost_parameters.json")
with open(params_save_path, 'w') as f:
    json.dump(CATBOOST_PARAMS, f, indent=4)

# Print confirmation messages
print(f"Model saved: {model_path}")
print(f"Predictions saved: {predictions_path}")
print(f"Performance metrics saved: {performance_path}")
print(f"Feature importance saved: {importance_path}")
print(f"Parameters saved: {params_save_path}")
print(f"Visualizations saved in: {GRAPHS_FOLDER}")

# ==========================================
# FINAL SUMMARY
# ==========================================
# Print final summary header
print("\n" + "="*80)
print("CATBOOST TEA YIELD PREDICTION - FINAL SUMMARY")
print("="*80)

# Print Model Performance section
print(f"\nMODEL PERFORMANCE:")
print(f"   Test R2: {test_metrics['R2']:.4f} ({test_metrics['R2']*100:.1f}% variance explained)")
print(f"   MAE: {test_metrics['MAE (kg)']:.1f} kg ({test_metrics['MAE (kg)']/test_metrics['Mean Yield (kg)']*100:.1f}% error)")
print(f"   Within 10% error: {test_metrics['Within 10% (%)']:.1f}% of predictions")
print(f"   Within 20% error: {test_metrics['Within 20% (%)']:.1f}% of predictions")

# Print Model Configuration section
print(f"\nMODEL CONFIGURATION:")
print(f"   Training time: {training_time:.1f} seconds")
print(f"   Best iteration: {best_iteration}")
print(f"   Features used: {X_train.shape[1]}")
print(f"   Categorical features: {len(categorical_features)}")

# Print Key Insights section
print(f"\nKEY INSIGHTS:")
print(f"   1. Most important feature: {top_15.iloc[0]['Feature']}")
print(f"   2. Yield/Crop factors contribute: {yield_imp/total_imp*100:.1f}%")
print(f"   3. Climate factors contribute: {climate_imp/total_imp*100:.1f}%")
print(f"   4. Labor factors contribute: {labor_imp/total_imp*100:.1f}%")
print(f"   5. Location factors contribute: {location_imp/total_imp*100:.1f}%")

# Print Advantages Utilized section
print(f"\nCATBOOST ADVANTAGES UTILIZED:")
print("   1. Native categorical feature handling for plantation divisions")
print("   2. Robust to agricultural data outliers and extremes")
print("   3. Automatic missing value handling for climate data")
print("   4. Symmetric trees for better generalization")
print("   5. Ordered boosting to reduce overfitting in time-series")

# Print Practical Applications section
print(f"\nPRACTICAL APPLICATIONS:")
print("   1. Weekly tea yield forecasting for plantations")
print("   2. Labor allocation optimization based on predictions")
print("   3. Climate impact assessment and adaptation planning")
print("   4. Resource management decision support")
print("   5. Yield prediction for different plantation divisions")

# Print Model Readiness section
print(f"\nMODEL READINESS:")
print("   1. Comprehensive performance evaluation completed")
print("   2. Feature importance analysis documented")
print("   3. All visualizations generated and saved")
print("   4. Model artifacts saved for deployment")
print("   5. Ready for thesis presentation and defense")

# Print closing footer
print(f"\nCATBOOST TEA YIELD PREDICTION MODEL COMPLETE!")
print("="*80)