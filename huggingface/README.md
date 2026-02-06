---
title: iTeaGrow Disease Detection API
emoji: 🍃
colorFrom: green
colorTo: yellow
sdk: docker
pinned: false
license: mit
app_port: 7860
---

# iTeaGrow Tea Leaf Disease Detection API

A production-ready API for detecting tea leaf diseases using YOLOv8.

## Diseases Detected
- **Healthy** - No disease detected
- **Red Rust** - Cephaleuros virescens
- **Blister Blight** - Exobasidium vexans

## API Endpoints

### Health Check
```
GET /health
```

### Disease Detection (Single Image)
```
POST /api/v1/inference/detect
```
- `image`: Image file (required)
- `temperature`: Environmental temperature (optional)
- `humidity`: Environmental humidity (optional)

### Field Analysis (Multiple Leaves)
```
POST /api/v1/inference/field-analysis
```
- `image`: Field image with multiple leaves
- `temperature`: Environmental temperature (optional)
- `humidity`: Environmental humidity (optional)

## Usage

```python
import requests

url = "https://YOUR-SPACE.hf.space/api/v1/inference/detect"
files = {"image": open("leaf.jpg", "rb")}
response = requests.post(url, files=files)
print(response.json())
```
