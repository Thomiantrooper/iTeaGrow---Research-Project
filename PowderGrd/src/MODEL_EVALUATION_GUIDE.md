# Model Evaluation & Accuracy Guide

## 📊 Overview

The API now includes **model accuracy** in all prediction responses. This shows the overall performance of the trained model on the test dataset.

---

## 🔍 What is Model Accuracy?

### **Confidence vs Accuracy**

| Metric | Meaning | Scope |
|--------|---------|-------|
| **Confidence** | How certain the model is about THIS single prediction | Per prediction (e.g., 95.67%) |
| **Model Accuracy** | How often the model is correct across ALL test samples | Overall model (e.g., 92.5%) |

**Example Response:**
```json
{
  "grade": "Fanning1",
  "confidence": 95.67,      ← "I'm 95.67% sure this is Fanning1"
  "model_accuracy": 92.5,   ← "I'm correct 92.5% of the time overall"
  "density_status": "Excellent",
  ...
}
```

---

## 🧪 How to Evaluate Your Model

### **Step 1: Run Evaluation Script**

**Requirements:**
- Python with TensorFlow installed (Python 3.9-3.11 recommended)
- Trained model file: `best_model.keras`
- Test dataset in `../data/final`

**Command:**
```powershell
cd src
python evaluate_model.py
```

**What it does:**
1. Loads your trained model
2. Tests it on validation dataset (20% of data)
3. Calculates:
   - Overall accuracy
   - Per-class accuracy (for each tea grade)
   - Test loss
4. Saves results to `model_metrics.json`

**Expected Output:**
```
============================================================
🔍 MODEL EVALUATION
============================================================

📂 Loading model from: best_model.keras
✓ Model loaded successfully

📊 Loading test dataset from: ../data/final
Found 6 files belonging to 6 classes.
Using 20% for validation.

🧪 Evaluating model on test set...
25/25 [==============================] - 12s 480ms/step - loss: 0.2145 - accuracy: 0.9250

============================================================
📈 EVALUATION RESULTS
============================================================
Test Loss: 0.2145
Test Accuracy: 92.50%
============================================================

📊 Per-Class Accuracy:
----------------------------------------
BOP         :  94.12% (64/68 correct)
BOPF        :  91.67% (55/60 correct)
Dust        :  95.45% (63/66 correct)
Dust1       :  89.47% (51/57 correct)
Fanning1    :  93.33% (56/60 correct)
Pekoe       :  90.00% (54/60 correct)

💾 Metrics saved to: model_metrics.json
============================================================
```

---

### **Step 2: Metrics File (model_metrics.json)**

After evaluation, this file is created:

```json
{
  "evaluation_date": "2026-01-04T15:30:45.123456",
  "model_path": "best_model.keras",
  "test_dataset": "../data/final",
  "overall_accuracy": 92.5,
  "test_loss": 0.2145,
  "per_class_accuracy": {
    "BOP": 94.12,
    "BOPF": 91.67,
    "Dust": 95.45,
    "Dust1": 89.47,
    "Fanning1": 93.33,
    "Pekoe": 90.0
  },
  "total_samples": 371,
  "class_distribution": {
    "BOP": 68,
    "BOPF": 60,
    "Dust": 66,
    "Dust1": 57,
    "Fanning1": 60,
    "Pekoe": 60
  }
}
```

---

### **Step 3: API Automatically Uses These Metrics**

Once `model_metrics.json` exists, the API will:
- Load it on startup
- Include `model_accuracy` in all `/predict` responses
- Expose metrics via `/metrics` endpoint

**Test it:**
```bash
# Get metrics
curl http://localhost:8000/metrics

# Prediction now includes accuracy
curl -X POST http://localhost:8000/predict \
  -F "image=@tea.jpg" \
  -F "weight=305"
```

---

## 📡 New API Endpoint: `/metrics`

**URL:** `GET http://localhost:8000/metrics`

**Returns:**
```json
{
  "evaluation_date": "2026-01-04T15:30:45.123456",
  "overall_accuracy": 92.5,
  "per_class_accuracy": {
    "BOP": 94.12,
    "BOPF": 91.67,
    "Dust": 95.45,
    "Dust1": 89.47,
    "Fanning1": 93.33,
    "Pekoe": 90.0
  },
  "total_samples": 371
}
```

**In Postman:**
- Method: `GET`
- URL: `http://localhost:8000/metrics`
- No parameters needed

---

## 🔄 Re-evaluating After Retraining

### When to Re-evaluate:
- ✅ After training with new data
- ✅ After adjusting model architecture
- ✅ After changing hyperparameters
- ✅ Periodically (monthly/quarterly)

### Steps:
```powershell
# 1. Retrain model
python train.py

# 2. Evaluate new model
python evaluate_model.py

# 3. Restart API (auto-reloads new metrics)
# If using auto-reload, just save the file
# Otherwise, restart: python app_demo.py
```

---

## 📊 Understanding Model Performance

### **Good Accuracy Ranges:**

| Accuracy | Rating | Action |
|----------|--------|--------|
| **95%+** | Excellent | Production ready |
| **90-95%** | Good | Consider minor improvements |
| **85-90%** | Fair | Review problem classes |
| **<85%** | Poor | Retrain with more data |

### **Analyzing Per-Class Performance:**

If one class has low accuracy:
```json
{
  "Dust1": 75.0  ← Low accuracy!
}
```

**Possible reasons:**
1. ❌ Not enough training images for Dust1
2. ❌ Dust1 looks similar to Dust (confusion)
3. ❌ Low quality images
4. ❌ Inconsistent labeling

**Solutions:**
1. ✅ Add more Dust1 images to training data
2. ✅ Use data augmentation
3. ✅ Verify labels are correct
4. ✅ Increase training epochs

---

## 🎯 Updated Response Format

### **Before (without accuracy):**
```json
{
  "grade": "BOP",
  "confidence": 95.67
}
```

### **After (with accuracy):**
```json
{
  "grade": "BOP",
  "confidence": 95.67,
  "model_accuracy": 92.5,  ← NEW!
  "density_status": "Excellent",
  "price_per_kg": 1380.0,
  "quality_score": 97.84
}
```

---

## 🐛 Troubleshooting

### Issue: "Metrics not available"
**Cause:** `model_metrics.json` doesn't exist  
**Solution:** Run `python evaluate_model.py`

### Issue: Demo accuracy (92.5) instead of real
**Cause:** Using `app_demo.py` instead of `app.py`  
**Solution:** 
```powershell
# For real model with TensorFlow:
python app.py

# For demo mode:
python app_demo.py  # Shows 92.5 as demo value
```

### Issue: TensorFlow not compatible with Python 3.14
**Solution:** Use Python 3.9-3.11
```powershell
# Create virtual environment with Python 3.11
py -3.11 -m venv venv
venv\Scripts\activate
pip install tensorflow fastapi uvicorn python-multipart pillow
python evaluate_model.py
```

---

## 📈 Monitoring Accuracy Over Time

### Best Practices:

1. **Baseline Evaluation**
   ```powershell
   # First time
   python evaluate_model.py
   # Save baseline: 92.5%
   ```

2. **After Each Retrain**
   ```powershell
   python train.py
   python evaluate_model.py
   # Compare: 92.5% → 94.2% ✓ Improved!
   ```

3. **Track Metrics**
   - Keep old `model_metrics.json` files
   - Rename with dates: `model_metrics_2026-01-04.json`
   - Compare trends over time

4. **Production Monitoring**
   - Log prediction confidence values
   - Track user feedback
   - Re-evaluate quarterly

---

## 🎓 Key Takeaways

1. **Model Accuracy** = Overall correctness (92.5% of predictions are right)
2. **Confidence** = Certainty for ONE prediction (95.67% sure about this tea)
3. **Run** `evaluate_model.py` after training to get real metrics
4. **Check** `/metrics` endpoint to see model performance
5. **Monitor** per-class accuracy to find weak spots
6. **Retrain** when accuracy drops below 90%

---

## 🚀 Quick Commands

```powershell
# Evaluate model (generates metrics)
python evaluate_model.py

# Start API with metrics
python app_demo.py

# Check metrics endpoint
curl http://localhost:8000/metrics

# Test prediction (includes accuracy)
curl -X POST http://localhost:8000/predict \
  -F "image=@tea.jpg" \
  -F "weight=305"
```

---

**The API now provides complete transparency about model performance!** 🎯
