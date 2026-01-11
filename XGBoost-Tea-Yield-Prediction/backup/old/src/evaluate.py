# evaluate_compliance.py
# Purpose: Evaluate 18 kg/day incentive compliance using predictions from training
# Run after: train_xgboost_v8.py (which must save test_predictions_v8.csv)

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, accuracy_score, classification_report
import os

# ==========================================
# CONFIGURATION
# ==========================================
project_root = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\XGBoost-Tea-Yield-Prediction"
artifacts_folder = os.path.join(project_root, "Model_Artifacts_Final_v8")
output_folder = os.path.join(project_root, "Compliance_Analysis_v8")

os.makedirs(output_folder, exist_ok=True)

REAL_TARGET = 18.0      # The actual incentive goal
MODEL_THRESHOLD = 16.5  # Your "Safety Buffer" to reduce False Negatives

# ==========================================
# LOAD PREDICTIONS FROM TRAINING
# ==========================================
print("Loading test predictions for compliance evaluation...")
pred_file = os.path.join(artifacts_folder, "test_predictions_final.csv")

if not os.path.exists(pred_file):
    raise FileNotFoundError(f"Predictions file not found: {pred_file}\nRun training script first.")

df = pd.read_csv(pred_file)

# Required columns (from your training output)
required = ['actual_eff_kg', 'pred_eff_kg']
missing = [c for c in required if c not in df.columns]
if missing:
    raise ValueError(f"Missing columns in predictions CSV: {missing}")

actual_eff = df['actual_eff_kg'].values
pred_eff   = df['pred_eff_kg'].values

print(f"Loaded {len(df)} test samples")

# ==========================================
# BINARY COMPLIANCE CALCULATION
# ==========================================
actual_hit = (actual_eff >= REAL_TARGET).astype(int)
pred_hit   = (pred_eff   >= MODEL_THRESHOLD).astype(int)

# Metrics
accuracy = accuracy_score(actual_hit, pred_hit) * 100
tn, fp, fn, tp = confusion_matrix(actual_hit, pred_hit).ravel()

tpr = tp / (tp + fn) * 100 if (tp + fn) > 0 else 0      # True Positive Rate / Recall
fnr = fn / (tp + fn) * 100 if (tp + fn) > 0 else 0      # False Negative Rate
fpr = fp / (fp + tn) * 100 if (fp + tn) > 0 else 0      # False Positive Rate

print("="*80)
print("18 kg/day INCENTIVE COMPLIANCE PREDICTION RESULTS")
print("="*80)
print(f"Accuracy (correct hit/miss prediction):      {accuracy:.1f}%")
print(f"True Positive Rate (caught days ≥18 kg):     {tpr:.1f}%")
print(f"False Negative Rate (missed days ≥18 kg):    {fnr:.1f}%")
print(f"False Positive Rate (false alarm <18 kg):    {fpr:.1f}%")
print(f"Actual % of days ≥ 18 kg:                    {actual_hit.mean()*100:.1f}%")
print(f"Predicted % of days ≥ 18 kg:                 {pred_hit.mean()*100:.1f}%")
print("-"*80)

# Classification report
print("Detailed Classification Report:")
print(classification_report(actual_hit, pred_hit, target_names=['<18 kg', '≥18 kg']))
print("-"*80)

# ==========================================
# GRAPHS — VISUAL SUPPORT FOR 18KG IDEA
# ==========================================
print("\nGenerating compliance-supporting visualizations...")

# 1. Confusion Matrix Heatmap
# 1. Confusion Matrix Heatmap
plt.figure(figsize=(8, 6))

# Define 'cm' here so the heatmap can use it
cm = confusion_matrix(actual_hit, pred_hit) 

sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=['Pred <18', 'Pred ≥18'],
            yticklabels=['Actual <18', 'Actual ≥18'],
            cbar=False)
plt.xlabel('Predicted Compliance')
plt.ylabel('Actual Compliance')
plt.title('Confusion Matrix: 18 kg/day Target Compliance')
plt.tight_layout()
plt.savefig(os.path.join(output_folder, "18kg_Confusion_Matrix.png"), dpi=300)
plt.close()
print("Saved: 18kg_Confusion_Matrix.png")

# 2. Bar Plot: Actual vs Predicted Compliance Rate
compliance_summary = pd.DataFrame({
    'Category': ['Actual % ≥18 kg', 'Predicted % ≥18 kg'],
    'Percentage': [actual_hit.mean()*100, pred_hit.mean()*100]
})

plt.figure(figsize=(6, 5))
bars = sns.barplot(x='Category', y='Percentage', data=compliance_summary, palette=['#1f77b4', '#ff7f0e'])
plt.ylim(0, 100)
plt.ylabel('Percentage of Days')
plt.title('Actual vs Predicted Compliance with 18 kg Target')
for bar in bars.patches:
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 2,
             f"{bar.get_height():.1f}%", ha='center', va='bottom', fontweight='bold')
plt.tight_layout()
plt.savefig(os.path.join(output_folder, "18kg_Compliance_Bar.png"), dpi=300)
plt.close()
print("Saved: 18kg_Compliance_Bar.png")


# 3. Scatter Plot with Dual Threshold Lines
plt.figure(figsize=(10, 6))
sns.scatterplot(x=actual_eff, y=pred_eff, alpha=0.6, s=60, color='teal')

# Draw the Business Goal
plt.axhline(REAL_TARGET, color='red', linestyle='-', linewidth=2, label=f'Target ({REAL_TARGET}kg)')
# Draw your Model's Trigger Point (the Safety Buffer)
plt.axhline(MODEL_THRESHOLD, color='orange', linestyle='--', linewidth=2, label=f'Model Trigger ({MODEL_THRESHOLD}kg)')

plt.axvline(REAL_TARGET, color='red', linestyle='-', linewidth=2)

max_val = max(actual_eff.max(), pred_eff.max()) * 1.05
plt.plot([0, max_val], [0, max_val], 'k--', alpha=0.5, label='Perfect Prediction')
plt.xlim(0, max_val)
plt.ylim(0, max_val)
plt.xlabel('Actual Efficiency (kg/worker)')
plt.ylabel('Predicted Efficiency (kg/worker)')
plt.title(f'Efficiency Prediction: {MODEL_THRESHOLD}kg Trigger vs {REAL_TARGET}kg Target')
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
plt.savefig(os.path.join(output_folder, "Efficiency_Scatter_Dual_Threshold.png"), dpi=300)
plt.close()

# 4. Summary Table as Image (for thesis/report)
summary_data = [
    ["Accuracy", f"{accuracy:.1f}%"],
    ["True Positive Rate", f"{tpr:.1f}%"],
    ["False Negative Rate", f"{fnr:.1f}%"],
    ["Actual % ≥18 kg", f"{actual_hit.mean()*100:.1f}%"],
    ["Predicted % ≥18 kg", f"{pred_hit.mean()*100:.1f}%"]
]

fig, ax = plt.subplots(figsize=(6, 3))
ax.axis('off')
table = ax.table(cellText=summary_data, colLabels=['Metric', 'Value'], loc='center', cellLoc='center')
table.auto_set_font_size(False)
table.set_fontsize(12)
table.scale(1.3, 1.8)
plt.title("18 kg/day Compliance Summary", fontsize=14, pad=20)
plt.tight_layout()
plt.savefig(os.path.join(output_folder, "18kg_Compliance_Summary_Table.png"), dpi=300, bbox_inches='tight')
plt.close()
print("Saved: 18kg_Compliance_Summary_Table.png")

# ==========================================
# FINAL MESSAGE
# ==========================================
print(f"\nEvaluation complete.")
print(f"All compliance graphs and results saved to: {output_folder}")
print("Use these visuals directly in your thesis results/discussion section.")