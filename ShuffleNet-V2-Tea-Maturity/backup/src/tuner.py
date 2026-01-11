# """
# SHUFFLENETV2 HYPERPARAMETER TUNER (OPTUNA - RESEARCH GRADE)
# ===========================================================
# - Framework: PyTorch (Compatible with preprocessing.py)
# - Strategy: Two-Stage Training (Head -> Fine-Tune)
# - Features: Pruning, Auto-Resume, Keras-style JSON Logging
# """

# import os
# import json
# import torch
# import torch.nn as nn
# import torch.optim as optim
# from torchvision import models
# import optuna
# from optuna.trial import TrialState
# import copy

# # Import pipeline
# try:
#     from preprocessing import create_data_loaders, CLASS_MAP, set_seed
# except ImportError:
#     raise ImportError("CRITICAL ERROR: Could not import 'preprocessing.py'.")

# # ==============================================================================
# #   TUNING CONFIGURATION
# # ==============================================================================
# class TuneConfig:
#     N_TRIALS = 30               # Total trials to run
#     EPOCHS_HEAD = 5             # Short warmup per trial
#     EPOCHS_FINE = 8             # Short fine-tuning per trial
#     BATCH_SIZE = 32             # Matches your training script
#     DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
    
#     # Path to save results (Keras Tuner Style)
#     BASE_LOG_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity\tuning_results"
#     DB_NAME = "tea_tuning.db"   # Optuna database for pausing/resuming

# # Ensure log directory exists
# os.makedirs(TuneConfig.BASE_LOG_DIR, exist_ok=True)

# # ==============================================================================
# #   GLOBAL DATA LOADING (SPEED OPTIMIZATION)
# # ==============================================================================
# print(f"[INFO] Loading data globally for tuning on {TuneConfig.DEVICE}...")
# set_seed(42)
# # Load data ONCE so we don't waste time reloading it 30 times
# train_loader, val_loader, _, _, _, _ = create_data_loaders(batch_size=TuneConfig.BATCH_SIZE)

# # ==============================================================================
# #   HELPER: SAVE TRIAL RESULTS (JSON + PTH)
# # ==============================================================================
# def save_trial_results(trial, params, accuracy, model):
#     """Saves separate JSON and .pth files for each trial, mimicking Keras Tuner."""
#     trial_dir = os.path.join(TuneConfig.BASE_LOG_DIR, f"trial_{trial.number:02d}")
#     os.makedirs(trial_dir, exist_ok=True)
    
#     # 1. Save Metrics & Params to JSON
#     results = {
#         "trial_id": trial.number,
#         "status": "COMPLETED",
#         "val_accuracy": float(accuracy),
#         "hyperparameters": params
#     }
    
#     with open(os.path.join(trial_dir, "trial.json"), "w") as f:
#         json.dump(results, f, indent=4)
        
#     # 2. Save Model Weights
#     torch.save(model.state_dict(), os.path.join(trial_dir, "checkpoint.pth"))

# # ==============================================================================
# #   THE OBJECTIVE FUNCTION
# # ==============================================================================
# def objective(trial):
#     # 1. Define Search Space
#     dropout = trial.suggest_float("dropout", 0.2, 0.6, step=0.1)
#     lr_head = trial.suggest_float("lr_head", 1e-4, 5e-3, log=True)
#     lr_fine = trial.suggest_float("lr_fine", 1e-6, 1e-4, log=True)
#     weight_decay = trial.suggest_float("weight_decay", 1e-5, 1e-3, log=True)

#     # 2. Build Model
#     model = models.shufflenet_v2_x1_0(weights="DEFAULT")
#     in_features = model.fc.in_features
#     model.fc = nn.Sequential(
#         nn.Dropout(dropout),
#         nn.Linear(in_features, len(CLASS_MAP))
#     )
#     model = model.to(TuneConfig.DEVICE)
    
#     criterion = nn.CrossEntropyLoss()

#     # 3. STAGE 1: HEAD TUNING (Freeze Backbone)
#     for param in model.parameters(): param.requires_grad = False
#     for param in model.fc.parameters(): param.requires_grad = True
        
#     optimizer = optim.AdamW(model.fc.parameters(), lr=lr_head, weight_decay=weight_decay)

#     for epoch in range(TuneConfig.EPOCHS_HEAD):
#         model.train()
#         for inputs, labels in train_loader:
#             inputs, labels = inputs.to(TuneConfig.DEVICE), labels.to(TuneConfig.DEVICE)
#             optimizer.zero_grad()
#             outputs = model(inputs)
#             loss = criterion(outputs, labels)
#             loss.backward()
#             optimizer.step()
            
#         # Pruning check (Stop bad trials early to save time)
#         val_acc = evaluate(model)
#         trial.report(val_acc, epoch)
#         if trial.should_prune():
#             raise optuna.exceptions.TrialPruned()

#     # 4. STAGE 2: FINE TUNING (Unfreeze Stage 4 + Conv5)
#     for name, param in model.named_parameters():
#         if "stage4" in name or "conv5" in name or "fc" in name:
#             param.requires_grad = True
            
#     optimizer = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), 
#                            lr=lr_fine, weight_decay=weight_decay)
    
#     best_val_acc = 0.0
    
#     for epoch in range(TuneConfig.EPOCHS_FINE):
#         model.train()
#         for inputs, labels in train_loader:
#             inputs, labels = inputs.to(TuneConfig.DEVICE), labels.to(TuneConfig.DEVICE)
#             optimizer.zero_grad()
#             outputs = model(inputs)
#             loss = criterion(outputs, labels)
#             loss.backward()
#             optimizer.step()
            
#         val_acc = evaluate(model)
#         if val_acc > best_val_acc:
#             best_val_acc = val_acc
            
#         trial.report(val_acc, TuneConfig.EPOCHS_HEAD + epoch)
#         if trial.should_prune():
#             raise optuna.exceptions.TrialPruned()
            
#     # --- LOGGING: Save JSON & Checkpoint like Keras Tuner ---
#     save_trial_results(trial, trial.params, best_val_acc, model)

#     return best_val_acc

# def evaluate(model):
#     model.eval()
#     correct = 0
#     total = 0
#     with torch.no_grad():
#         for inputs, labels in val_loader:
#             inputs, labels = inputs.to(TuneConfig.DEVICE), labels.to(TuneConfig.DEVICE)
#             outputs = model(inputs)
#             preds = outputs.argmax(dim=1)
#             correct += (preds == labels).sum().item()
#             total += inputs.size(0)
#     return correct / total

# # ==============================================================================
# #   RUNNER
# # ==============================================================================
# if __name__ == "__main__":
#     print(f"\n[INFO] Starting Optuna Search ({TuneConfig.N_TRIALS} Trials)...")
#     print(f"[INFO] Results will be saved to: {TuneConfig.BASE_LOG_DIR}")
    
#     # We use SQLite to allow stop/resume functionality
#     db_path = os.path.join(TuneConfig.BASE_LOG_DIR, TuneConfig.DB_NAME)
#     storage_url = f"sqlite:///{db_path}"
    
#     study = optuna.create_study(
#         direction="maximize", 
#         storage=storage_url, 
#         study_name="tea_shufflenet_study",
#         load_if_exists=True
#     )
    
#     study.optimize(objective, n_trials=TuneConfig.N_TRIALS)
    
#     print("\n" + "="*60)
#     print("🏆 FINAL WINNING CONFIGURATION 🏆")
#     print("="*60)
#     best = study.best_params
#     print(f"DROPOUT_RATE  = {best['dropout']:.2f}")
#     print(f"LR_HEAD       = {best['lr_head']:.2e}")
#     print(f"LR_FINE       = {best['lr_fine']:.2e}")
#     print(f"WEIGHT_DECAY  = {best['weight_decay']:.2e}")
#     print(f"Best Accuracy = {study.best_value*100:.2f}%")
#     print("="*60)
    
#     # Try to plot if environment supports it
#     try:
#         import plotly
#         fig1 = optuna.visualization.plot_optimization_history(study)
#         fig1.write_html(os.path.join(TuneConfig.BASE_LOG_DIR, "optimization_history.html"))
#         fig2 = optuna.visualization.plot_param_importances(study)
#         fig2.write_html(os.path.join(TuneConfig.BASE_LOG_DIR, "param_importance.html"))
#         print("[INFO] Visualization plots saved as HTML files in logs folder.")
#     except:
#         print("[INFO] Install 'plotly' to generate interactive HTML plots.")
