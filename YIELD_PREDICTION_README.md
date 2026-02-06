# iTeaGrow - Yield Prediction Module

The **Yield Prediction Module** is a core component of the iTeaGrow platform, designed to accurately forecast tea crop production using advanced machine learning. By analyzing historical harvest data, labor inputs, and real-time weather conditions, it provides estate managers with actionable insights for the upcoming weeks.

---

## Key Features

### 1. AI-Powered Yield Forecasting
- **7-Day to 14-Day Forecasts**: Generates precise daily yield predictions (in kg).
- **Comprehensive Factor Analysis**: The model processes multiple critical variables:
    - **Harvest Data**: Previous day's crop yield (kg).
    - **Labor Metrics**: Number of pluckers assigned.
    - **Field Characteristics**: Division ID and Field Size (Effective Hectares).
    - **Quality Metrics**: Leaf Grade percentages (Good, Coarse, Damaged).
    - **Weather Integration**: Real-time forecasts for Temperature, Rainfall, and Humidity.

### 2. Automated Historical Tracking
- **Seamless Synchronization**: Every prediction is automatically captured and sent to the local backend.
- **Secure Storage**: Data is persisted in the **MongoDB** database (Collection: `tea_yield_mobile`).
- **Audit Trail**: Records include the full prediction result, input parameters, user identity, and timestamp.

### 3. Professional Reporting
- **Instant PDF Reports**: Generate comprehensive reports with a single tap.
- **Actionable Data**: Includes summary statistics (Total, Average, Min/Max Yield) and daily breakdowns.
- **Easy Sharing**: Reports can be immediately shared via email or messaging apps.

---

## Technical Workflow

The module employs a secure, hybrid architecture to ensure accuracy and data ownership.

1.  **Input Collection (Mobile App)**:
    - The Manager enters the daily variables (Labor, Crop, Field Size) into the Flutter app.
    - Data is validated to ensure integrity (e.g., percentages sum to 100%).

2.  **Prediction Engine (Cloud AI)**:
    - The app securely transmits inputs to the **Yield Prediction Microservice** (hosted on Railway).
    - The **XGBoost/CatBoost** model processes the inputs alongside live weather data from the estate's location.
    - The generated forecast is returned to the app.

3.  **Data Persistence (Local Backend)**:
    - Upon receiving the forecast, the app silently sends a copy to the **Local Backend API**.
    - The API authenticates the request and stores the record in **MongoDB** for long-term analysis.

---

## API Reference

### 1. Generate Prediction
- **Endpoint**: `POST /api/v1/predict` (External Service)
- **Purpose**: Generates the yield forecast.
- **Inputs**:
  - `division_id` (String): e.g., "LN", "NC"
  - `labor_total` (Int): Total workers
  - `field_size_ha` (Float): Field area
  - `crop_harvested_kg` (Float): Previous yield
  - `g_pct`, `c_pct`, `d_pct` (Float): Leaf quality grades
  - `prediction_days` (Int): 7 or 14

### 2. Store Record
- **Endpoint**: `POST /api/v1/yield/records` (Local Backend)
- **Purpose**: Archives the prediction for history.
- **Auth**: Bearer Token (Logged-in User).

### 3. Weather Data
- **Endpoint**: `GET /api/v1/weather` (External Service)
- **Purpose**: Fetches meteorological data for the estate region.

---

## User Guide

1.  **Access**: Log in as a **Manager** and select **Yield Prediction** from the Dashboard.
2.  **Configure**:
    - Choose the **Division** (Location).
    - Enter the **Field Size** and **Labor Count**.
    - Input the **Previous Crop** quantity and **Leaf Quality** percentages.
3.  **Execute**: Tap **Get Prediction**.
4.  **Review**: Analyze the projected yield chart and daily table.
5.  **Export**: Tap the **PDF** icon to download the official report.
