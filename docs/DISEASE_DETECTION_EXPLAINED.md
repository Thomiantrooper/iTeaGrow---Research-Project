# Disease Detection System - Complete Technical Breakdown

## Overview

The disease detection module is the core feature of iTeaGrow. It uses a **YOLOv8n (You Only Look Once v8 nano)** object detection model to identify tea leaf diseases from camera images in real-time, both on-device (mobile) and server-side.

---

## Model Used: YOLOv8n (Nano)

### Why YOLOv8n?
- **Nano variant** = smallest and fastest in the YOLOv8 family
- Designed for **mobile and edge deployment** (low compute, low memory)
- Single-pass detection = processes the entire image in one forward pass (no region proposals)
- Achieves real-time inference (~30ms per frame on modern phones)
- Only **~22 MB** in PyTorch format

### Model Specifications
| Property | Value |
|----------|-------|
| Architecture | YOLOv8n (nano) |
| Input Size | 640 x 640 RGB |
| Number of Classes | 4 |
| Model Size (PyTorch) | ~22 MB |
| Model Size (ONNX) | ~43 MB |
| Confidence Threshold | 0.25 (default) |
| IoU Threshold (NMS) | 0.45 |

### What Diseases It Detects (4 Classes)

| Class | Scientific Name | Description |
|-------|----------------|-------------|
| **Healthy** | - | Normal, healthy tea leaf with no visible disease |
| **Red Rust** | *Cephaleuros virescens* | Algal leaf spot causing orange-red patches on leaf surface |
| **Blister Blight** | *Exobasidium vexans* | Fungal disease causing blister-like swellings on young leaves |
| **Not a Leaf** | - | False positive filter - detects when the image is not actually a tea leaf |

---

## Model File Formats & Where They Live

### Server-Side Models (`/models/`)
| File | Format | Size | Purpose |
|------|--------|------|---------|
| `best.pt` | PyTorch | 22 MB | Primary model for server inference |
| `best.onnx` | ONNX | 43 MB | Optimized for cross-platform deployment |
| `best.torchscript` | TorchScript | 43 MB | Serialized for production serving |

### Mobile Models (`/frontend/.../assets/models/`)
| File | Format | Size | Purpose |
|------|--------|------|---------|
| `disease_model.ptl` | PyTorch Mobile Lite | 20.3 MB | On-device inference (standard) |
| `disease_explain.ptl` | PyTorch Mobile Lite | 20.3 MB | On-device inference + Grad-CAM explainability |
| `disease_fc_weights.json` | JSON | ~87 KB | Feature weights for generating visual explanations |

---

## How Detection Works (Step by Step)

### 1. Image Capture
- User opens the app camera or selects an image from gallery
- Image is captured at native resolution

### 2. Image Quality Check
Before running inference, the system validates the image:
- **Green pixel ratio check**: At least **25%** of the image must be green (to confirm it's a leaf)
- **Blur detection**: Rejects blurry/out-of-focus images
- **Brightness check**: Rejects too dark or overexposed images
- If quality check fails, user gets feedback to retake the photo

### 3. Image Preprocessing
```
Original Image -> Resize to 640x640 -> Normalize pixel values (0-1) -> Convert to tensor
```
- Maintains aspect ratio with letterboxing (padding)
- RGB channel order
- Float32 precision

### 4. Model Inference (YOLOv8n Forward Pass)
The YOLOv8n architecture:
```
Input (640x640x3)
    |
    v
[Backbone: CSPDarknet] -- Feature extraction at multiple scales
    |
    v
[Neck: PANet/FPN] -- Multi-scale feature fusion
    |
    v
[Head: Decoupled Head] -- Separate classification + bounding box regression
    |
    v
Raw Predictions (8400 candidate detections)
```

### 5. Post-Processing
- **Non-Maximum Suppression (NMS)**: Removes duplicate/overlapping detections
  - IoU threshold: 0.45 (boxes overlapping >45% are merged)
  - Confidence threshold: 0.25 (detections below 25% confidence are discarded)
- **Minimum valid detections**: At least 1 valid detection required

### 6. Result Output
For each detection, the model outputs:
- **Bounding box**: `[x1, y1, x2, y2]` coordinates around the diseased area
- **Class label**: Healthy, Red Rust, Blister Blight, or Not a Leaf
- **Confidence score**: 0.0 to 1.0 (how certain the model is)

---

## Explainability: Grad-CAM (Gradient-weighted Class Activation Mapping)

### What is Grad-CAM?
Grad-CAM generates **heatmap visualizations** showing which parts of the leaf image the model focused on when making its prediction. This builds trust - farmers can see WHY the model classified a leaf as diseased.

### How Grad-CAM Works in This System
1. **Forward pass**: Run the image through the model normally
2. **Extract feature maps**: Capture the final convolutional layer's activations
3. **Compute gradients**: Calculate how much each feature map contributes to the predicted class
4. **Weighted combination**: Multiply each feature map by its importance weight
5. **Apply ReLU**: Keep only positive contributions
6. **Upsample**: Resize the small heatmap back to original image size
7. **Overlay**: Blend heatmap (60% opacity) with original image using JET colormap

### Visual Output
- **Red/Yellow areas**: High importance (model focused here for diagnosis)
- **Blue/Green areas**: Low importance (not relevant to the diagnosis)
- **Overlay**: Semi-transparent heatmap on top of the original leaf image

### Implementation Files
- **Server-side**: `src/services/explainability/gradcam.py`
- **Mobile-side**: Feature integrated in `disease_explain.ptl` model
- **Weights**: `disease_fc_weights.json` for mobile CAM computation

---

## Training Data

### Dataset Structure
```
raw_data/
  train/
    images/     # Training images
    labels/     # YOLO format bounding box annotations
  valid/
    images/     # Validation images
    labels/     # Validation annotations
  test/
    images/     # Test images
    labels/     # Test annotations
```

### Annotation Format (YOLO)
Each label file contains one line per object:
```
<class_id> <x_center> <y_center> <width> <height>
```
All values normalized to 0-1 relative to image dimensions.

### Training Scripts
| Script | Purpose |
|--------|---------|
| `export_disease_model.py` | Export trained model to ONNX format |
| `export_disease_explain_model.py` | Export with Grad-CAM support |
| `convert_ptl.py` | Convert to PyTorch Mobile (.ptl) format |
| `verify_models.py` | Verify model integrity and accuracy |
| `test_models.py` | Run test inference on sample images |

---

## Server-Side Inference Pipeline

### Key Files
| File | Role |
|------|------|
| `src/services/inference/detector.py` | Main YOLOv8 detection engine |
| `src/services/inference/image_processor.py` | Image preprocessing (resize, normalize) |
| `src/services/inference/quality_checker.py` | Image quality validation |
| `src/services/explainability/gradcam.py` | Grad-CAM heatmap generation |

### API Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/inference/detect` | POST | Detect diseases in a single image |
| `/api/v1/inference/batch` | POST | Process multiple images at once |
| `/api/v1/inference/explain` | POST | Get detection + Grad-CAM explanation |

---

## Mobile (On-Device) Inference Pipeline

### How On-Device Works
The Flutter app runs the model **directly on the phone** without needing internet:

1. **PyTorch Mobile Lite** runtime loads `disease_model.ptl`
2. Camera frame is preprocessed in Dart
3. Tensor is passed to the native PyTorch runtime via platform channels
4. Results are parsed and displayed with bounding boxes
5. Optional: `disease_explain.ptl` generates Grad-CAM heatmaps on-device

### Key Flutter Files
- `lib/features/disease_detection/` - Disease detection feature module
- `lib/services/ml_services/` - ML inference services
- On-device SQLite stores scan history for offline access

### Offline Capability
- Models are **bundled inside the APK** (~50 MB total for all models)
- No internet needed for basic detection
- Results are cached locally in SQLite
- When internet is available, results sync to MongoDB Atlas cloud

---

## Architecture Summary

```
                    +-------------------+
                    |   Camera/Gallery  |
                    +--------+----------+
                             |
                    +--------v----------+
                    |  Quality Checker  |
                    |  (blur, green %)  |
                    +--------+----------+
                             |
              +--------------+--------------+
              |                             |
     +--------v--------+          +--------v--------+
     |  On-Device       |          |  Server-Side    |
     |  (PyTorch Mobile)|          |  (FastAPI)      |
     |  disease_model.ptl|         |  best.pt/onnx   |
     +--------+---------+          +--------+--------+
              |                             |
     +--------v---------+         +--------v--------+
     |  NMS + Filtering  |         |  NMS + Filtering |
     +--------+----------+         +--------+--------+
              |                             |
     +--------v----------+        +--------v--------+
     |  Grad-CAM          |        |  Grad-CAM       |
     |  (disease_explain)  |        |  (gradcam.py)   |
     +--------+-----------+        +--------+--------+
              |                             |
              +-------------+---------------+
                            |
                   +--------v--------+
                   |  Display Result  |
                   |  + Bounding Box  |
                   |  + Confidence    |
                   |  + Heatmap       |
                   +-----------------+
```
