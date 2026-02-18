# 📱 Flutter App Integration Guide: Tea Grading & Pricing

You asked: **"Which model do I use? PowderGrd only? MarketValue only? Or BOTH?"**

## ✅ The Answer: You Need BOTH Models

Think of it like a **Two-Step Process**:
1.  **Identity**: "What is this?" -> **PowderGrd Model** (Image -> Grade)
2.  **Value**: "How much is it worth?" -> **MarketValue Model** (Grade + Quality -> Price)

---

## 🔄 The Workflow (Pipeline)

Your Flutter app will orchestrate this improved workflow:

### **Step 1: The "Identity" Check (PowderGrd)**
*   **Input**: User takes a photo of the tea powder.
*   **Action**: Send image to `PowderGrd` model.
*   **Output**: 
    *   **Grade**: e.g., `"BOPF"` (This is CRITICAL input for the next step)
    *   **Confidence**: e.g., `0.94` (If low, ask user to retake photo)

### **Step 2: The "Quality" Check (User Input)**
*   **Input**: User manually rates visual qualities in the App UI.
    *   **Color**: Good/Average/Poor (1.0, 0.5, 0.0)
    *   **Aroma**: Strong/Average/Weak
    *   **Age/Freshness**: Fresh/Old
    *   **Quantity**: e.g., `500 kg`

### **Step 3: The "Valuation" (MarketValue Model)**
*   **Input**: You combine inputs from **Step 1** and **Step 2**:
    *   `Grade` (from Step 1)
    *   `Confidence` (from Step 1)
    *   `Color`, `Aroma`, `Age` (from Step 2)
    *   `Quantity` (from Step 2)
    *   `Market Price` (Current market rate, e.g., Rs. 1150)
*   **Action**: Send this combined data to `MarketValue` XGBoost model.
*   **Output**: **Fair Price** (e.g., Rs. 1057/kg)

---

## � Mobile App Inputs (From User)

### 1. From Camera/Image Model (Automated)
```json
{
  "grade": "BOPF",           // From your image classification model
  "confidence": 0.94          // From your image model
}
```

### 2. From User Dropdowns (30-second form)
```json
{
  "color": 1.0,               // Bright=1.0, Normal=0.5, Dull=0.0
  "aroma": 0.5,               // Strong=1.0, Moderate=0.5, Weak=0.0
  "age": 0.5,                  // Fresh=1.0, Medium=0.5, Old=0.0
  "quantity": 500              // kg (number input)
}
```

---

## 🌧️ External API Calls (App Fetches Automatically)

Do **NOT** ask the user for this data. Fetch it automatically to ensure accuracy.

### 1. Weather API (Rainfall) - Open-Meteo (FREE)
```python
# Mobile app makes this API call
import requests

def fetch_rainfall(lat=6.9003, lon=80.5966):
    """Fetch real rainfall for Hatton"""
    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": "2026-02-18",  # Today's date
        "end_date": "2026-02-18",
        "daily": "rain_sum",
        "timezone": "Asia/Colombo"
    }
    response = requests.get(url, params=params)
    data = response.json()
    return data['daily']['rain_sum'][0]  # Returns rainfall in mm
```

### 2. Market Price (Admin-Managed Database)
Instead of a public API (which doesn't exist for tea auctions), use an **"Owner-Managed"** approach:

*   **Logic**: Admin updates a simple database table or JSON file once a week.
*   **Why?**: Tea auctions happen weekly, so a weekly update is 100% accurate.
*   **Implementation**: Create an Admin Dashboard where you can input the latest Rs/kg for each grade.

```python
def fetch_market_price(grade="BOPF"):
    """Fetch latest price from YOUR database (Updated weekly by Admin)"""
    # 1. Connect to your Firebase/SQL database
    # 2. Query the latest price for the given grade
    # 3. Return the value
    
    # Example DB structure: { "BOPF": 1143, "BOP": 1120, ... }
    return db.get_price(grade) 
```

### 3. Exchange Rate API (FREE)
```python
def fetch_exchange_rate():
    """Get USD/LKR from Central Bank"""
    url = "https://api.cbsl.gov.lk/api/v1/exchange_rates"
    params = {
        "date": "2026-02-18",
        "currency": "USD"
    }
    response = requests.get(url, params=params)
    data = response.json()
    return data['spot']  # Returns LKR per USD
```

---

## 🤖 Backend API Endpoint (Your Server)

### Request from Mobile App:
```json
POST /predict-price
{
  "grade": "BOPF",
  "confidence": 0.94,
  "color": 1.0,
  "aroma": 0.5,
  "age": 0.5,
  "quantity": 500,
  "market_price": 1143,        // Auto-fetched by app
  "rainfall_mm": 125,           // Auto-fetched by app
  "exchange_rate": 309,         // Auto-fetched by app
  "season": "Peak"              // Auto-calculated by app (based on month)
}
```

### Response from Server:
```json
{
  "success": true,
  "prediction": {
    "price_per_kg": 1057.10,
    "total_value": 528550.00,
    "confidence": 0.94,
    "model_accuracy": {
      "mae": 14.82,
      "within_20": "71%",
      "r2": 0.969
    }
  },
  "breakdown": {
    "base_market": 1143,
    "grade_premium": 57,
    "quality_premium": 43,
    "quantity_effect": -186,
    "season_effect": 0
  },
  "timestamp": "2026-02-18T10:30:00Z"
}
```

## 🎯 Summary
*   **PowderGrd**: The "Eyes" (Sees the tea).
*   **MarketValue**: The "Brain" (Calculates the value).

**You cannot use MarketValue without PowderGrd**, because price depends heavily on the Grade!
