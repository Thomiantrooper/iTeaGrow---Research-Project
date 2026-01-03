# iTeaGrow: AI-IoT System For Tea Leaf Monitoring, Fertilization, and Powder Grading

---

## Project Overview

**iTeaGrow** is an integrated AI–IoT research platform designed to modernize decision-making in the Sri Lankan tea industry.  
The system replaces subjective, manual assessment practices with **data-driven, explainable, and offline-capable intelligence** across the full tea value chain from field-level leaf plucking to factory-grade yield estimation and market valuation.

The platform combines **computer vision**, **machine learning**, and **edge IoT sensing** to support smallholder farmers, estate supervisors, and factory-level analysts in improving productivity, consistency, and economic outcomes.

---

## System Objectives

- Enable early detection of disease and environmental/soil-related stress
- Reduce subjectivity in leaf maturity assessment and yield forecasting to improve harvesting quality and factory-usable yield consistency  
- Provide transparent, data-backed tea powder grading and valuation  
- Support rural deployments through offline system design  

---

## High-Level System Architecture

iTeaGrow operates as a **hybrid edge–mobile–cloud architecture**
<img width="1536" height="1024" alt="HA" src="https://github.com/user-attachments/assets/6a2fac10-94a0-4237-81b6-d8d2de991c8d" />

---

## Core Research Modules

### 1. Disease Detection & Environmental Monitoring  
**Lead: Kajanthan K (IT22197214)**

#### Scope
Automated detection of visible tea leaf diseases and stress indicators, synchronized with real-time environmental data.

#### Key Capabilities
- Image-based detection of fungal and nutrient-related diseases  
- Correlation with temperature, humidity, and soil moisture  
- Actionable treatment recommendations  

---
### 1. Leaf Maturity Detection & Yield Decision Support  
**Lead: Kanzurrizk M R A (IT22166524)**

#### Scope
This module addresses inaccuracies in manual leaf grading and traditional yield estimation by integrating **vision-based maturity detection** with **quality-adjusted yield prediction**.

#### Key Capabilities
- Real-time classification into *Tender*, *Mature*, and *Coarser* stages  
- Multi-leaf detection using instance segmentation
- Predicts factory-usable yield using a hybrid machine learning model
- Supports "What-If" simulations adjusting Good Leaf % for economic forecasting

---

### 3. Growth Analyzer & Fertilization Management  
**Lead: Ashwin V (IT22204448)**

#### Scope
Data-driven fertilization planning aligned with **Tea Research Institute (TRI)** standards.

#### Key Capabilities
- Multi-depth NPK and pH sensing  
- Rule-based fertilizer recommendation engine  
- GSM-based SMS alerts for corrective actions  

---

### 4. Tea Powder Grading & Market Valuation  
**Lead: Peiris M. D. T. N. (IT22109448)**

#### Scope
Objective grading and valuation of processed tea powders to replace subjective auction-based assessment.

#### Key Capabilities
- Classification of powder grades (e.g., BOP, BOPF, Dust, PF1)  
- Regression-based market price estimation (Rs/kg)  
- Analyst dashboards with trend visualization  

---

## Key Technical Features

### Explainable AI (XAI)
- Grad-CAM heatmaps highlight regions influencing model predictions and SHAP to verify the predicted tabular form
- Improves trust and auditability for supervisors and managers  

### Offline Design
- All inference and logging functions operate without internet  
- Designed for remote plantation environments  

### Multilingual User Interface
- Sinhala, Tamil, and English support  

### Continuous Learning
- User feedback loop enables periodic dataset refinement  

---

## Technology Stack

### Hardware
- ESP32-WROOM-32  
- SIM800L GSM module  
- NEO-6M GPS  
- NPK, pH, moisture, temperature sensors  
- Solar–battery hybrid power system  

### AI / Machine Learning
- YOLOv8n
- Random Forest  
- MobileNetV3
- ShuffleNetV2  
- XGBoost
- CatBoost
- TensorFlow Lite  
- OpenCV  

### Mobile & Frontend
- React Native  
- SQLite (local storage)  

### Backend & Tools
- Node.js  
- Firebase  
- Google Cloud Platform  
- Python (Pandas, NumPy, Scikit-learn)  

---

## Installation & Deployment (High Level)

1. **IoT Units**
   - Flash ESP32 firmware with TRI rule configuration  
   - Calibrate sensors using standard solutions  

2. **Mobile Application**
   - Install APK on Android device
   - Pair with IoT units via Bluetooth  

3. **Data Handling**
   - Store logs locally on SD card  
   - Optional cloud sync for analytics  

---

## Contributors

- **Kajanthan Kirubakaran (IT22197214)** – Tea Leaf Disease Detection & Environmental Monitoring
- **Kanzurrizk M R A (IT22166524)** – Tea Leaf Maturity Detection & Yield Decision Support  
- **Ashwin Visvanathan (IT22204448)** – Soild Monitoring  & Fertilization Management  
- **Peiris M. D. T. N. (IT22109408)** – Tea Powder Grading & Market Valuation  

---

## Research Context

This project is developed as part of an undergraduate research initiative focused on applying **AI, IoT, and Explainable ML** to real-world agricultural decision systems in Sri Lanka.

