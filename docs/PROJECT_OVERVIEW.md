# iTeaGrow - Complete Project Overview

## What is iTeaGrow?

**iTeaGrow** is an AI-IoT (Artificial Intelligence + Internet of Things) mobile application system designed for **Sri Lankan tea plantations**. It combines deep learning, IoT sensors, and a mobile app to help tea farmers and estate managers with:

1. **Disease Detection** - Identify tea leaf diseases using phone camera
2. **Tea Leaf Maturity Assessment** - Determine optimal harvest timing
3. **Tea Powder Grading** - Classify processed tea into commercial grades
4. **Soil Monitoring** - Real-time soil health tracking via IoT sensors
5. **Yield Prediction** - Forecast crop output using ML
6. **Market Analysis** - Track tea auction prices and estimate value

---

## Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter 3.2+ (Android/iOS/Web) |
| **State Management** | Riverpod 2.5.1 |
| **Backend** | FastAPI (Python 3.10+) |
| **Database** | MongoDB Atlas (cloud) + SQLite (local) |
| **ML Models** | YOLOv8n, ShuffleNetV2, MobileNetV3, XGBoost |
| **ML Frameworks** | PyTorch Mobile, TensorFlow Lite, ONNX Runtime |
| **IoT Hardware** | ESP32-WROOM-32 + SIM800L GSM |
| **IoT Protocol** | MQTT (HiveMQ Cloud) |
| **Caching** | Redis |
| **Object Storage** | MinIO (S3-compatible) |
| **Containerization** | Docker & Docker Compose |
| **Languages** | English, Sinhala, Tamil |

---

## The 4 ML Models at a Glance

| Feature | Model | Architecture | Size | Input | Classes |
|---------|-------|-------------|------|-------|---------|
| Disease Detection | YOLOv8n | CSPDarknet + PANet | 20.3 MB | 640x640 | 4 (Healthy, Red Rust, Blister Blight, Not Leaf) |
| Leaf Maturity | ShuffleNetV2 | Channel Shuffle | 5.5 MB | 224x224 | 4 (Assamica/DT1 x Tender/Mature) |
| Powder Grading | MobileNetV3 | SE Blocks | 8.9 MB | 224x224 | 6 (BOP, BOPF, PF1, Dust, Dust1, Fanning1) |
| Yield Prediction | XGBoost/CatBoost | Gradient Boosting | Variable | Tabular data | Regression (kg/hectare) |

---

## Explainability (XAI)

All vision models include explainability features:

| Model | Technique | What It Shows |
|-------|-----------|---------------|
| Disease Detection | **Grad-CAM** | Which leaf regions indicate disease |
| Leaf Maturity | **CAM** | Which features indicate maturity stage |
| Powder Grading | **Grad-CAM** | Which particle characteristics indicate grade |

This is important because:
- Farmers can **trust** the AI by seeing WHY it made a decision
- Incorrect predictions can be **caught** when heatmaps look wrong
- Supports **learning** - farmers understand what disease symptoms look like

---

## Key Features

### Offline-First Architecture
- All ML models run **on-device** (no internet needed for predictions)
- SQLite stores results locally
- Automatic **cloud sync** when connectivity is restored
- Bluetooth direct connection to IoT sensors

### Multi-Language Support
- **English** - Default
- **Sinhala** (si) - For local farmers
- **Tamil** (ta) - For Tamil-speaking estate workers

### Security
- JWT token authentication
- Biometric login (fingerprint/face)
- Secure credential storage
- HTTPS/TLS encryption

---

## Detailed Documentation

For deep-dive into each component, see:

| Document | What It Covers |
|----------|---------------|
| [DISEASE_DETECTION_EXPLAINED.md](DISEASE_DETECTION_EXPLAINED.md) | YOLOv8n model, training data, inference pipeline, Grad-CAM |
| [TEA_LEAF_MATURITY_EXPLAINED.md](TEA_LEAF_MATURITY_EXPLAINED.md) | ShuffleNetV2 model, maturity classes, CAM, harvest standards |
| [TEA_GRADING_EXPLAINED.md](TEA_GRADING_EXPLAINED.md) | MobileNetV3 model, 6 tea grades, market pricing |
| [SOIL_MONITORING_EXPLAINED.md](SOIL_MONITORING_EXPLAINED.md) | ESP32 hardware, sensors, MQTT, TRI fertilizer rules |
| [HOW_TO_RUN.md](HOW_TO_RUN.md) | Complete setup and run commands for your laptop |

---

## System Architecture (High Level)

```
+--------------------------------------------------+
|                 MOBILE APP (Flutter)              |
|                                                   |
|  +----------+  +----------+  +----------+        |
|  | Disease  |  | Maturity |  | Grading  |        |
|  | YOLOv8n  |  |ShuffleV2 |  |MobileV3  |        |
|  | (PTL)    |  | (PTL)    |  | (TFLite) |        |
|  +----------+  +----------+  +----------+        |
|                                                   |
|  +----------+  +----------+  +----------+        |
|  | Soil     |  | Yield    |  | Market   |        |
|  | Monitor  |  | Predict  |  | Analysis |        |
|  +----------+  +----------+  +----------+        |
|                                                   |
|  [SQLite Local DB]  [Bluetooth BLE]              |
+------------------+-------------------------------+
                   |
                   | HTTPS / REST API
                   |
+------------------v-------------------------------+
|              BACKEND (FastAPI)                    |
|                                                   |
|  /api/v1/inference  - Disease detection           |
|  /api/v1/iot        - Sensor data ingestion       |
|  /api/v1/users      - User management             |
|  /api/v1/chatbot    - AI tea expert               |
|  /api/v1/yield      - Yield predictions           |
+------------------+-------------------------------+
                   |
        +----------+----------+
        |          |          |
   +----v---+ +---v----+ +---v----+
   |MongoDB | | Redis  | | MinIO  |
   | Atlas  | | Cache  | | Images |
   +--------+ +--------+ +--------+

+--------------------------------------------------+
|              IoT LAYER                            |
|                                                   |
|  [ESP32] --MQTT--> [HiveMQ] ---> [IoT Backend]  |
|    + NPK, pH, Moisture, Temp, Light sensors      |
|    + SIM800L GSM for SMS alerts                  |
|    + Solar + Battery power                       |
+--------------------------------------------------+
```
