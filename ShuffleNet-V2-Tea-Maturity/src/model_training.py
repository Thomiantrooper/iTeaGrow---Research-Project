"""
==============================================================
SHUFFLENETV2 TRAINING SCRIPT
==============================================================
"""

import os  # Operating system interfaces
import torch  # PyTorch deep learning library
import torch.nn as nn  # Neural network modules
import torch.optim as optim  # Optimization algorithms
from torchvision import models  # Pre-trained models
from tqdm import tqdm  # Progress bar
import seaborn as sns  # Statistical data visualization
import matplotlib.pyplot as plt  # Plotting library
from sklearn.metrics import confusion_matrix, classification_report, roc_curve, auc  # Metrics
from sklearn.preprocessing import label_binarize  # Label binarization for ROC
from itertools import cycle  # Cycle iterator for plotting
import numpy as np  # Numerical operations
import copy  # Object copying
import math  # Mathematical functions

# Import the pipeline
try:
    # Import custom data loader and utilities from preprocessing.py
    from preprocessing import create_data_loaders, CLASS_MAP, set_seed
except ImportError:
    # Raise error if preprocessing module is missing
    raise ImportError("CRITICAL ERROR: Could not import 'preprocessing.py'.")

# ==============================================================================
#   MASTER CONFIGURATION
# ==============================================================================
class Config:
    """
    Centralized configuration for hyperparameters and paths.
    """
    SEED = 42  # Random seed for reproducibility
    DEVICE = "cuda" if torch.cuda.is_available() else "cpu"  # Compute device (GPU/CPU)
    
    # Project Paths
    BASE_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"
    MODEL_SAVE_DIR = os.path.join(BASE_DIR, "torch_file")  # Directory to save models
    MODEL_SAVE_PATH = os.path.join(MODEL_SAVE_DIR, "tea_maturity_shufflenetv2_final.pth")  # Final model path

    # Training Hyperparameters
    BATCH_SIZE = 32  # Batch size
    EPOCHS_HEAD = 12  # Epochs for warming up the head
    LR_HEAD = 4.72e-03  # Learning rate for head training
    EPOCHS_FINE = 25  # Epochs for fine-tuning
    LR_FINE = 2.36e-05  # Learning rate for fine-tuning
    
    # Regularization
    DROPOUT_RATE = 0.55  # Dropout probability
    WEIGHT_DECAY = 1.66e-03  # L2 regularization factor
    EARLY_STOPPING_PATIENCE = 10  # Patience for early stopping
    
# ==============================================================================
#   UTILITIES
# ==============================================================================
class EarlyStopping:
    """
    Early stops the training if validation loss doesn't improve after a given patience.
    """
    def __init__(self, patience=5, min_delta=0):
        self.patience = patience  # Eras to wait for improvement
        self.min_delta = min_delta  # Minimum change to qualify as improvement
        self.counter = 0  # Counter for epochs without improvement
        self.best_loss = None  # Best validation loss observed
        self.early_stop = False  # Flag to trigger stopping

    def __call__(self, val_loss):
        """
        Call method updates the internal state based on current validation loss.
        """
        if self.best_loss is None:
            self.best_loss = val_loss
        elif val_loss > self.best_loss - self.min_delta:
            # Loss did not improve significantly
            self.counter += 1
            if self.counter >= self.patience:
                self.early_stop = True
        else:
            # Loss improved
            self.best_loss = val_loss
            self.counter = 0

def calculate_confidence_interval(accuracy, n_samples, confidence=0.95):
    """
    Calculates the 95% confidence interval for classification accuracy.
    """
    z_score = 1.96  # Z-score for 95% confidence
    # Standard Error = sqrt( (p * (1-p)) / n )
    error_margin = z_score * math.sqrt((accuracy * (1 - accuracy)) / n_samples)
    return error_margin

def run_epoch(model, loader, criterion, optimizer, device, is_training=True):
    """
    Executes one epoch of training or validation.
    """
    # Set model mode
    model.train() if is_training else model.eval()
    
    running_loss = 0.0
    correct_preds = 0
    total_samples = 0
    
    # Enable gradients only for training
    context = torch.enable_grad() if is_training else torch.no_grad()
    
    with context:
        # Create progress bar
        loop = tqdm(loader, desc="Training" if is_training else "Validation", leave=False)
        for inputs, labels in loop:
            # Move data to device
            inputs, labels = inputs.to(device), labels.to(device)
            
            if is_training:
                # Zero gradients
                optimizer.zero_grad()
                # Forward pass
                outputs = model(inputs)
                # Compute loss
                loss = criterion(outputs, labels)
                # Backward pass
                loss.backward()
                # Update weights
                optimizer.step()
            else:
                # Forward pass (no grad)
                outputs = model(inputs)
                # Compute loss
                loss = criterion(outputs, labels)
            
            # Accumulate stats
            running_loss += loss.item() * inputs.size(0)
            preds = outputs.argmax(dim=1)
            correct_preds += (preds == labels).sum().item()
            total_samples += inputs.size(0)
            
            # Update progress bar
            loop.set_postfix(loss=loss.item())
            
    # Return average loss and accuracy
    return running_loss / total_samples, correct_preds / total_samples

# ==============================================================================
#   MAIN EXECUTION
# ==============================================================================
def main():
    # Set random seed
    set_seed(Config.SEED)
    # Ensure save directory exists
    os.makedirs(Config.MODEL_SAVE_DIR, exist_ok=True)
    print(f"\n[INFO] Using device: {Config.DEVICE}")

    # 1. LOAD DATA
    print(f"[INFO] Initializing Data Loaders (Batch: {Config.BATCH_SIZE})...")
    # specific batch size from config
    train_loader, val_loader, test_loader, _, _, _ = create_data_loaders(batch_size=Config.BATCH_SIZE)
    
    # Get class names sorted by index
    class_names = [k for k, v in sorted(CLASS_MAP.items(), key=lambda item: item[1])]
    NUM_CLASSES = len(class_names)
    print(f"[INFO] Classes: {class_names}")

    # 2. BUILD MODEL
    print("[INFO] Building ShuffleNetV2 x1.0...")
    # Load pre-trained ShuffleNetV2
    model = models.shufflenet_v2_x1_0(weights=models.ShuffleNet_V2_X1_0_Weights.DEFAULT)
    
    # Replace the final fully connected layer
    in_features = model.fc.in_features
    model.fc = nn.Sequential(
        nn.Dropout(Config.DROPOUT_RATE),  # Dropout for regularization
        nn.Linear(in_features, NUM_CLASSES)  # New output layer
    )
    # Move model to device
    model = model.to(Config.DEVICE)

    # Loss function (CrossEntropyLoss includes Softmax)
    criterion = nn.CrossEntropyLoss()
    
    # Keep track of best model weights
    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0
    # Dictionary to store training history
    history = {'train_acc': [], 'val_acc': [], 'train_loss': [], 'val_loss': []}

    # 3. STAGE 1: HEAD TRAINING
    print(f"\n{'='*40}\nSTAGE 1: Warmup ({Config.EPOCHS_HEAD} Epochs) @ LR={Config.LR_HEAD}\n{'='*40}")
    # Freeze all parameters except the new fc layer
    for name, param in model.named_parameters():
        if "fc" not in name: param.requires_grad = False
            
    # Optimizer for head only
    optimizer = optim.Adam(model.parameters(), lr=Config.LR_HEAD, weight_decay=Config.WEIGHT_DECAY)

    for epoch in range(Config.EPOCHS_HEAD):
        # Run Training Epoch (Validation mode=False for model.train())
        t_loss, t_acc = run_epoch(model, train_loader, criterion, optimizer, Config.DEVICE, True)
        # Run Validation Epoch
        v_loss, v_acc = run_epoch(model, val_loader, criterion, None, Config.DEVICE, False)
        
        # Store history
        history['train_acc'].append(t_acc)
        history['val_acc'].append(v_acc)
        history['train_loss'].append(t_loss)
        history['val_loss'].append(v_loss)
        
        # Check for improvement
        if v_acc > best_acc:
            best_acc = v_acc
            best_model_wts = copy.deepcopy(model.state_dict())
        
        print(f"Epoch [{epoch+1}/{Config.EPOCHS_HEAD}] Train Acc: {t_acc:.4f} | Val Acc: {v_acc:.4f}")

    # 4. STAGE 2: FINE-TUNING
    print(f"\n{'='*40}\nSTAGE 2: Fine-Tuning ({Config.EPOCHS_FINE} Epochs) @ LR={Config.LR_FINE}\n{'='*40}")
    # Unfreeze deeper layers (stage 4, conv5, and fc)
    for name, param in model.named_parameters():
        if "stage4" in name or "conv5" in name or "fc" in name:
            param.requires_grad = True
            
    # Optimizer for fine-tuning
    optimizer = optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), 
                          lr=Config.LR_FINE, weight_decay=Config.WEIGHT_DECAY)
    # Learning rate scheduler
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.5, patience=2)
    # Early stopping wrapper
    early_stopper = EarlyStopping(patience=Config.EARLY_STOPPING_PATIENCE)

    for epoch in range(Config.EPOCHS_FINE):
        current_epoch = Config.EPOCHS_HEAD + epoch + 1
        
        # Run epochs
        t_loss, t_acc = run_epoch(model, train_loader, criterion, optimizer, Config.DEVICE, True)
        v_loss, v_acc = run_epoch(model, val_loader, criterion, None, Config.DEVICE, False)
        
        # Step scheduler and check early stopping
        scheduler.step(v_acc)
        early_stopper(v_loss)
        
        # Store history
        history['train_acc'].append(t_acc)
        history['val_acc'].append(v_acc)
        history['train_loss'].append(t_loss)
        history['val_loss'].append(v_loss)
        
        # Save best model
        if v_acc > best_acc:
            best_acc = v_acc
            best_model_wts = copy.deepcopy(model.state_dict())
            
        print(f"Fine-Tune [{current_epoch}] Train Acc: {t_acc:.4f} | Val Acc: {v_acc:.4f}")
        
        # Check early stopping condition
        if early_stopper.early_stop:
            print(f"\n[INFO] Early stopping triggered!")
            break

    # 5. FINAL EVALUATION & PLOTS
    print(f"\n[INFO] Loading best weights (Acc: {best_acc:.4f})...")
    # Load best weights
    model.load_state_dict(best_model_wts)
    # Save model to disk
    torch.save(model.state_dict(), Config.MODEL_SAVE_PATH)

    print("\n[INFO] Evaluating on Test Set (Collecting Probabilities)...")
    model.eval()
    y_true = []
    y_pred = []
    y_probs = [] # Need probabilities for ROC
    
    with torch.no_grad():
        for inputs, labels in tqdm(test_loader, desc="Testing"):
            inputs, labels = inputs.to(Config.DEVICE), labels.to(Config.DEVICE)
            outputs = model(inputs)
            
            # Get Probabilities (Softmax)
            probs = torch.softmax(outputs, dim=1)
            preds = outputs.argmax(1)
            
            # Collect results
            y_true.extend(labels.cpu().numpy())
            y_pred.extend(preds.cpu().numpy())
            y_probs.extend(probs.cpu().numpy())

    # Convert to numpy arrays
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    y_probs = np.array(y_probs)

    # --- METRICS REPORT ---
    print("\n" + "="*40 + "\nFINAL RESULTS REPORT\n" + "="*40)
    print(classification_report(y_true, y_pred, target_names=class_names, digits=4))
    
    # Confidence Interval
    final_acc = np.mean(y_true == y_pred)
    ci_margin = calculate_confidence_interval(final_acc, len(y_true))
    print(f"Test Accuracy: {final_acc*100:.2f}% (± {ci_margin*100:.2f}% at 95% Confidence)")

    # --- PLOT 1: Accuracy & Loss History ---
    plt.figure(figsize=(14, 5))
    
    # Accuracy Subplot
    plt.subplot(1, 2, 1)
    plt.plot(history['train_acc'], label='Train Acc', marker='o')
    plt.plot(history['val_acc'], label='Val Acc', marker='o')
    plt.axvline(x=Config.EPOCHS_HEAD, color='r', linestyle='--', label='Fine-Tuning Start')
    plt.title("Model Accuracy over Epochs")
    plt.xlabel("Epoch")
    plt.ylabel("Accuracy")
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)

    # Loss Subplot
    plt.subplot(1, 2, 2)
    plt.plot(history['train_loss'], label='Train Loss', marker='o')
    plt.plot(history['val_loss'], label='Val Loss', marker='o')
    plt.axvline(x=Config.EPOCHS_HEAD, color='r', linestyle='--', label='Fine-Tuning Start')
    plt.title("Model Loss over Epochs")
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()

    # --- PLOT 2: Confusion Matrix ---
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=class_names, yticklabels=class_names)
    plt.title("Confusion Matrix")
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.show()

    # --- PLOT 3: ROC Curves (One-vs-Rest) ---
    # Binarize the output for multiclass ROC
    y_true_bin = label_binarize(y_true, classes=range(NUM_CLASSES))
    
    # Compute ROC curve and ROC area for each class
    fpr = dict()
    tpr = dict()
    roc_auc = dict()
    for i in range(NUM_CLASSES):
        fpr[i], tpr[i], _ = roc_curve(y_true_bin[:, i], y_probs[:, i])
        roc_auc[i] = auc(fpr[i], tpr[i])

    # Compute micro-average ROC curve and ROC area (Optional, good for overall view)
    fpr["micro"], tpr["micro"], _ = roc_curve(y_true_bin.ravel(), y_probs.ravel())
    roc_auc["micro"] = auc(fpr["micro"], tpr["micro"])

    plt.figure(figsize=(10, 8))
    colors = cycle(['blue', 'red', 'green', 'orange'])
    
    # Plot each class ROC
    for i, color in zip(range(NUM_CLASSES), colors):
        plt.plot(fpr[i], tpr[i], color=color, lw=2,
                 label=f'ROC curve: {class_names[i]} (area = {roc_auc[i]:.2f})')

    # Plot Micro Average
    plt.plot(fpr["micro"], tpr["micro"],
             label=f'Micro-average ROC (area = {roc_auc["micro"]:.2f})',
             color='deeppink', linestyle=':', linewidth=4)

    # Plot Random Guess Line
    plt.plot([0, 1], [0, 1], 'k--', lw=2)
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('Receiver Operating Characteristic (ROC) - Multi-Class')
    plt.legend(loc="lower right")
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.show()

if __name__ == "__main__":
    main()