# Leaf Maturity Component

The Leaf Maturity component provides an AI-powered analysis of tea leaves to determine their **Species** (Assamica vs. DT1) and **Maturity level** (Tender vs. Mature). It features a unique "Explainability" layer that visualizes which parts of the leaf the AI is looking at using Class Activation Mapping (CAM).

## 🧠 Model Architecture

### Exact Model Details
- **Filename**: `tea_maturity_explain.ptl` (Optimized for Mobile)
- **Path**: `assets/models/tea_maturity_explain.ptl`
- **Backbone**: **ShuffleNetV2** (Mobile-optimized architecture)
- **Target CAM Layer**: `conv5` (The final 1024-channel convolutional feature map)
- **Input Size**: 224x224 px (RGB)

### 🛠️ Model Engineering Pipeline (Scripts)
The following Python scripts were used to bridge the gap between the research model and the "Explainable" mobile implementation:

#### 1. `inspect_model.py`
Used to explore the internal TorchScript structure of the original model. It identified that the backbone was ShuffleNetV2 and located the specific layer indices and parameter names (like `conv5` and `fc`) needed for extraction.

#### 2. `extract_weights.py`
Targets the weights of the final Linear (`fc`) layer. Since the mobile runtime doesn't allow easy access to internal weights during inference, this script:
- Loads the `.pt` model.
- Detaches the `fc.1.weight` tensor.
- Exports it to `assets/models/fc_weights.json`.
- These weights are then used in Dart to calculate the weighted sum of feature maps for the CAM heatmap.

#### 3. `export_explainable_model.py`
This is the core "bridge" script. It wraps the standard ShuffleNetV2 model in a custom class (`ExplainableShuffleNet`) that:
- Captures the output of the `conv5` layer *before* it is averaged and passed to the classifier.
- Flattens the 1024x7x7 features.
- Concatenates the classification Logits (4) with the spatial Features (50176) into a single 50,180-element tensor.
- Saves the wrapped model for the **PyTorch Mobile Lite Interpreter**.

### Output Structure (Concatenated Tensor)
To work around limitations in mobile inference engines (single-tensor output preference), we use a concatenated tensor:
1. **Indices 0-3**: Classification Logits (Assamica_Tender, Assamica_Mature, DT1_Tender, DT1_Mature).
2. **Indices 4-50179**: Raw Feature Maps (1024 channels × 7 × 7 grid from `conv5`) for Heatmap calculation.

### 📁 Model File Distinction (Why two files?)
You will see two `.ptl` files in the `assets/models/` directory:
- **`tea_maturity.ptl`**: The standard classification model. Use this only if heatmaps are NOT required.
- **`tea_maturity_explain.ptl` (ACTIVE)**: The explainable version used by this service. It contains the custom wrapper that provides both predictions and feature maps in a single pass. 

> [!IMPORTANT]
> The app is hardcoded to use `tea_maturity_explain.ptl`. Switching to the base version without modifying the Dart service logic will result in internal parsing errors.

### 🔄 Model Loading & Initialization
The component uses a singleton-like initialization pattern in `LeafMaturityPyTorchService` to ensure the heavy model is only loaded once.

1.  **State Guard**: A `_isInitialized` boolean prevents redundant loading.
2.  **Model Loading**: Uses the `pytorch_lite` package:
    ```dart
    _model = await PytorchLite.loadClassificationModel(
        'assets/models/tea_maturity_explain.ptl', 224, 224, 4);
    ```
3.  **Weight Loading**: Simultaneously loads `fc_weights.json` from the root bundle for CAM calculation.

### 🖼️ Image Preprocessing
Before inference, images undergo a standard vision pipeline to match the training data:

- **Resizing**: The image is resized such that the shorter side is 256 pixels while maintaining aspect ratio.
- **Center Cropping**: A 224x224 patch is cropped from the center.
- **Normalization**: Pixel values are normalized using ImageNet constants:
    - **Mean**: `[0.485, 0.456, 0.406]`
    - **Std Dev**: `[0.229, 0.224, 0.225]`
- **Inference Call**: Handled via `_model!.getImagePredictionList()`, which combines classification and feature extraction in one call.

### Auxiliary Files
- **`fc_weights.json`**: Contains the weights from the final Linear layer of the model. Since TFLite/PyTorch Mobile don't easily expose internal weights during run-time, we export these to JSON to calculate the CAM overlay manually in Dart.

---

## 🔍 Explainability (CAM Implementation)

### The Concept
We use **Class Activation Mapping (CAM)** instead of Grad-CAM because mobile inference engines do not provide the gradients required for Grad-CAM.

**Formula**:
`ActivationMap = Σ (weight_i * feature_map_i)`
Where:
- `weight_i` is the weight of the $i$-th channel for the predicted class (from `fc_weights.json`).
- `feature_map_i` is the $i$-th 7x7 activation grid (from the model's concatenated output).

### Implementation Flow
1. **Inference**: The service sends the image to `tea_maturity_explain.ptl`.
2. **Extraction**: Dart splits the result into classification logits and 1024 raw feature maps.
3. **Weighting**: Each of the 1024 feature maps is multiplied by its corresponding class weight.
4. **Summation**: The weighted maps are summed into a single 7x7 grid.
5. **Post-Processing**:
   - **ReLU**: Negative values are set to zero (focus only on positive triggers).
   - **Normalization**: Scales values to 0.0 - 1.0.
   - **Bilinear Upscaling**: Resizes the 7x7 grid to 224x224 to match the image.
6. **Visualization**: A JET-like color map is applied (Red = High interest, Blue = Low interest) and blended at 60% opacity over the original image.

---

## 🍃 Broad "Leaf Intelligence" Insights
The iTeaGrow system treats the tea leaf as the primary sensory organ of the plantation. Beyond maturity analysis, the system integrates several other "leaf-centric" modules:

### 🌱 Leaf Nutrition & Soil Interaction
The leaf's appearance is directly linked to soil health.
- **Soil Test Integration**: Nutrient deficiencies (like Nitrogen or Potassium) often manifest in leaf color changes. The system cross-references **Soil Health** data with **Leaf maturity** trends to advise on fertilization.
- **Growth Monitoring**: The `Plants` section tracks leaf count and surface area growth over time to predict the next available harvest window.

### 📡 IoT Contextual Scanning
Leaf analysis is never done in isolation. Every scan is enriched with:
- **Real-time Temperature & Humidity**: High humidity + specific leaf visual patterns trigger "High Disease Risk" alerts.
- **Air Quality**: Monitors how environmental stressors affecting the leaf's stomatal functions might be impacting overall yield.

---

## ✂️ Harvesting Standards (Growth Stages)
The system uses the industry-standard "Two Leaves and a Bud" philosophy to guide harvest timing, tracked in the `Plants` monitoring module:

| Stage | Description | System Status |
|-------|-------------|---------------|
| **Bud Stage** | Young buds, 1-2 leaves unfolded | Growing |
| **P+1** | One leaf below bud fully open | Near Harvest |
| **P+2** | **Two leaves below bud** | **Optimal Harvest** |
| **P+3** | Three leaves below bud | Mature |
| **Mature** | Fully mature, past optimal window | Over-mature |

### 🎯 The "Optimal Window"
The AI specifically flags **P+2** as the "Golden Window" for high-quality tea production. Scans that detect this stage will trigger a "Ready for Harvest" priority alert in the Manager Dashboard to ensure maximum flavor and yield balance.

---

## 🛠 Troubleshooting & Known Issues

### 1. `Incomplete model output` Error
- **Cause**: The model returned fewer than 50,180 values.
- **Solution**: Ensure the model being used is the `.ptl` version exported with the custom "explainable" wrapper that concatenates the features.

### 2. `PlatformException` (Multiple Outputs)
- **Cause**: PyTorch Lite's `getImagePredictionList` expects a single output tensor. 
- **Solution**: We previously fixed this by merging the Heatmap features and the Class predictions into one single tensor in the Python export script.

### 3. All heatmaps look the same
- **Cause**: `fc_weights.json` is missing or contains weights for the wrong class.
- **Solution**: Re-export weights using `extract_weights.py` whenever the model architecture or classes change.

### 4. High Latency on First Scan
- **Cause**: Model initialization and asset loading.
- **Optimization**: The `LeafMaturityPyTorchService` uses a singleton-like initialization pattern that keeps the model in memory after the first scan.

---

## 📂 File Summary
- `lib/features/leaf_maturity/data/datasources/leaf_maturity_pytorch_service.dart`: The core logic for inference and CAM generation.
- `lib/features/leaf_maturity/presentation/screens/leaf_maturity_screen.dart`: The UI for camera interaction and result display.
- `assets/models/tea_maturity_explain.ptl`: The brain of the component.
- `assets/models/fc_weights.json`: Required for the heatmap functionality.
