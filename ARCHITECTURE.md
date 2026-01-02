# Smart Tea Leaf Disease Detection and Monitoring System
## System Architecture Documentation

### Overview
A production-ready, offline-first system for detecting Red Rust and Blister Blight diseases in Sri Lankan tea plantations using YOLOv8n object detection with environmental IoT monitoring.

---

## System Architecture Diagram

```
+------------------------------------------------------------------+
|                    SMART TEA LEAF DISEASE SYSTEM                  |
+------------------------------------------------------------------+
|                                                                   |
|  +--------------------+    +--------------------+                 |
|  |   MOBILE APP       |    |   IoT SENSORS      |                 |
|  |   (React Native)   |    |   (ESP32/Arduino)  |                 |
|  |                    |    |                    |                 |
|  | - Camera Capture   |    | - Temperature      |                 |
|  | - On-device AI     |    | - Humidity         |                 |
|  | - Offline Storage  |    | - Soil Moisture    |                 |
|  | - Multilingual UI  |    | - Light Intensity  |                 |
|  +--------+-----------+    +--------+-----------+                 |
|           |                         |                             |
|           v                         v                             |
|  +--------------------------------------------------+             |
|  |              LOCAL PROCESSING LAYER               |             |
|  |                                                   |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  |  | YOLOv8n    |  | Grad-CAM    |  | Decision   | |             |
|  |  | Inference  |  | Explainer   |  | Support    | |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  |                                                   |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  |  | SQLite     |  | Image       |  | Sensor     | |             |
|  |  | Database   |  | Storage     |  | Buffer     | |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  +--------------------------------------------------+             |
|           |                                                       |
|           | (When Online)                                         |
|           v                                                       |
|  +--------------------------------------------------+             |
|  |              CLOUD SERVICES LAYER                 |             |
|  |                                                   |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  |  | REST API   |  | PostgreSQL  |  | S3 Storage | |             |
|  |  | (FastAPI)  |  | Database    |  | (Images)   | |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  |                                                   |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  |  | Model      |  | Analytics   |  | Feedback   | |             |
|  |  | Registry   |  | Dashboard   |  | Pipeline   | |             |
|  |  +-------------+  +-------------+  +------------+ |             |
|  +--------------------------------------------------+             |
+-------------------------------------------------------------------+
```

---

## Module Architecture

### 1. AI Inference Engine (`/ai_engine`)
- **Model**: YOLOv8n optimized for mobile deployment
- **Classes**: Healthy, Red Rust, Blister Blight
- **Input**: RGB images (640x640 recommended)
- **Output**: Bounding boxes, class labels, confidence scores
- **Export Formats**: ONNX, TFLite, CoreML

### 2. Explainability Module (`/explainability`)
- **Method**: Grad-CAM (Gradient-weighted Class Activation Mapping)
- **Purpose**: Highlight disease-affected regions
- **Mode**: Optional (for supervisors/researchers only)
- **Output**: Heatmap overlay on original image

### 3. IoT Integration (`/iot_module`)
- **Hardware**: ESP32 microcontroller
- **Sensors**: DHT22 (temp/humidity), capacitive soil moisture, BH1750 (light)
- **Protocol**: BLE for mobile connection, MQTT for cloud
- **Sampling**: Every 5 minutes

### 4. Decision Support (`/decision_support`)
- **Type**: Rule-based expert system
- **Inputs**: Detection results + Environmental data
- **Outputs**: Disease-specific recommendations
- **Languages**: Sinhala, Tamil, English

### 5. Mobile Application (`/mobile_app`)
- **Framework**: React Native with Expo
- **Storage**: SQLite + AsyncStorage
- **Inference**: TensorFlow Lite / ONNX Runtime
- **UI**: Simple, icon-driven for low digital literacy

### 6. Cloud Backend (`/backend`)
- **API**: FastAPI (Python)
- **Database**: PostgreSQL
- **Storage**: S3-compatible (MinIO for self-hosted)
- **Sync**: Conflict-free replicated data types (CRDTs)

---

## Data Flow

```
1. Image Capture → Preprocessing → YOLOv8n Inference → Detection Results
                                                            ↓
2. Environmental Data → Sensor Fusion → Context Enrichment ←
                                                            ↓
3. Detection + Context → Decision Rules → Recommendations
                                                            ↓
4. Results → Local Storage → (Online?) → Cloud Sync
                     ↓
5. User Feedback → Flagged Predictions → Model Improvement Queue
```

---

## Disease Classification

| Class | ID | Description |
|-------|-----|-------------|
| Healthy | 0 | Normal green tea leaf |
| Red Rust | 1 | Cephaleuros virescens - orange/rust colored spots |
| Blister Blight | 2 | Exobasidium vexans - white/pale blisters on young leaves |

---

## Environmental Thresholds

| Parameter | Red Rust Favorable | Blister Blight Favorable |
|-----------|-------------------|-------------------------|
| Temperature | 25-30°C | 15-25°C |
| Humidity | 70-90% | >85% |
| Soil Moisture | High (>60%) | Moderate-High (50-70%) |
| Light | Shaded conditions | Low light, overcast |

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/detect` | POST | Upload image for detection |
| `/api/v1/sync` | POST | Sync local data to cloud |
| `/api/v1/feedback` | POST | Submit prediction feedback |
| `/api/v1/sensors` | POST | Upload sensor readings |
| `/api/v1/model/latest` | GET | Get latest model version |
| `/api/v1/recommendations` | GET | Get recommendations by disease |

---

## Security

- Local SQLite database with encryption
- JWT authentication for cloud API
- HTTPS/TLS for all cloud communications
- Image data anonymization option
- Role-based access (Field Worker, Supervisor, Researcher)

---

## Deployment

- **Mobile**: Android APK, iOS App Store
- **IoT**: OTA firmware updates via ESP-IDF
- **Backend**: Docker containers on Kubernetes
- **Model**: MLflow registry with versioning
