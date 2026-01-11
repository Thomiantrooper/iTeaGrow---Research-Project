"""
SHUFFLENETV2 HYPERPARAMETER TUNER
============================================================

"""

import os
import json
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import models
import optuna
from optuna.trial import TrialState
from tqdm import tqdm
import copy

# Import pipeline
try:
    from preprocessing import create_data_loaders, CLASS_MAP, set_seed
except ImportError:
    raise ImportError("CRITICAL ERROR: Could not import 'preprocessing.py'.")

# ==============================================================================
#   1. CONFIGURATION
# ==============================================================================
class TuneConfig:
    PROJECT_NAME = "tea_shufflenet_constrained"  # Changed name to separate from previous high-acc study
    N_TRIALS = 30
    EPOCHS_HEAD = 6
    EPOCHS_FINE = 8
    BATCH_SIZE = 32
    DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
    
    BASE_LOG_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity\tuning_results_constrained"
    DB_NAME = "tea_tuning_constrained.db"

os.makedirs(TuneConfig.BASE_LOG_DIR, exist_ok=True)

# ==============================================================================
#   2. GLOBAL DATA LOADING
# ==============================================================================
print(f"[INFO] Loading data globally for tuning on {TuneConfig.DEVICE}...")
set_seed(42)
train_loader, val_loader, _, _, _, _ = create_data_loaders(batch_size=TuneConfig.BATCH_SIZE)

# ==============================================================================
#   3. LOGGING UTILITIES
# ==============================================================================
def save_trial_results(trial, params, accuracy, model):
    trial_dir = os.path.join(TuneConfig.BASE_LOG_DIR, f"trial_{trial.number:02d}")
    os.makedirs(trial_dir, exist_ok=True)
    
    results = {
        "trial_id": trial.number,
        "status": "COMPLETED",
        "val_accuracy": float(accuracy),
        "hyperparameters": params
    }
    with open(os.path.join(trial_dir, "trial.json"), "w") as f:
        json.dump(results, f, indent=4)
    torch.save(model.state_dict(), os.path.join(trial_dir, "checkpoint.pth"))

def print_trial_report(trial, acc, best_so_far):
    print("\n" + "-"*50)
    print(f"TRIAL {trial.number:02d} SUMMARY (CONSTRAINED MODE)")
    print("-" * 50)
    print(f"{'Hyperparameter':<20} | {'Value'}")
    print("-" * 50)
    for k, v in trial.params.items():
        if "lr" in k or "decay" in k:
            print(f"{k:<20} | {v:.2e}")
        else:
            print(f"{k:<20} | {v:.4f}")
    print("-" * 50)
    print(f"{'Validation Acc':<20} | {acc*100:.2f}%")
    print("-" * 50)
    print(f" BEST SO FAR: {best_so_far*100:.2f}%")
    print("-" * 50 + "\n")

# ==============================================================================
#   4. THE TRIAL LOOP
# ==============================================================================
def objective(trial):
    # --- A. AGGRESSIVE Search Space (The "Brakes") ---
    # 1. High Dropout: 0.5 to 0.8 (Forces model to struggle)
    dropout = trial.suggest_float("dropout", 0.5, 0.8, step=0.05)
    
    # 2. Strong Weight Decay: 1e-4 to 1e-2 (Penalizes complex learning)
    weight_decay = trial.suggest_float("weight_decay", 1e-4, 1e-2, log=True)
    
    # 3. Standard Learning Rates
    lr_head = trial.suggest_float("lr_head", 1e-4, 5e-3, log=True)
    
    # 4. Lower Fine-Tuning LR (Slows down adaptation of the brain)
    lr_fine = trial.suggest_float("lr_fine", 1e-7, 5e-5, log=True)

    # --- B. Build Model ---
    model = models.shufflenet_v2_x1_0(weights="DEFAULT")
    model.fc = nn.Sequential(
        nn.Dropout(dropout),
        nn.Linear(model.fc.in_features, len(CLASS_MAP))
    )
    model = model.to(TuneConfig.DEVICE)
    criterion = nn.CrossEntropyLoss()

    # --- C. Stage 1: Head Training ---
    print(f"\n[Trial {trial.number}] Stage 1: Warmup ({TuneConfig.EPOCHS_HEAD} Epochs)")
    for param in model.parameters(): param.requires_grad = False
    for param in model.fc.parameters(): param.requires_grad = True
    optimizer = optim.AdamW(model.fc.parameters(), lr=lr_head, weight_decay=weight_decay)

    for epoch in range(TuneConfig.EPOCHS_HEAD):
        t_loss, t_acc = run_epoch(model, train_loader, criterion, optimizer, True, f"  Ep {epoch+1}")
        v_loss, v_acc = run_epoch(model, val_loader, criterion, None, False, "  Validating")
        
        print(f"   -> Loss: {t_loss:.4f} | Acc: {t_acc:.1%} | Val: {v_acc:.1%}")

        trial.report(v_acc, epoch)
        if trial.should_prune():
            print(f"--> [PRUNED] Trial {trial.number} stopped early")
            raise optuna.exceptions.TrialPruned()

    # --- D. Stage 2: Fine-Tuning ---
    print(f"[Trial {trial.number}] Stage 2: Fine-Tuning ({TuneConfig.EPOCHS_FINE} Epochs)")
    for name, param in model.named_parameters():
        if "stage4" in name or "conv5" in name or "fc" in name:
            param.requires_grad = True
    optimizer = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), 
                           lr=lr_fine, weight_decay=weight_decay)
    
    best_val_acc = 0.0
    for epoch in range(TuneConfig.EPOCHS_FINE):
        t_loss, t_acc = run_epoch(model, train_loader, criterion, optimizer, True, f"  Ep {epoch+1}")
        v_loss, v_acc = run_epoch(model, val_loader, criterion, None, False, "  Validating")
        
        print(f"   -> Loss: {t_loss:.4f} | Acc: {t_acc:.1%} | Val: {v_acc:.1%}")

        if v_acc > best_val_acc:
            best_val_acc = v_acc
            
        trial.report(v_acc, TuneConfig.EPOCHS_HEAD + epoch)
        if trial.should_prune():
            print(f"--> [PRUNED] Trial {trial.number} stopped early")
            raise optuna.exceptions.TrialPruned()

    # --- E. Final Report ---
    try:
        study = optuna.load_study(study_name=TuneConfig.PROJECT_NAME, storage=f"sqlite:///{os.path.join(TuneConfig.BASE_LOG_DIR, TuneConfig.DB_NAME)}")
        current_best = max(study.best_value, best_val_acc)
    except:
        current_best = best_val_acc

    save_trial_results(trial, trial.params, best_val_acc, model)
    print_trial_report(trial, best_val_acc, current_best)
    
    return best_val_acc

# ==============================================================================
#   5. HELPERS
# ==============================================================================
def run_epoch(model, loader, criterion, optimizer, is_training, desc):
    model.train() if is_training else model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    loop = tqdm(loader, desc=desc, leave=False, ncols=100)
    
    for inputs, labels in loop:
        inputs, labels = inputs.to(TuneConfig.DEVICE), labels.to(TuneConfig.DEVICE)
        
        if is_training:
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
        else:
            with torch.no_grad():
                outputs = model(inputs)
                loss = criterion(outputs, labels)
        
        preds = outputs.argmax(dim=1)
        correct += (preds == labels).sum().item()
        total += inputs.size(0)
        running_loss += loss.item()
        
        loop.set_postfix(loss=f"{loss.item():.4f}", acc=f"{correct/total:.2%}")
        
    return running_loss / len(loader), correct / total

# ==============================================================================
#   6. RUNNER
# ==============================================================================
if __name__ == "__main__":
    print(f"\n[INFO] Starting Optuna Search ({TuneConfig.N_TRIALS} Trials)...")
    
    db_path = os.path.join(TuneConfig.BASE_LOG_DIR, TuneConfig.DB_NAME)
    storage_url = f"sqlite:///{db_path}"
    
    study = optuna.create_study(
        direction="maximize", 
        storage=storage_url, 
        study_name=TuneConfig.PROJECT_NAME,
        load_if_exists=True
    )
    
    try:
        study.optimize(objective, n_trials=TuneConfig.N_TRIALS)
    except KeyboardInterrupt:
        print("\n[INFO] Paused by user. Results saved.")
    
    print("\n" + "="*60)
    print("FINAL WINNING CONFIGURATION")
    best = study.best_params
    print(f"DROPOUT: {best['dropout']:.2f} | LR_HEAD: {best['lr_head']:.2e}")
    print(f"LR_FINE: {best['lr_fine']:.2e} | WD: {best['weight_decay']:.2e}")
    print(f"BEST ACCURACY: {study.best_value*100:.2f}%")
    print("="*60)