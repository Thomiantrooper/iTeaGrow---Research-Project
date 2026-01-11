# Step-by-Step Training Workflow

## 📍 You Are Here

Your project is at: `C:\Users\lenovo\OneDrive\Desktop\Disease\`

---

## 🎯 Complete Workflow (Copy & Paste)

### Step 1: Create Data Folder Structure

```powershell
# Create the raw_data folder
mkdir C:\Users\lenovo\OneDrive\Desktop\Disease\raw_data\images
mkdir C:\Users\lenovo\OneDrive\Desktop\Disease\raw_data\labels
```

After running this, you have:
```
C:\Users\lenovo\OneDrive\Desktop\Disease\
└── raw_data\
    ├── images\      ← PUT YOUR .JPG AND .PNG FILES HERE
    └── labels\      ← PUT YOUR .TXT LABEL FILES HERE
```

---

### Step 2: Add Your Images and Labels

#### Option A: If you have images but no labels yet

**Use Roboflow (Easiest):**
1. Go to https://roboflow.com/
2. Create free account
3. Create new project → Select "Object Detection"
4. Upload images from `raw_data/images/`
5. Annotate by drawing boxes and selecting disease type
6. Export as "YOLO Ultralytics" format
7. Download and extract to `raw_data/labels/`

**Or use LabelImg (Local):**
```powershell
# Install
pip install labelImg

# Run
labelImg

# Then:
# - File → Open Dir → Select raw_data/images/
# - Select "YOLO" format in menu
# - Draw boxes around diseases
# - Save (creates .txt files in same folder)
```

#### Option B: If you already have images with labels

Just copy them to:
```
raw_data/
├── images/
│   ├── image1.jpg
│   ├── image2.jpg
│   └── ...
└── labels/
    ├── image1.txt
    ├── image2.txt
    └── ...
```

---

### Step 3: Verify Your Data

```powershell
# Count files (should be equal)
(Get-ChildItem C:\Users\lenovo\OneDrive\Desktop\Disease\raw_data\images\ | Measure-Object).Count
(Get-ChildItem C:\Users\lenovo\OneDrive\Desktop\Disease\raw_data\labels\ | Measure-Object).Count

# View a label file (should show: class_id x y w h)
Get-Content C:\Users\lenovo\OneDrive\Desktop\Disease\raw_data\labels\image1.txt
```

Example output:
```
0 0.45 0.52 0.3 0.4
1 0.72 0.35 0.2 0.25
```

---

### Step 4: Prepare Dataset

```powershell
# Navigate to project
cd C:\Users\lenovo\OneDrive\Desktop\Disease

# Activate virtual environment
.\disease_env\Scripts\Activate.ps1

# Run preparation script
python scripts/prepare_dataset.py `
  --input raw_data/ `
  --output datasets/tealeaf/

# Expected output:
# train: 80 images, 80 labels
# val: 10 images, 10 labels
# test: 10 images, 10 labels
```

Check what was created:
```
datasets/tealeaf/
├── train/
│   ├── images/ (80% of your images)
│   └── labels/ (matching labels)
├── val/
│   ├── images/ (10% of your images)
│   └── labels/
├── test/
│   ├── images/ (10% of your images)
│   └── labels/
└── data.yaml  ← IMPORTANT CONFIG FILE
```

View the config:
```powershell
Get-Content datasets/tealeaf/data.yaml
```

Should show:
```yaml
path: /absolute/path/to/datasets/tealeaf
train: train/images
val: val/images
test: test/images
nc: 3
names: ['healthy', 'red_rust', 'blister_blight']
```

---

### Step 5: Train the Model

#### Quick Start (Fast, 30-60 minutes):
```powershell
python scripts/train.py `
  --data datasets/tealeaf/data.yaml `
  --epochs 50 `
  --batch 8
```

#### Standard Training (1-2 hours):
```powershell
python scripts/train.py `
  --data datasets/tealeaf/data.yaml `
  --epochs 100 `
  --batch 16 `
  --augment
```

#### Production Training (2-4 hours, export ONNX):
```powershell
python scripts/train.py `
  --data datasets/tealeaf/data.yaml `
  --epochs 100 `
  --batch 16 `
  --augment `
  --patience 50 `
  --export-onnx
```

#### GPU Training (if you have NVIDIA GPU):
```powershell
python scripts/train.py `
  --data datasets/tealeaf/data.yaml `
  --epochs 100 `
  --batch 16 `
  --device 0 `
  --augment `
  --export-onnx
```

#### CPU Training (slower, no GPU needed):
```powershell
python scripts/train.py `
  --data datasets/tealeaf/data.yaml `
  --epochs 100 `
  --batch 8 `
  --device cpu `
  --workers 2
```

**During training, you'll see:**
```
Epoch 1/100: 100%|██████████| Loss: 2.34 | Acc: 0.65
Epoch 2/100: 100%|██████████| Loss: 1.87 | Acc: 0.75
...
Training completed!
Best weights saved to: runs/train/tealeaf/weights/best.pt
```

---

### Step 6: Monitor Training Results

While training is running or after it finishes:

```powershell
# View all training outputs
ls runs/train/tealeaf/

# View metrics log
Get-Content runs/train/tealeaf/results.csv

# Open training plot (on Windows)
start runs/train/tealeaf/results.png
```

Files you'll see:
```
runs/train/tealeaf/
├── weights/
│   ├── best.pt         ← BEST MODEL (use this)
│   ├── last.pt
│   └── epoch50.pt
├── results.csv         ← METRICS TABLE
├── results.png         ← TRAINING CURVES
├── confusion_matrix.png ← ERRORS BY CLASS
├── F1_curve.png
├── PR_curve.png
└── ...
```

---

### Step 7: Deploy New Model

If you used `--export-onnx`, the model is automatically copied:

```
models/
├── yolov8n_tealeaf.pt
└── yolov8n_tealeaf.onnx
```

**Restart the API to use new model:**

```powershell
# Kill running server
Get-Process python | Stop-Process -Force

# Start fresh (will load new model)
.\disease_env\Scripts\Activate.ps1
uvicorn src.main:app --reload
```

Check it's working:
```powershell
curl http://127.0.0.1:8000/health
```

---

## 🎬 Complete Example (Minimal Dataset)

Quick test with 10 images:

```powershell
# 1. Create folders
mkdir raw_data\images, raw_data\labels

# 2. Copy 10 tea leaf images to raw_data/images/

# 3. Create labels (quick test - all healthy)
for ($i=1; $i -le 10; $i++) {
    "0 0.5 0.5 0.9 0.9" | Out-File "raw_data\labels\image$i.txt"
}

# 4. Prepare
python scripts/prepare_dataset.py --input raw_data/ --output datasets/tealeaf/

# 5. Train (fast)
python scripts/train.py --data datasets/tealeaf/data.yaml --epochs 10 --batch 4

# 6. Results
ls runs/train/tealeaf/weights/
```

---

## 📊 Expected Results

### Good Training:
- ✅ Loss decreases each epoch
- ✅ mAP50 > 0.5 after 50 epochs
- ✅ No overfitting (val loss similar to train loss)
- ✅ All classes detected (confusion matrix diagonal)

### Poor Training:
- ❌ Loss stays high or increases
- ❌ mAP50 < 0.3 after 50 epochs
- ❌ Validation loss >> Training loss (overfitting)
- ❌ One class always misclassified

**If poor:** Add more images, fix labels, or increase epochs

---

## 🔧 Troubleshooting

### "FileNotFoundError: No such file or directory"
```
Check: 
- Image files are in raw_data/images/
- Label files are in raw_data/labels/
- Filenames match (image1.jpg ↔ image1.txt)
```

### "CUDA out of memory"
```powershell
# Reduce batch size
python scripts/train.py --batch 4 ...
```

### "Training is very slow"
```powershell
# Use GPU if available
python scripts/train.py --device 0 ...

# Or reduce images temporarily
ls raw_data/images/ | Get-Random -Count 50 | # Use only 50 images
```

### "data.yaml not found"
```
Ensure:
- prepare_dataset.py ran successfully
- Check datasets/tealeaf/ exists
- Verify data.yaml is in datasets/tealeaf/
```

---

## 📁 Final Directory Structure

After everything:

```
C:\Users\lenovo\OneDrive\Desktop\Disease\
├── raw_data/                    ← YOUR ORIGINAL IMAGES
│   ├── images/
│   └── labels/
├── datasets/tealeaf/            ← SPLIT TRAINING DATA
│   ├── train/images & labels
│   ├── val/images & labels
│   ├── test/images & labels
│   └── data.yaml
├── runs/train/tealeaf/          ← TRAINING OUTPUTS
│   └── weights/
│       ├── best.pt
│       ├── last.pt
│       └── ...
├── models/                      ← PRODUCTION MODELS
│   ├── yolov8n_tealeaf.pt       ← NEW MODEL
│   └── yolov8n_tealeaf.onnx
├── src/
├── scripts/
│   ├── train.py
│   └── prepare_dataset.py
└── ...
```

---

## ✅ Checklist

- [ ] Virtual environment activated
- [ ] Images in `raw_data/images/`
- [ ] Labels in `raw_data/labels/` (matching names)
- [ ] Labels in correct YOLO format
- [ ] `prepare_dataset.py` ran successfully
- [ ] `data.yaml` created in `datasets/tealeaf/`
- [ ] Training started with `train.py`
- [ ] Monitor `runs/train/tealeaf/results.png`
- [ ] Best model saved to `models/`
- [ ] API restarted with new model

---

**You're ready to train!** 🚀

Start with Step 1 and follow through. You'll have a trained model in a few hours!
