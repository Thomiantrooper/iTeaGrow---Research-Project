import torch
import numpy as np
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
from tqdm import tqdm
import os

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
MODEL_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity\torch_file\tea_maturity_shufflenetv2_final.pth"
TEST_DIR   = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity\dataset\test"
SAVE_DIR   = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\Graph-Confusion-Metrix-Combined"

os.makedirs(SAVE_DIR, exist_ok=True)

IMG_SIZE = 224
BATCH = 1

# Transforms & dataset
transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406], [0.229,0.224,0.225])
])
test_dataset = datasets.ImageFolder(TEST_DIR, transform=transform)
test_loader  = DataLoader(test_dataset, batch_size=BATCH, shuffle=False)

# Load model
model = models.shufflenet_v2_x1_0(weights=None)
in_features = model.fc.in_features
model.fc = torch.nn.Sequential(torch.nn.Dropout(0.45), torch.nn.Linear(in_features, 4))
model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
model.to(DEVICE)
model.eval()

# Collect predictions
y_true, y_pred = [], []
for inputs, labels in tqdm(test_loader, desc="Evaluating"):
    inputs, labels = inputs.to(DEVICE), labels.to(DEVICE)
    with torch.no_grad():
        outputs = model(inputs)
        preds = outputs.argmax(1)
    y_true.append(labels.item())
    y_pred.append(preds.item())

# Save predictions
np.save(os.path.join(SAVE_DIR, "y_true_shuffle.npy"), y_true)
np.save(os.path.join(SAVE_DIR, "y_pred_shuffle.npy"), y_pred)

print(f"[INFO] Predictions saved to {SAVE_DIR}")
