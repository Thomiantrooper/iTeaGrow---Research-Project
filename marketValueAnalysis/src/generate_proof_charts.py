"""
generate_proof_charts.py
Generates comprehensive validation charts for the Tea Price Prediction Model.
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
import shap
import os
from sklearn.metrics import mean_absolute_error, r2_score

# Configure plotting
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

# Ensure output directory exists
OUTPUT_DIR = '../results/final_model/plots'
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_charts():
    print("="*60)
    print("GENERATING PROOF OF PERFORMANCE CHARTS")
    print("="*60)

    # 1. Load Data and Model
    print("\nLoading data and model...")
    try:
        df = pd.read_csv("../dataset/tea pricing.csv")
    except FileNotFoundError:
        # Try local path if running from src
        df = pd.read_csv("../../marketvalueanlys/dataset/tea pricing.csv")
    
    # We need to preprocess the data exactly as the model expects
    from preprocessing import preprocess_for_xgboost
    X, y = preprocess_for_xgboost(df, is_training=True)
    
    # Load model
    model = joblib.load('../results/final_model/xgboost_final_tea_model.pkl')
    
    # Split data (same logic as training)
    train_size = int(len(X) * 0.7)
    val_size = int(len(X) * 0.15)
    
    # Use Test set for validation charts
    X_test = X.iloc[train_size+val_size:]
    y_test = y.iloc[train_size+val_size:]
    
    print(f"Loaded {len(X_test)} test samples for validation")
    
    # Get predictions
    y_pred = model.predict(X_test)
    
    # ========================================================
    # 1. Actual vs Predicted Scatter
    # ========================================================
    print("\nGenerating 1. Predicted vs Actual Plot...")
    plt.figure(figsize=(10, 8))
    plt.scatter(y_test, y_pred, alpha=0.6, color='#2ecc71', edgecolors='w', s=80)
    
    # Ideal line
    min_val = min(y_test.min(), y_pred.min())
    max_val = max(y_test.max(), y_pred.max())
    plt.plot([min_val, max_val], [min_val, max_val], 'r--', lw=2, label='Ideal Fit')
    
    plt.xlabel('Actual Market Price (Rs/kg)', fontsize=12)
    plt.ylabel('Predicted Price (Rs/kg)', fontsize=12)
    plt.title(f'Actual vs Predicted Prices\nMAE: Rs. {mean_absolute_error(y_test, y_pred):.2f}/kg | R²: {r2_score(y_test, y_pred):.4f}', fontsize=14)
    plt.legend()
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/1_actual_vs_predicted.png', dpi=300)
    plt.close()

    # ========================================================
    # 2. Residual Plot
    # ========================================================
    print("Generating 2. Residual Plot...")
    residuals = y_test - y_pred
    
    plt.figure(figsize=(10, 6))
    plt.scatter(y_pred, residuals, alpha=0.6, color='#3498db', edgecolors='w')
    plt.axhline(y=0, color='r', linestyle='--', lw=2)
    plt.xlabel('Predicted Price (Rs/kg)', fontsize=12)
    plt.ylabel('Residuals (Actual - Predicted)', fontsize=12)
    plt.title('Residual Plot (Checks for Bias)', fontsize=14)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/2_residuals.png', dpi=300)
    plt.close()

    # ========================================================
    # 3. Error Histogram
    # ========================================================
    print("Generating 3. Error Histogram...")
    plt.figure(figsize=(10, 6))
    sns.histplot(residuals, kde=True, color='#9b59b6', bins=30)
    plt.axvline(x=0, color='r', linestyle='--', lw=2)
    plt.xlabel('Prediction Error (Rs/kg)', fontsize=12)
    plt.title('Distribution of Prediction Errors', fontsize=14)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/3_error_histogram.png', dpi=300)
    plt.close()

    # ========================================================
    # 4. Feature Importance
    # ========================================================
    print("Generating 4. Feature Importance...")
    importance = pd.DataFrame({
        'feature': X.columns,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False).head(10)
    
    plt.figure(figsize=(12, 8))
    sns.barplot(data=importance, y='feature', x='importance', palette='viridis')
    plt.title('Top 10 Key Price Drivers', fontsize=14)
    plt.xlabel('Relative Importance', fontsize=12)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/4_feature_importance.png', dpi=300)
    plt.close()

    # ========================================================
    # 5. Accuracy per Grade (Boxplot)
    # ========================================================
    print("Generating 5. Accuracy per Grade...")
    # Map back encoded grades
    try:
        grade_encoder = joblib.load('../results/preprocessing/grade_encoder.pkl')
        inv_grade_map = {v: k for k, v in grade_encoder.items()}
        
        plot_df = pd.DataFrame({
            'Grade': X_test['grade_encoded'].map(inv_grade_map),
            'Absolute Error': np.abs(residuals)
        })
        
        plt.figure(figsize=(12, 6))
        sns.boxplot(data=plot_df, x='Grade', y='Absolute Error', palette='Set3')
        plt.title('Model Accuracy Consistency Across Grades', fontsize=14)
        plt.ylabel('Absolute Error (Rs/kg)', fontsize=12)
        plt.axhline(y=20, color='r', linestyle=':', label='Target Margin (Rs. 20)')
        plt.legend()
        plt.tight_layout()
        plt.savefig(f'{OUTPUT_DIR}/5_accuracy_by_grade.png', dpi=300)
        plt.close()
    except Exception as e:
        print(f"Could not generate grade accuracy plot: {e}")

    # ========================================================
    # 6. SHAP Summary Plot
    # ========================================================
    print("Generating 6. SHAP Explainability Charts...")
    try:
        # Use TreeExplainer for XGBoost
        explainer = shap.TreeExplainer(model)
        shap_values = explainer.shap_values(X_test)
        
        plt.figure(figsize=(10, 8))
        shap.summary_plot(shap_values, X_test, show=False)
        plt.title('SHAP Summary: Impact of Features on Price', fontsize=14)
        plt.tight_layout()
        plt.savefig(f'{OUTPUT_DIR}/6_shap_summary.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        # 7. SHAP Dependence Plot (Top Feature)
        top_feature = importance.iloc[0]['feature']
        print(f"   - Generating Dependence plot for: {top_feature}")
        
        plt.figure(figsize=(10, 6))
        shap.dependence_plot(top_feature, shap_values, X_test, show=False)
        plt.title(f'SHAP Dependence: How {top_feature} affects Price', fontsize=14)
        plt.tight_layout()
        plt.savefig(f'{OUTPUT_DIR}/7_shap_dependence_{top_feature}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    except Exception as e:
        print(f"Could not generate SHAP plots: {e}")

    # ========================================================
    # 8. REC Curve (Regression Error Characteristic)
    # ========================================================
    print("Generating 8. REC Curve...")
    
    def get_rec_curve(y_true, y_pred):
        errors = np.abs(y_true - y_pred)
        tolerances = np.linspace(0, 100, 1000)
        accuracy = []
        
        for t in tolerances:
            acc = np.mean(errors <= t)
            accuracy.append(acc)
            
        return tolerances, accuracy

    tol, acc = get_rec_curve(y_test, y_pred)
    
    plt.figure(figsize=(10, 6))
    plt.plot(tol, acc, lw=3, color='#e74c3c')
    plt.xlabel('Error Tolerance (Rs/kg)', fontsize=12)
    plt.ylabel('Accuracy % (Samples within tolerance)', fontsize=12)
    plt.title('REC Curve: Accuracy at Different Tolerances', fontsize=14)
    
    # Highlight key points
    for t in [10, 20, 30]:
        val = np.mean(np.abs(residuals) <= t)
        plt.plot(t, val, 'bo')
        plt.annotate(f'{val*100:.1f}% @ Rs.{t}', 
                     (t, val), xytext=(10, -15), textcoords='offset points')
        
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(f'{OUTPUT_DIR}/8_rec_curve.png', dpi=300)
    plt.close()

    print(f"\nAll charts saved to: {os.path.abspath(OUTPUT_DIR)}")

if __name__ == "__main__":
    generate_charts()
