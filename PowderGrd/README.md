# Tea Grading Backend API

## 🚀 How to Run

### Step 1: Navigate to Project
```powershell
cd src
```

### Step 2: Create Virtual Environment (Recommended)
```powershell
python -m venv venv
```

### Step 3: Activate Virtual Environment
```powershell
venv\Scripts\activate
```

### Step 4: Install Dependencies
```powershell
pip install -r requirements.txt
```

### Step 5: Start Server
```powershell
python app_demo.py
```

Server runs at: **http://localhost:8000**

---

## 🔧 Alternative (Without Virtual Environment)

If you skip virtual environment:
```powershell
cd src
pip install -r requirements.txt
python app_demo.py
```

---

## 📡 API Endpoints

### 1. Health Check
**GET** `/health`

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true
}
```

---

### 2. Get Standards
**GET** `/grades`

**Response:**
```json
{
  "grades": ["BOP", "BOPF", "Dust", "Dust1", "Fanning1", "Pekoe"],
  "density_standards": {
    "BOP": {"min": 280, "max": 320, "optimal": 300}
  },
  "base_prices": {
    "BOP": 1200
  }
}
```

---

### 3. Predict Grade (Main Endpoint)
**POST** `/predict`

**Body:** `form-data`

| Key | Type | Value | Required |
|-----|------|-------|----------|
| `image` | File | Tea image (.jpg, .png) | Yes |
| `weight` | Text | Weight in grams (e.g., `305`) | Yes |
| `volume` | Text | Volume in liters (e.g., `1.0`) | No (default: 1.0) |

**Response:**
```json
{
  "grade": "BOP",
  "confidence": 95.67,
  "model_accuracy": 92.5,
  "density_status": "Excellent",
  "entered_weight": 305.0,
  "standard_density_range": {
    "min": 280,
    "max": 320,
    "optimal": 300,
    "actual": 305.0
  },
  "within_tolerance": true,
  "price_category": "Premium",
  "price_per_kg": 1380.0,
  "quality_score": 97.84,
  "recommendations": "Excellent quality BOP! Density is optimal."
}
```

---

### 4. Check Density Only
**POST** `/check-density`

**Body:** `x-www-form-urlencoded`

| Key | Type | Value | Required |
|-----|------|-------|----------|
| `grade` | Text | Grade name (e.g., `BOP`) | Yes |
| `weight` | Text | Weight in grams | Yes |
| `volume` | Text | Volume in liters | No (default: 1.0) |

**Response:**
```json
{
  "grade": "BOP",
  "density_analysis": {
    "actual_density": 305.0,
    "standard_range": {
      "min": 280,
      "max": 320,
      "optimal": 300
    },
    "within_tolerance": true,
    "status": "Excellent",
    "deviation_percentage": 1.67
  },
  "pricing": {
    "base_price": 1200,
    "multiplier": 1.15,
    "final_price": 1380.0,
    "category": "Premium"
  }
}
```

---

### 5. Get Metrics
**GET** `/metrics`

**Response:**
```json
{
  "overall_accuracy": 92.5,
  "per_class_accuracy": {
    "BOP": 94.12,
    "BOPF": 91.67,
    "Dust": 95.45
  }
}
```

---

## 📮 Postman Setup

### Endpoint 1: Health Check
- Method: `GET`
- URL: `http://localhost:8000/health`

### Endpoint 2: Predict Grade
- Method: `POST`
- URL: `http://localhost:8000/predict`
- Body: `form-data`
  - Key: `image` | Type: **File** | Value: Select tea image
  - Key: `weight` | Type: Text | Value: `305`
  - Key: `volume` | Type: Text | Value: `1.0`

### Endpoint 3: Check Density
- Method: `POST`
- URL: `http://localhost:8000/check-density`
- Body: `x-www-form-urlencoded`
  - Key: `grade` | Value: `BOP`
  - Key: `weight` | Value: `305`
  - Key: `volume` | Value: `1.0`

---

## 📊 Request/Response Structure

### Request Format (Predict)
```
POST /predict
Content-Type: multipart/form-data

image: [binary file]
weight: 305
volume: 1.0
```

### Response Format (Predict)
```json
{
  "grade": "string",
  "confidence": "float (0-100)",
  "model_accuracy": "float (0-100)",
  "density_status": "string (Excellent/Good/Acceptable/Below Standard)",
  "entered_weight": "float",
  "standard_density_range": {
    "min": "float",
    "max": "float",
    "optimal": "float",
    "actual": "float"
  },
  "within_tolerance": "boolean",
  "price_category": "string (Premium/Standard/Below Standard)",
  "price_per_kg": "float",
  "quality_score": "float (0-100)",
  "recommendations": "string"
}
```

---

**Server URL:** `http://localhost:8000`  
**API Docs:** `http://localhost:8000/docs` (Interactive)