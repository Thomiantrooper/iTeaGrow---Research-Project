# Smart Tea Leaf Disease Detection Platform

A production-ready backend system for detecting and managing tea leaf diseases in Sri Lankan plantations using AI-powered image analysis.

## Features

- **Disease Detection**: YOLOv8n-based multi-leaf object detection and classification
- **Explainability**: Server-side Grad-CAM visual explanations for model predictions
- **IoT Integration**: Environmental sensor data processing (temperature, humidity, soil moisture, light)
- **Recommendations**: Rule-based disease management and treatment advice
- **Offline-First**: Secure local storage with automatic cloud synchronization
- **Fault Tolerant**: Handles poor images, sensor failures, and network loss

## Disease Classes

| Class | Description | Scientific Name |
|-------|-------------|-----------------|
| Healthy | Normal tea leaves | - |
| Red Rust | Algal leaf spot disease | *Cephaleuros virescens* |
| Blister Blight | Major fungal disease | *Exobasidium vexans* |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                              │
│                    (FastAPI + Uvicorn)                       │
└─────────────────────────────────────────────────────────────┘
         │           │           │           │           │
         ▼           ▼           ▼           ▼           ▼
┌─────────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│  Inference  │ │ Explain │ │   IoT   │ │  Reco-  │ │  Sync   │
│   Service   │ │ Service │ │ Service │ │ mmender │ │ Service │
└─────────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘
         │           │           │           │           │
         └───────────┴───────────┴───────────┴───────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
   ┌──────────┐         ┌──────────┐         ┌──────────┐
   │  Redis   │         │  MinIO   │         │  Local   │
   │  Queue   │         │ Storage  │         │ Storage  │
   └──────────┘         └──────────┘         └──────────┘
```

## Quick Start

### Prerequisites

- Python 3.10+
- Docker & Docker Compose
- NVIDIA GPU (optional, for accelerated inference)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/your-org/tea-leaf-disease-detection.git
cd tea-leaf-disease-detection
```

2. **Create environment file**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Using Docker (Recommended)**
```bash
# CPU-only deployment
docker-compose up -d

# GPU-enabled deployment
docker-compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

4. **Local Development**
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
.\venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Run the application
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### Verify Installation

```bash
# Check health endpoint
curl http://localhost:8000/health

# View API documentation (development mode)
open http://localhost:8000/docs
```

## API Endpoints

### Disease Detection

```bash
# Single image detection
curl -X POST http://localhost:8000/api/v1/inference/detect \
  -F "image=@tea_leaf.jpg" \
  -F "plantation_id=PLT001" \
  -F "request_explainability=true"

# Batch detection
curl -X POST http://localhost:8000/api/v1/inference/batch \
  -F "images=@image1.jpg" \
  -F "images=@image2.jpg" \
  -F "plantation_id=PLT001"
```

### IoT Data Ingestion

```bash
curl -X POST http://localhost:8000/api/v1/iot/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "SENSOR001",
    "plantation_id": "PLT001",
    "timestamp": "2024-01-15T10:30:00Z",
    "temperature": 24.5,
    "humidity": 75.0,
    "soil_moisture": 45.0,
    "light_intensity": 35000
  }'
```

### Get Recommendations

```bash
curl -X POST http://localhost:8000/api/v1/recommendations/generate \
  -H "Content-Type: application/json" \
  -d '{
    "plantation_id": "PLT001",
    "detection_summary": {
      "total_leaves_detected": 10,
      "healthy_count": 5,
      "red_rust_count": 3,
      "blister_blight_count": 2,
      "overall_health_score": 50.0,
      "severity_level": "high",
      "requires_immediate_action": true
    }
  }'
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug mode | `false` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `DEVICE` | Inference device (cpu/cuda) | `cpu` |
| `USE_ONNX` | Use ONNX runtime | `true` |
| `CONFIDENCE_THRESHOLD` | Detection confidence | `0.25` |
| `REDIS_HOST` | Redis server host | `localhost` |
| `MINIO_ENDPOINT` | MinIO server endpoint | `localhost:9000` |

See `.env.example` for complete configuration options.

## Model Training

### Dataset Preparation

```bash
# Organize dataset in YOLO format
datasets/
├── train/
│   ├── images/
│   └── labels/
├── val/
│   ├── images/
│   └── labels/
└── data.yaml
```

### Training

```bash
# Train YOLOv8n model
python scripts/train.py \
  --data datasets/data.yaml \
  --epochs 100 \
  --imgsz 640 \
  --batch 16

# Export to ONNX
python scripts/export.py \
  --weights runs/train/exp/weights/best.pt \
  --format onnx \
  --simplify
```

## Deployment

### Production Checklist

- [ ] Set `DEBUG=false`
- [ ] Configure strong `SECRET_KEY`
- [ ] Set up SSL/TLS termination
- [ ] Configure proper CORS origins
- [ ] Set up log aggregation
- [ ] Configure backup for MinIO storage
- [ ] Set up monitoring and alerting

### Kubernetes Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/
```

## Project Structure

```
tea-leaf-disease-detection/
├── configs/                 # Configuration files
│   ├── __init__.py
│   └── settings.py         # Pydantic settings
├── docker/                  # Docker configurations
│   ├── gateway/
│   └── inference/
├── docs/                    # Documentation
├── models/                  # Model weights
├── scripts/                 # Training & utility scripts
├── src/
│   ├── api/                 # FastAPI routes
│   │   ├── routes/
│   │   ├── middleware.py
│   │   └── schemas.py
│   ├── core/                # Core utilities
│   │   ├── exceptions.py
│   │   ├── logging.py
│   │   └── security.py
│   ├── services/            # Business logic
│   │   ├── explainability/
│   │   ├── inference/
│   │   ├── iot/
│   │   ├── recommendation/
│   │   └── sync/
│   └── main.py              # Application entry point
├── tests/                   # Test suite
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `pytest`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Open an issue on GitHub
- Contact: support@example.com
