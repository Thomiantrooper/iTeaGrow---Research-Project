# 🍃 Smart Tea Leaf Disease Detection Platform

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.1+-red.svg)](https://pytorch.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready backend system for detecting and managing tea leaf diseases in Sri Lankan plantations using AI-powered image analysis with YOLOv8n.

## 🎯 Features

| Feature | Description |
|---------|-------------|
| **Disease Detection** | YOLOv8n-based multi-leaf object detection (healthy, red rust, blister blight) |
| **ONNX Optimization** | Optimized inference with ONNX Runtime and optional INT8 quantization |
| **Grad-CAM Explainability** | Visual explanations for model predictions (server-side) |
| **IoT Integration** | Environmental sensor data processing (temperature, humidity, soil moisture, light) |
| **Rule-Based Recommendations** | Disease management and treatment advice tailored for Sri Lankan tea plantations |
| **Offline-First Architecture** | Secure local storage with automatic cloud sync |
| **Fault Tolerance** | Handles poor images, sensor failures, and network loss |
| **User Feedback** | Capture corrections for continuous model improvement |

## 🚀 Quick Start

### Using Docker (Recommended)

```bash
# Clone repository
git clone https://github.com/your-org/tea-leaf-disease-detection.git
cd tea-leaf-disease-detection

# Configure environment
cp .env.example .env

# Start services
docker-compose up -d

# Verify
curl http://localhost:8000/health
```

### Local Development

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Run application
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

## 📚 API Documentation

When running in development mode, interactive API documentation is available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/inference/detect` | POST | Detect diseases in an image |
| `/api/v1/inference/batch` | POST | Batch image processing |
| `/api/v1/inference/explain` | POST | Generate Grad-CAM explanations |
| `/api/v1/iot/ingest` | POST | Ingest IoT sensor data |
| `/api/v1/recommendations/generate` | POST | Get treatment recommendations |
| `/api/v1/sync/status` | GET | Check synchronization status |
| `/api/v1/feedback/submit` | POST | Submit user feedback |

### Example: Disease Detection

```bash
curl -X POST http://localhost:8000/api/v1/inference/detect \
  -F "image=@tea_leaf.jpg" \
  -F "plantation_id=PLT001" \
  -F "request_explainability=true"
```

Response:
```json
{
  "request_id": "uuid",
  "image_id": "uuid",
  "processing_time_ms": 45.2,
  "detections": [
    {
      "class_name": "red_rust",
      "confidence": 0.92,
      "bounding_box": {"x_min": 100, "y_min": 150, ...}
    }
  ],
  "summary": {
    "total_leaves_detected": 5,
    "healthy_count": 3,
    "red_rust_count": 2,
    "severity_level": "moderate"
  }
}
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                              │
│                    (FastAPI + Uvicorn)                       │
└─────────────────────────────────────────────────────────────┘
                              │
    ┌─────────┬───────────────┼───────────────┬─────────┐
    │         │               │               │         │
    ▼         ▼               ▼               ▼         ▼
┌───────┐ ┌───────┐     ┌───────────┐    ┌───────┐ ┌───────┐
│Infer- │ │Explain│     │    IoT    │    │ Reco- │ │ Sync  │
│ence   │ │ability│     │ Processor │    │mmend  │ │Manager│
└───────┘ └───────┘     └───────────┘    └───────┘ └───────┘
    │         │               │               │         │
    └─────────┴───────────────┴───────────────┴─────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
    ┌─────────┐         ┌─────────┐         ┌─────────┐
    │  Redis  │         │  MinIO  │         │  Local  │
    │  Queue  │         │ Storage │         │ Storage │
    └─────────┘         └─────────┘         └─────────┘
```

## 📁 Project Structure

```
tea-leaf-disease-detection/
├── configs/                    # Configuration management
│   └── settings.py            # Pydantic settings
├── docker/                     # Docker configurations
│   ├── gateway/               # API gateway Dockerfile
│   └── inference/             # Inference service Dockerfiles
├── docs/                       # Documentation
├── models/                     # Model weights (.pt, .onnx)
├── scripts/                    # Training & utility scripts
│   ├── train.py               # Model training
│   ├── export.py              # ONNX export
│   ├── validate.py            # Model validation
│   └── prepare_dataset.py     # Dataset preparation
├── src/
│   ├── api/                   # FastAPI application
│   │   ├── routes/            # API endpoints
│   │   ├── middleware.py      # Custom middleware
│   │   └── schemas.py         # Pydantic schemas
│   ├── core/                  # Core utilities
│   │   ├── exceptions.py      # Custom exceptions
│   │   ├── logging.py         # Logging configuration
│   │   └── security.py        # Security utilities
│   ├── services/              # Business logic
│   │   ├── inference/         # YOLOv8 detection
│   │   ├── explainability/    # Grad-CAM implementation
│   │   ├── iot/               # Sensor data processing
│   │   ├── recommendation/    # Rules engine
│   │   └── sync/              # Offline sync
│   └── main.py                # Application entry point
├── tests/                      # Test suite
├── docker-compose.yml          # Docker orchestration
├── requirements.txt            # Python dependencies
└── .env.example               # Environment template
```

## 🔧 Configuration

Copy `.env.example` to `.env` and configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug mode | `false` |
| `DEVICE` | Inference device (cpu/cuda) | `cpu` |
| `USE_ONNX` | Use ONNX Runtime | `true` |
| `CONFIDENCE_THRESHOLD` | Detection threshold | `0.25` |
| `REDIS_HOST` | Redis server | `localhost` |
| `MINIO_ENDPOINT` | Object storage | `localhost:9000` |
| `ENCRYPTION_KEY` | Local storage encryption | (generate) |

## 🧪 Training

### Dataset Preparation

```bash
python scripts/prepare_dataset.py \
  --input raw_data/ \
  --output datasets/tealeaf/
```

### Model Training

```bash
python scripts/train.py \
  --data datasets/tealeaf/data.yaml \
  --epochs 100 \
  --batch 16 \
  --export-onnx
```

### Model Export

```bash
python scripts/export.py \
  --weights runs/train/tealeaf/weights/best.pt \
  --format onnx \
  --simplify
```

## 🐳 Deployment

### Production Checklist

- [ ] Set `DEBUG=false`
- [ ] Configure strong `SECRET_KEY` and `ENCRYPTION_KEY`
- [ ] Set up SSL/TLS termination
- [ ] Configure proper CORS origins
- [ ] Set up log aggregation (ELK/CloudWatch)
- [ ] Configure MinIO backup
- [ ] Set up monitoring (Prometheus/Grafana)

### GPU Deployment

```bash
docker-compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

## 🧪 Testing

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html
```

## 📊 Monitoring

- **Health Check**: `GET /health`
- **Liveness Probe**: `GET /health/live`
- **Readiness Probe**: `GET /health/ready`
- **Metrics**: `GET /metrics`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics)
- [FastAPI](https://fastapi.tiangolo.com/)
- Sri Lanka Tea Research Institute

---

**Built with ❤️ for Sri Lankan Tea Plantations**
