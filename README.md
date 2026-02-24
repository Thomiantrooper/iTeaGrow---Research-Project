# 🌱 iTeaGrow - Tea Soil Health IoT API

A high-performance FastAPI backend designed to monitor tea plantation soil health via IoT sensors. The system integrates real-time MQTT data processing, Machine Learning (XGBoost) for soil classification, and automated fertilizer recommendations.

---

## 🚀 Features

- **7-Feature Soil Analysis**: Processes Nitrogen (N), Phosphorus (P), Potassium (K), pH, Electrical Conductivity (EC), Temperature, and Humidity.
- **ML-Powered Predictions**: Uses a trained XGBoost model to classify soil health into `Good`, `Fair`, or `Poor`.
- **Automated Fertilizer Recommendations**: Provides specific prescriptions based on nutrient deficiencies and predicted soil health.
- **MQTT Integration**: Real-time listener for IoT devices (ESP32/ESP8266) via HiveMQ Cloud.
- **Database Persistence**: Stores all historical sensor data and predictions in MongoDB.
- **Deployment Ready**: Optimized for **Railway** with Nixpacks support and health checks.

---

## 🛠️ Technology Stack

- **Framework**: FastAPI (Python 3.12)
- **Database**: MongoDB (Motor / PyMongo)
- **Messaging**: MQTT (Paho-MQTT)
- **Machine Learning**: XGBoost, Scikit-learn, Joblib
- **Deployment**: Railway (Nixpacks), Uvicorn

---

## 📂 Project Structure

```text
Tea-Soil-IoT-API/
├── app/
│   ├── api/            # API Routes (Health, Latest Data, Hectare lookup)
│   ├── core/           # Configuration and Environment Management
│   ├── database/       # MongoDB Connection and Utilities
│   ├── models/         # Pydantic Schemas & ML Model Binary (.pkl)
│   ├── mqtt/           # MQTT Client and Message Handler
│   └── services/       # ML Inference & Fertilizer Logic
├── tests/              # Integration and ML Pipeline Tests
├── requirements.txt    # Production Dependencies
├── railway.json        # Railway Deployment Config
└── Procfile            # Deployment Worker Config
```

---

## 📡 MQTT Payload Format

The IoT devices should publish a JSON payload to the configured topic (e.g., `test/iot`):

```json
{
  "device_id": "esp32_01",
  "hectare_id": 1,
  "N": 150.5,
  "P": 45.2,
  "K": 180.3,
  "pH": 6.2,
  "EC": 0.85,
  "temperature": 24.5,
  "humidity": 68.0
}
```

---

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | `GET` | System health check (API, DB, MQTT) |
| `/farm/latest` | `GET` | Retrieve the latest predictions across the farm |
| `/hectare/{id}`| `GET` | Get historical data for a specific hectare |

---

## ⚙️ Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone -b iot_backend https://github.com/Thomiantrooper/iTeaGrow---Research-Project.git
   cd Tea-Soil-IoT-API
   ```

2. **Setup Environment**:
   Create a `.env` file based on `.env.example`:
   ```bash
   MONGO_URL=your_mongodb_url
   MQTT_BROKER=your_hivemq_broker
   MQTT_USERNAME=your_username
   MQTT_PASSWORD=your_password
   ```

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Run Locally**:
   ```bash
   python run.py
   ```

---

## ☁️ Deployment (Railway)

The project is pre-configured for Railway. Simply connect your GitHub repository to a new Railway project and provide the variables defined in `.env.example` in the **Variables** tab.

---

## 🧪 Testing

Use the comprehensive test script to verify the entire pipeline:
```bash
python test_all_services.py
```
This script validates the API, connects directly to the ML model, generates 25 mock records, and verifies their persistence in MongoDB.
