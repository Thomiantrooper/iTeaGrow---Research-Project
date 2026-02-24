# Tea Powder Classification & Market Analysis Components 🍵

This document provides a technical overview of the **Tea Powder Grading (with Grad-CAM)** and **Market Value Analysis** features integrated into the iTeaGrow system.

---

## 🔬 1. Tea Powder Grading (Computer Vision)
The system uses an advanced on-device AI model to classify tea powder samples into 6 quality grades (BOP, BOPF, Dust, Dust1, Fanning1, Pekoe).

### 🧠 Model Architecture & Explainability
To provide high-trust results, we implemented **Grad-CAM (Gradient-weighted Class Activation Mapping)** for visual explainability.

- **Explainable TFLite Model**: `grading_model_explain.tflite`
  - **Input**: 224x224 RGB Image.
  - **Output 0**: Feature Maps `[1, 7, 7, 1280]` (extracted from the last convolutional layer).
  - **Output 1**: Classification Logits `[1, 6]`.
- **Pre-computed Weights**: `powder_weights.json`
  - Contains the transposed weights of the final `Dense` layer `(6 x 1280)`.
  - Used in Dart to perform a weighted sum of the feature maps without requiring expensive backpropagation on-device.

### 🛠️ Grad-CAM Logic (Dart)
The CAM is generated in `GradingMlService.dart` using the following steps:
1. **Weighted Sum**: $CAM = \sum weights_c \cdot feature\_maps_c$
2. **ReLU Activation**: Removes negative influence to focus on distinguishing features.
3. **Normalization**: Scales the map to a `0-1` range.
4. **Color Mapping**: Converts normalized values to a Blue-to-Red heatmap.
5. **Alpha Blending**: Overlays the heatmap on the original image with 30% intensity.

---

## 📈 2. Market Value Analysis
Allows Managers and Admins to manage real-time tea prices and visualize market trends.

### 🖥️ Admin Price Update
- **Feature**: Provides a clean interface for updating the weekly tea auction prices.
- **Smart Placeholders**: Displays the latest known market prices as guidance (hint text).
- **Fallback Logic**: If a user leaves a price field empty, the system automatically uses the latest market value to ensure the AI model always has a complete dataset.
- **Role-Based Access**: Restricted to **Manager** and **Admin** roles.

### 📊 Data Visualization
- **Market Trends**: Synchronized with the production API to fetch historical price data.
- **Pricing Calculator**: Integrates classification results with current market values to provide "Best Estimated Price" per kilogram.

---

## 🏗️ Technical Stack
- **Framework**: Flutter (Riverpod for State Management)
- **Engine**: TensorFlow Lite (tflite_flutter)
- **Networking**: HTTP REST API for Cloud Market Data & Publishing.
- **Image Processing**: `image` package for pixel-level manipulation and heatmap blending.

---

## 📁 Key File Locations
- **ML Logic**: `lib/features/market_analysis/data/services/grading_ml_service.dart`
- **Admin UI**: `lib/features/market_analysis/presentation/market_value_admin_screen.dart`
- **Models**: `assets/models/grading_model_explain.tflite`
- **Data Weights**: `assets/models/powder_weights.json`
- **State Management**: `lib/features/market_analysis/providers/market_providers.dart`

---

## 🚀 How to Add New Grades
1. Update the `_labels` list in `GradingMlService.dart`.
2. Re-export the Keras model using `tensorflow` and update the `Dense` layer weights in `powder_weights.json`.
3. Update the `_gradesList` in the Admin Screen to allow price management for the new grade.
