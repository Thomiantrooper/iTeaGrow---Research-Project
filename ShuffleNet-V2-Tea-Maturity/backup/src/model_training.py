# # ======= ShuffleNetV2 Tea Maturity =======
# # Author: Kanzurrizk M R A
# # Component: Classify tea leaf maturity using ShuffleNetV2 (4 classes: Assamica/DT1 × tender/matured)

# import os
# import numpy as np
# import matplotlib.pyplot as plt
# import seaborn as sns
# from tqdm import tqdm

# import torch
# import torch.nn as nn
# import torch.optim as optim
# from torch.utils.data import DataLoader
# from torchvision import transforms, datasets, models

# from sklearn.utils.class_weight import compute_class_weight
# from sklearn.metrics import confusion_matrix, classification_report

# # ============================
# # 0. TRAIN/MAIN FUNCTION
# # ============================
# def main():
#     # ----------------------------
#     # Device
#     # ----------------------------
#     DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
#     print(f"[INFO] Using device: {DEVICE}")

#     # ----------------------------
#     # Paths
#     # ----------------------------
#     BASE_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"
#     MODEL_PATH = os.path.join(BASE_DIR, "torch_file/tea_maturity_shufflenetv2_final.pth")
#     TRAIN_DIR = os.path.join(BASE_DIR, "dataset/train")
#     VAL_DIR   = os.path.join(BASE_DIR, "dataset/valid")
#     TEST_DIR  = os.path.join(BASE_DIR, "dataset/test")

#     # ----------------------------
#     # Hyperparameters
#     # ----------------------------
#     IMG_SIZE = 224
#     BATCH = 32
#     NUM_CLASSES = 4
#     EPOCHS_HEAD = 12
#     EPOCHS_FINE = 6

#     # ----------------------------
#     # Transforms
#     # ----------------------------
#     train_transforms = transforms.Compose([
#         transforms.Resize((IMG_SIZE, IMG_SIZE)),
#         transforms.RandomRotation(20),
#         transforms.RandomHorizontalFlip(),
#         transforms.RandomResizedCrop(IMG_SIZE, scale=(0.8, 1.0)),
#         transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
#         transforms.ToTensor(),
#         transforms.Normalize([0.485, 0.456, 0.406],
#                              [0.229, 0.224, 0.225])
#     ])

#     val_transforms = transforms.Compose([
#         transforms.Resize((IMG_SIZE, IMG_SIZE)),
#         transforms.ToTensor(),
#         transforms.Normalize([0.485, 0.456, 0.406],
#                              [0.229, 0.224, 0.225])
#     ])

#     # ----------------------------
#     # Datasets & Dataloaders
#     # ----------------------------
#     train_dataset = datasets.ImageFolder(root=TRAIN_DIR, transform=train_transforms)
#     val_dataset   = datasets.ImageFolder(root=VAL_DIR, transform=val_transforms)
#     test_dataset  = datasets.ImageFolder(root=TEST_DIR, transform=val_transforms)

#     num_workers = 0 if DEVICE.type == 'cpu' else 4  # avoid Windows multiprocessing issue on CPU

#     train_loader = DataLoader(train_dataset, batch_size=BATCH, shuffle=True, num_workers=num_workers, pin_memory=(DEVICE.type=='cuda'))
#     val_loader   = DataLoader(val_dataset, batch_size=BATCH, shuffle=False, num_workers=num_workers, pin_memory=(DEVICE.type=='cuda'))
#     test_loader  = DataLoader(test_dataset, batch_size=1, shuffle=False, num_workers=num_workers, pin_memory=(DEVICE.type=='cuda'))

#     # # ----------------------------
#     # # Class Weights
#     # # ----------------------------
#     # def compute_weights(dataset, device, num_classes):
#     #     labels = [label for _, label in dataset]
#     #     classes = np.arange(num_classes)
#     #     weights = compute_class_weight('balanced', classes=classes, y=labels)
#     #     return torch.tensor(weights, dtype=torch.float).to(device)

#     # class_weights = compute_weights(train_dataset, DEVICE, NUM_CLASSES)
#     # print(f"[INFO] Class weights: {class_weights.cpu().numpy()}")

#     # ----------------------------
#     # Class Weights
#     # ----------------------------
#     def compute_weights(dataset, device):
#         labels = [label for _, label in dataset]
#         classes = np.unique(labels)  # only the classes actually present
#         weights = compute_class_weight('balanced', classes=classes, y=labels)
#         # Create a tensor of length NUM_CLASSES, fill missing class weights with 1.0
#         full_weights = torch.ones(NUM_CLASSES, dtype=torch.float)
#         for i, cls in enumerate(classes):
#             full_weights[cls] = weights[i]
#         return full_weights.to(device)

#     class_weights = compute_weights(train_dataset, DEVICE)
#     print(f"[INFO] Class weights: {class_weights.cpu().numpy()}")


#     # ----------------------------
#     # Model
#     # ----------------------------
#     print("[INFO] Building ShuffleNetV2 model...")
#     model = models.shufflenet_v2_x1_0(weights=models.ShuffleNet_V2_X1_0_Weights.DEFAULT)

#     in_features = model.fc.in_features
#     model.fc = nn.Sequential(
#         nn.Dropout(0.45),
#         nn.Linear(in_features, NUM_CLASSES)
#     )
#     model = model.to(DEVICE)

#     criterion = nn.CrossEntropyLoss(weight=class_weights)
#     optimizer = optim.Adam(model.parameters(), lr=1e-4)

#     # ----------------------------
#     # Training Functions
#     # ----------------------------
#     def train_epoch(model, loader, criterion, optimizer):
#         model.train()
#         running_loss, running_corrects = 0.0, 0
#         for inputs, labels in tqdm(loader, desc="Training", leave=False):
#             inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
#             optimizer.zero_grad()
#             outputs = model(inputs)
#             loss = criterion(outputs, labels)
#             loss.backward()
#             optimizer.step()
#             running_loss += loss.item() * inputs.size(0)
#             running_corrects += (outputs.argmax(1) == labels).sum().item()
#         return running_loss / len(loader.dataset), running_corrects / len(loader.dataset)

#     def validate_epoch(model, loader, criterion):
#         model.eval()
#         running_loss, running_corrects = 0.0, 0
#         with torch.no_grad():
#             for inputs, labels in tqdm(loader, desc="Validation", leave=False):
#                 inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
#                 outputs = model(inputs)
#                 loss = criterion(outputs, labels)
#                 running_loss += loss.item() * inputs.size(0)
#                 running_corrects += (outputs.argmax(1) == labels).sum().item()
#         return running_loss / len(loader.dataset), running_corrects / len(loader.dataset)

#     # ----------------------------
#     # Stage 1: Train Head Only
#     # ----------------------------
#     for name, param in model.named_parameters():
#         if "fc" not in name:
#             param.requires_grad = False

#     history = {'train_acc': [], 'val_acc': [], 'train_loss': [], 'val_loss': []}

#     print("\n=== Stage 1: Training Head Only ===")
#     for epoch in range(EPOCHS_HEAD):
#         train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer)
#         val_loss, val_acc     = validate_epoch(model, val_loader, criterion)
#         history['train_acc'].append(train_acc)
#         history['val_acc'].append(val_acc)
#         history['train_loss'].append(train_loss)
#         history['val_loss'].append(val_loss)
#         print(f"Epoch [{epoch+1}/{EPOCHS_HEAD}] Train Acc: {train_acc:.4f}, Val Acc: {val_acc:.4f}")

#     # ----------------------------
#     # Stage 2: Fine-Tune Last 15 Layers
#     # ----------------------------
#     print("\n=== Stage 2: Fine-Tuning Last 15 Layers ===")
#     backbone_params = [p for name, p in model.named_parameters() if "fc" not in name]
#     for param in backbone_params[-15:]:
#         param.requires_grad = True

#     optimizer = optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-5)
#     # scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=2, verbose=True)
#     scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=2)

#     for epoch in range(EPOCHS_FINE):
#         train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer)
#         val_loss, val_acc     = validate_epoch(model, val_loader, criterion)
#         scheduler.step(val_loss)
#         history['train_acc'].append(train_acc)
#         history['val_acc'].append(val_acc)
#         history['train_loss'].append(train_loss)
#         history['val_loss'].append(val_loss)
#         print(f"Epoch [{epoch+1}/{EPOCHS_FINE}] Train Acc: {train_acc:.4f}, Val Acc: {val_acc:.4f}")

#     # ----------------------------
#     # Save Model
#     # ----------------------------
#     os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
#     torch.save(model.state_dict(), MODEL_PATH)
#     print(f"[INFO] Model saved to: {MODEL_PATH}")

#     # ----------------------------
#     # Evaluation
#     # ----------------------------
#     model.eval()
#     y_true, y_pred = [], []
#     with torch.no_grad():
#         for inputs, labels in tqdm(test_loader, desc="Testing"):
#             inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
#             outputs = model(inputs)
#             preds = outputs.argmax(1)
#             y_true.append(labels.item())
#             y_pred.append(preds.item())

#     cm = confusion_matrix(y_true, y_pred)
#     print("\nConfusion Matrix:\n", cm)
#     print("\nClassification Report:\n", classification_report(y_true, y_pred, target_names=train_dataset.classes))

#     plt.figure(figsize=(6,5))
#     sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=train_dataset.classes, yticklabels=train_dataset.classes)
#     plt.xlabel("Predicted")
#     plt.ylabel("Actual")
#     plt.title("Confusion Matrix")
#     plt.show()

#     # ----------------------------
#     # Plot Training History
#     # ----------------------------
#     plt.figure()
#     plt.plot(history['train_acc'], label='Train Acc')
#     plt.plot(history['val_acc'], label='Val Acc')
#     plt.title("Training & Validation Accuracy")
#     plt.xlabel("Epochs")
#     plt.ylabel("Accuracy")
#     plt.grid(True)
#     plt.legend()
#     plt.show()

#     print("\n[INFO] Training complete.")

# # ============================
# # Windows Multiprocessing Safe Entry
# # ============================
# if __name__ == "__main__":
#     main()





# # ======= ShuffleNetV2 Tea Maturity =======
# # Author: Kanzurrizk M R A
# # Component: Classify tea leaf maturity using ShuffleNetV2 (4 classes: Assamica/DT1 × tender/matured)

# import os
# import numpy as np
# import matplotlib.pyplot as plt
# import seaborn as sns
# from tqdm import tqdm

# import torch
# import torch.nn as nn
# import torch.optim as optim
# from torch.utils.data import DataLoader
# from torchvision import transforms, datasets, models

# from sklearn.utils.class_weight import compute_class_weight
# from sklearn.metrics import confusion_matrix, classification_report

# # ============================
# # 0. TRAIN/MAIN FUNCTION
# # ============================
# def main():
#     # ----------------------------
#     # Device
#     # ----------------------------
#     DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
#     print(f"[INFO] Using device: {DEVICE}")

#     # ----------------------------
#     # Paths
#     # ----------------------------
#     BASE_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"
#     MODEL_PATH = os.path.join(BASE_DIR, "torch_file/tea_maturity_shufflenetv2_final.pth")
#     TRAIN_DIR = os.path.join(BASE_DIR, "dataset/train")
#     VAL_DIR   = os.path.join(BASE_DIR, "dataset/valid")
#     TEST_DIR  = os.path.join(BASE_DIR, "dataset/test")

#     # ----------------------------
#     # Hyperparameters
#     # ----------------------------
#     IMG_SIZE = 224
#     BATCH = 32
#     NUM_CLASSES = 4
#     EPOCHS_HEAD = 12
#     EPOCHS_FINE = 6

#     # ----------------------------
#     # Transforms
#     # ----------------------------
#     train_transforms = transforms.Compose([
#         transforms.Resize((IMG_SIZE, IMG_SIZE)),
#         transforms.RandomRotation(20),
#         transforms.RandomHorizontalFlip(),
#         transforms.RandomResizedCrop(IMG_SIZE, scale=(0.8, 1.0)),
#         transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
#         transforms.ToTensor(),
#         transforms.Normalize([0.485, 0.456, 0.406],
#                              [0.229, 0.224, 0.225])
#     ])

#     val_transforms = transforms.Compose([
#         transforms.Resize((IMG_SIZE, IMG_SIZE)),
#         transforms.ToTensor(),
#         transforms.Normalize([0.485, 0.456, 0.406],
#                              [0.229, 0.224, 0.225])
#     ])

#     # ----------------------------
#     # Datasets & Dataloaders
#     # ----------------------------
#     train_dataset = datasets.ImageFolder(root=TRAIN_DIR, transform=train_transforms)
#     val_dataset   = datasets.ImageFolder(root=VAL_DIR, transform=val_transforms)
#     test_dataset  = datasets.ImageFolder(root=TEST_DIR, transform=val_transforms)

#     num_workers = 0 if DEVICE.type == 'cpu' else 4  # avoid Windows multiprocessing issue on CPU

#     train_loader = DataLoader(train_dataset, batch_size=BATCH, shuffle=True, num_workers=num_workers, pin_memory=(DEVICE.type=='cuda'))
#     val_loader   = DataLoader(val_dataset, batch_size=BATCH, shuffle=False, num_workers=num_workers, pin_memory=(DEVICE.type=='cuda'))
#     test_loader  = DataLoader(test_dataset, batch_size=1, shuffle=False, num_workers=num_workers, pin_memory=(DEVICE.type=='cuda'))

#     # # ----------------------------
#     # # Class Weights
#     # # ----------------------------
#     # def compute_weights(dataset, device, num_classes):
#     #     labels = [label for _, label in dataset]
#     #     classes = np.arange(num_classes)
#     #     weights = compute_class_weight('balanced', classes=classes, y=labels)
#     #     return torch.tensor(weights, dtype=torch.float).to(device)

#     # class_weights = compute_weights(train_dataset, DEVICE, NUM_CLASSES)
#     # print(f"[INFO] Class weights: {class_weights.cpu().numpy()}")

#     # ----------------------------
#     # Class Weights
#     # ----------------------------
#     def compute_weights(dataset, device):
#         labels = [label for _, label in dataset]
#         classes = np.unique(labels)  # only the classes actually present
#         weights = compute_class_weight('balanced', classes=classes, y=labels)
#         # Create a tensor of length NUM_CLASSES, fill missing class weights with 1.0
#         full_weights = torch.ones(NUM_CLASSES, dtype=torch.float)
#         for i, cls in enumerate(classes):
#             full_weights[cls] = weights[i]
#         return full_weights.to(device)

#     class_weights = compute_weights(train_dataset, DEVICE)
#     print(f"[INFO] Class weights: {class_weights.cpu().numpy()}")


#     # ----------------------------
#     # Model
#     # ----------------------------
#     print("[INFO] Building ShuffleNetV2 model...")
#     model = models.shufflenet_v2_x1_0(weights=models.ShuffleNet_V2_X1_0_Weights.DEFAULT)

#     in_features = model.fc.in_features
#     model.fc = nn.Sequential(
#         nn.Dropout(0.45),
#         nn.Linear(in_features, NUM_CLASSES)
#     )
#     model = model.to(DEVICE)

#     criterion = nn.CrossEntropyLoss(weight=class_weights)
#     optimizer = optim.Adam(model.parameters(), lr=1e-4)

#     # ----------------------------
#     # Training Functions
#     # ----------------------------
#     def train_epoch(model, loader, criterion, optimizer):
#         model.train()
#         running_loss, running_corrects = 0.0, 0
#         for inputs, labels in tqdm(loader, desc="Training", leave=False):
#             inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
#             optimizer.zero_grad()
#             outputs = model(inputs)
#             loss = criterion(outputs, labels)
#             loss.backward()
#             optimizer.step()
#             running_loss += loss.item() * inputs.size(0)
#             running_corrects += (outputs.argmax(1) == labels).sum().item()
#         return running_loss / len(loader.dataset), running_corrects / len(loader.dataset)

#     def validate_epoch(model, loader, criterion):
#         model.eval()
#         running_loss, running_corrects = 0.0, 0
#         with torch.no_grad():
#             for inputs, labels in tqdm(loader, desc="Validation", leave=False):
#                 inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
#                 outputs = model(inputs)
#                 loss = criterion(outputs, labels)
#                 running_loss += loss.item() * inputs.size(0)
#                 running_corrects += (outputs.argmax(1) == labels).sum().item()
#         return running_loss / len(loader.dataset), running_corrects / len(loader.dataset)

#     # ----------------------------
#     # Stage 1: Train Head Only
#     # ----------------------------
#     for name, param in model.named_parameters():
#         if "fc" not in name:
#             param.requires_grad = False

#     history = {'train_acc': [], 'val_acc': [], 'train_loss': [], 'val_loss': []}

#     print("\n=== Stage 1: Training Head Only ===")
#     for epoch in range(EPOCHS_HEAD):
#         train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer)
#         val_loss, val_acc     = validate_epoch(model, val_loader, criterion)
#         history['train_acc'].append(train_acc)
#         history['val_acc'].append(val_acc)
#         history['train_loss'].append(train_loss)
#         history['val_loss'].append(val_loss)
#         print(f"Epoch [{epoch+1}/{EPOCHS_HEAD}] Train Acc: {train_acc:.4f}, Val Acc: {val_acc:.4f}")

#     # ----------------------------
#     # Stage 2: Fine-Tune Last 15 Layers
#     # ----------------------------
#     print("\n=== Stage 2: Fine-Tuning Last 15 Layers ===")
#     backbone_params = [p for name, p in model.named_parameters() if "fc" not in name]
#     for param in backbone_params[-15:]:
#         param.requires_grad = True

#     optimizer = optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-5)
#     # scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=2, verbose=True)
#     scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=2)

#     for epoch in range(EPOCHS_FINE):
#         train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer)
#         val_loss, val_acc     = validate_epoch(model, val_loader, criterion)
#         scheduler.step(val_loss)
#         history['train_acc'].append(train_acc)
#         history['val_acc'].append(val_acc)
#         history['train_loss'].append(train_loss)
#         history['val_loss'].append(val_loss)
#         print(f"Epoch [{epoch+1}/{EPOCHS_FINE}] Train Acc: {train_acc:.4f}, Val Acc: {val_acc:.4f}")

#     # ----------------------------
#     # Save Model
#     # ----------------------------
#     os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
#     torch.save(model.state_dict(), MODEL_PATH)
#     print(f"[INFO] Model saved to: {MODEL_PATH}")

#     # ----------------------------
#     # Evaluation
#     # ----------------------------
#     model.eval()
#     y_true, y_pred = [], []
#     with torch.no_grad():
#         for inputs, labels in tqdm(test_loader, desc="Testing"):
#             inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
#             outputs = model(inputs)
#             preds = outputs.argmax(1)
#             y_true.append(labels.item())
#             y_pred.append(preds.item())

#     cm = confusion_matrix(y_true, y_pred)
#     print("\nConfusion Matrix:\n", cm)
#     print("\nClassification Report:\n", classification_report(y_true, y_pred, target_names=train_dataset.classes))

#     plt.figure(figsize=(6,5))
#     sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=train_dataset.classes, yticklabels=train_dataset.classes)
#     plt.xlabel("Predicted")
#     plt.ylabel("Actual")
#     plt.title("Confusion Matrix")
#     plt.show()

#     # ----------------------------
#     # Plot Training History
#     # ----------------------------
#     plt.figure()
#     plt.plot(history['train_acc'], label='Train Acc')
#     plt.plot(history['val_acc'], label='Val Acc')
#     plt.title("Training & Validation Accuracy")
#     plt.xlabel("Epochs")
#     plt.ylabel("Accuracy")
#     plt.grid(True)
#     plt.legend()
#     plt.show()

#     print("\n[INFO] Training complete.")

# # ============================
# # Windows Multiprocessing Safe Entry
# # ============================
# if __name__ == "__main__":
#     main()



