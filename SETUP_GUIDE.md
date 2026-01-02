# Complete Setup Guide - Tea Leaf Disease Detection System

This guide walks you through setting up the entire system from scratch.

## Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Training Data Setup](#2-training-data-setup)
3. [Environment Configuration](#3-environment-configuration)
4. [Model Training](#4-model-training)
5. [Backend Deployment](#5-backend-deployment)
6. [Mobile App Setup](#6-mobile-app-setup)
7. [IoT Sensor Setup](#7-iot-sensor-setup)
8. [Testing the System](#8-testing-the-system)

---

## 1. Prerequisites

### Install Required Software

#### Windows
```powershell
# Install Python 3.11
winget install Python.Python.3.11

# Install Node.js 18+
winget install OpenJS.NodeJS.LTS

# Install Docker Desktop
winget install Docker.DockerDesktop

# Install Git
winget install Git.Git
```

#### Linux/Mac
```bash
# Python
sudo apt install python3.11 python3.11-venv  # Ubuntu
brew install python@3.11  # Mac

# Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs  # Ubuntu
brew install node  # Mac

# Docker
curl -fsSL https://get.docker.com | sh
```

### Verify GPU (Optional but recommended for training)
```bash
# Check if CUDA is available
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

---

## 2. Training Data Setup

### Step 2.1: Create Dataset Directory Structure

Run this command to create the required folders:

```bash
cd C:\Users\lenovo\OneDrive\Desktop\Tea
python scripts/setup_dataset.py
```

Or manually create:
```
Tea/
└── data/
    ├── images/
    │   ├── train/     <- Put 70% of images here
    │   ├── val/       <- Put 20% of images here
    │   └── test/      <- Put 10% of images here
    └── labels/
        ├── train/     <- Corresponding label files
        ├── val/       <- Corresponding label files
        └── test/      <- Corresponding label files
```

### Step 2.2: Collect Training Images

**Image Requirements:**
- Format: JPG or PNG
- Minimum resolution: 640x640 pixels recommended
- Capture conditions: Various lighting, angles, backgrounds
- Include: Healthy leaves, Red Rust infected, Blister Blight infected

**Recommended Dataset Size:**
- Minimum: 500 images per class (1500 total)
- Recommended: 1000+ images per class (3000+ total)
- More data = better accuracy

### Step 2.3: Annotate Images with Bounding Boxes

Use **LabelImg** or **Roboflow** to annotate:

#### Option A: Using LabelImg (Free, Offline)
```bash
pip install labelImg
labelImg
```

1. Open LabelImg
2. Click "Open Dir" → Select `data/images/train`
3. Click "Change Save Dir" → Select `data/labels/train`
4. Set format to "YOLO" (important!)
5. Draw bounding boxes around each leaf
6. Select class: `healthy`, `red_rust`, or `blister_blight`
7. Save (Ctrl+S) after each image

#### Option B: Using Roboflow (Free tier, Online)
1. Go to https://roboflow.com
2. Create project → Object Detection
3. Upload images
4. Annotate using web interface
5. Export in "YOLOv8" format
6. Download and extract to `data/` folder

### Step 2.4: Label File Format

Each image needs a `.txt` file with the same name:

**Example:** `image001.jpg` → `image001.txt`

**Label format (YOLO):**
```
class_id x_center y_center width height
```

- All values normalized (0.0 to 1.0)
- Class IDs: 0=healthy, 1=red_rust, 2=blister_blight

**Example label file (`image001.txt`):**
```
1 0.45 0.32 0.12 0.08
2 0.67 0.55 0.15 0.10
0 0.25 0.75 0.20 0.18
```

This means:
- Red Rust leaf at position (0.45, 0.32) with size (0.12, 0.08)
- Blister Blight leaf at position (0.67, 0.55) with size (0.15, 0.10)
- Healthy leaf at position (0.25, 0.75) with size (0.20, 0.18)

### Step 2.5: Sample/Demo Data (For Testing)

If you don't have real data yet, create synthetic demo:

```bash
python scripts/create_demo_data.py
```

---

## 3. Environment Configuration

### Step 3.1: Create Python Virtual Environment

```bash
cd C:\Users\lenovo\OneDrive\Desktop\Tea

# Create virtual environment
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 3.2: Create Environment Configuration File

Create `.env` file in the project root:

```bash
# Copy the template
copy config\.env.example .env
```

Edit `.env` with your settings (see next section for details).

---

## 4. Model Training

### Step 4.1: Verify Dataset

```bash
python scripts/verify_dataset.py
```

This checks:
- Images exist in correct folders
- Labels are properly formatted
- Class distribution is balanced

### Step 4.2: Train the Model

```bash
# Basic training (CPU - slow but works everywhere)
python scripts/train_model.py --data ./data --output ./runs --epochs 100

# GPU training (much faster if you have NVIDIA GPU)
python scripts/train_model.py --data ./data --output ./runs --epochs 100 --batch-size 16

# Quick test run (5 epochs just to verify everything works)
python scripts/train_model.py --data ./data --output ./runs --epochs 5 --batch-size 8
```

### Step 4.3: Training Output

After training completes, you'll find:
```
runs/
└── tea_disease_YYYYMMDD_HHMMSS/
    ├── weights/
    │   ├── best.pt          <- Best model (use this!)
    │   └── last.pt          <- Last epoch model
    ├── results.csv          <- Training metrics
    ├── confusion_matrix.png <- Performance visualization
    └── training_config.json <- Training parameters
```

### Step 4.4: Export for Mobile

```bash
# Export to mobile formats
python scripts/export_model.py --model runs/tea_disease_*/weights/best.pt --formats onnx tflite
```

Output:
```
exports/
├── best.onnx      <- For Android (ONNX Runtime)
├── best.tflite    <- For Android (TensorFlow Lite)
└── best.mlmodel   <- For iOS (Core ML)
```

---

## 5. Backend Deployment

### Step 5.1: Start Docker Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f api
```

### Step 5.2: Verify Services

| Service | URL | Purpose |
|---------|-----|---------|
| API | http://localhost:8000 | Main backend |
| API Docs | http://localhost:8000/docs | Swagger UI |
| MinIO Console | http://localhost:9001 | File storage |
| Grafana | http://localhost:3000 | Monitoring |

### Step 5.3: Initialize Database

```bash
# Run database migrations
docker-compose exec api python -c "from backend.database.init import init_db; init_db()"
```

### Step 5.4: Create Storage Buckets

1. Open MinIO Console: http://localhost:9001
2. Login: `minioadmin` / `minioadmin`
3. Create buckets:
   - `tea-disease-images`
   - `tea-disease-models`

Or via command line:
```bash
docker-compose exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
docker-compose exec minio mc mb local/tea-disease-images
docker-compose exec minio mc mb local/tea-disease-models
```

---

## 6. Mobile App Setup

### Step 6.1: Install Dependencies

```bash
cd mobile_app
npm install
```

### Step 6.2: Configure API Endpoint

Edit `mobile_app/src/services/config.ts`:

```typescript
export const API_CONFIG = {
  // For local development (Android emulator)
  BASE_URL: 'http://10.0.2.2:8000/api/v1',

  // For local development (iOS simulator)
  // BASE_URL: 'http://localhost:8000/api/v1',

  // For physical device on same network
  // BASE_URL: 'http://YOUR_COMPUTER_IP:8000/api/v1',

  // For production
  // BASE_URL: 'https://api.yourdomain.com/api/v1',
};
```

### Step 6.3: Add Model File to App

Copy the exported model to the mobile app:

```bash
# Create assets directory
mkdir -p mobile_app/assets/models

# Copy ONNX model
copy exports\best.onnx mobile_app\assets\models\tea_disease.onnx
```

### Step 6.4: Run the App

```bash
cd mobile_app

# Start Expo development server
npx expo start

# Then:
# Press 'a' for Android emulator
# Press 'i' for iOS simulator
# Scan QR code with Expo Go app for physical device
```

### Step 6.5: Build for Production

```bash
# Android APK
npx expo build:android -t apk

# Android App Bundle (for Play Store)
npx expo build:android -t app-bundle

# iOS (requires Mac)
npx expo build:ios
```

---

## 7. IoT Sensor Setup

### Step 7.1: Hardware Requirements

| Component | Quantity | Purpose |
|-----------|----------|---------|
| ESP32 DevKit | 1 | Microcontroller |
| DHT22 Sensor | 1 | Temperature & Humidity |
| Capacitive Soil Moisture Sensor | 1 | Soil moisture |
| BH1750 Light Sensor | 1 | Light intensity |
| Jumper wires | ~15 | Connections |
| Breadboard | 1 | Prototyping |
| 5V Power supply / USB cable | 1 | Power |

### Step 7.2: Wiring Diagram

```
ESP32 DevKit          Sensors
─────────────         ───────
3.3V  ──────────────► DHT22 VCC
GND   ──────────────► DHT22 GND
GPIO4 ──────────────► DHT22 DATA

3.3V  ──────────────► Soil Sensor VCC
GND   ──────────────► Soil Sensor GND
GPIO34 ─────────────► Soil Sensor AOUT

3.3V  ──────────────► BH1750 VCC
GND   ──────────────► BH1750 GND
GPIO21 (SDA) ───────► BH1750 SDA
GPIO22 (SCL) ───────► BH1750 SCL
```

### Step 7.3: Flash Firmware

1. Install Arduino IDE or PlatformIO
2. Install ESP32 board support
3. Install libraries:
   - DHT sensor library
   - BH1750
   - ArduinoJson
   - PubSubClient (MQTT)

4. Open `iot_module/firmware/esp32_sensor_node.cpp`
5. Upload to ESP32

### Step 7.4: Configure Sensor via BLE

Use the mobile app's Sensor screen or a BLE scanner app:

1. Find device "TeaSensor-XXXX"
2. Connect and write to config characteristic:
```json
{
  "wifi_ssid": "YourWiFiName",
  "wifi_pass": "YourWiFiPassword",
  "mqtt_server": "your-server-ip",
  "mqtt_port": 1883
}
```

---

## 8. Testing the System

### Step 8.1: Test Backend API

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Expected response:
# {"status":"healthy","timestamp":"...","version":"1.0.0"}
```

### Step 8.2: Test Model Inference

```bash
python scripts/test_inference.py --image path/to/test/image.jpg
```

### Step 8.3: Test Mobile App

1. Open the app
2. Go to Camera tab
3. Take a photo of a tea leaf (or use test image)
4. Verify detection results appear
5. Check History tab for saved scan

### Step 8.4: Test Full Pipeline

```bash
# Run integration tests
python -m pytest tests/ -v
```

### Step 8.5: Test Offline Mode

1. Enable airplane mode on phone
2. Take photos and analyze - should work
3. Check History shows "Pending Sync"
4. Disable airplane mode
5. Data should sync automatically

---

## Troubleshooting

### Common Issues

**1. "No module named 'ultralytics'"**
```bash
pip install ultralytics
```

**2. "CUDA out of memory"**
```bash
# Reduce batch size
python scripts/train_model.py --data ./data --batch-size 8
```

**3. "Docker: port already in use"**
```bash
# Find and kill process using port
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

**4. Mobile app can't connect to API**
- Check your computer's firewall
- Use correct IP (not localhost for physical device)
- Verify Docker is running

**5. Model accuracy is low**
- Need more training data
- Check label quality
- Increase training epochs
- Balance class distribution

---

## Quick Start Commands Summary

```bash
# 1. Setup environment
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# 2. Prepare data (after adding your images/labels)
python scripts/verify_dataset.py

# 3. Train model
python scripts/train_model.py --data ./data --output ./runs --epochs 100

# 4. Start backend
docker-compose up -d

# 5. Run mobile app
cd mobile_app
npm install
npx expo start
```

---

## Next Steps

1. **Collect Real Data**: Get images from actual tea plantations
2. **Fine-tune Model**: Adjust training parameters for better accuracy
3. **Deploy to Cloud**: Use AWS/GCP/Azure for production
4. **Distribute App**: Publish to Play Store/App Store
5. **Install Sensors**: Deploy IoT nodes in the field

For support, check the project documentation or open an issue.
