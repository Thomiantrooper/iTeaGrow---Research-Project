<div align="center">

# 🌱🤖 iTeaGrow  
### AI–IoT System for Tea Leaf Monitoring, Fertilization & Powder Grading

> **Transforming Sri Lanka’s tea industry with explainable, offline-capable intelligence**

![AI](https://img.shields.io/badge/AI-Computer%20Vision%20%7C%20ML-blue)
![IoT](https://img.shields.io/badge/IoT-ESP32%20%7C%20Sensors-green)
![Offline](https://img.shields.io/badge/Mode-Offline%20First-orange)
![Research](https://img.shields.io/badge/Type-Undergraduate%20Research-purple)
![License](https://img.shields.io/badge/License-Academic-lightgrey)

</div>

---

> *“I don’t grind leaves — I grind **data** to extract value.”* ☕

---

## 🌍 Project Overview

**iTeaGrow** is an integrated **AI–IoT research platform** designed to modernize decision-making across the Sri Lankan tea value chain.

The system replaces **subjective, manual assessments** with:

- 📊 **Data-driven intelligence**
- 🔍 **Explainable AI (XAI)**
- 🌐 **Offline-first rural deployment**

From **leaf plucking** to **factory-level tea powder valuation**, iTeaGrow improves **quality consistency, yield accuracy, and economic transparency**.

---

## 🎯 System Objectives

✔ Early detection of disease and environmental stress  
✔ Reduce subjectivity in leaf maturity and yield estimation  
✔ Objective tea powder grading & market price prediction  
✔ Offline functionality for remote plantations  
✔ Multilingual farmer-friendly interfaces  

---

## 🧠 High-Level Architecture

> **Hybrid Edge – Mobile – Cloud System**

<p align="center">
  <img src="https://github.com/user-attachments/assets/6a2fac10-94a0-4237-81b6-d8d2de991c8d" width="90%" />
</p>

---

## 🧩 Core Research Modules

### 🍃 1. Disease Detection & Environmental Monitoring  
**Lead:** *Kajanthan Kirubakaran (IT22197214)*

- Image-based detection of fungal & nutrient-related diseases  
- Correlation with temperature, humidity & soil moisture  
- Actionable treatment recommendations  

**Tech:** CNNs, Sensor Fusion, Grad-CAM

---

### 🌱 2. Leaf Maturity Detection & Yield Decision Support  
**Lead:** *Kanzurrizk M R A (IT22166524)*

- Classifies leaves as **Tender / Mature / Coarser**  
- Multi-leaf detection via instance segmentation  
- Predicts **factory-usable yield**, not raw harvest  

**Advanced:** What-if simulations, hybrid ML models, edge inference

---

### 🌾 3. Growth Analyzer & Fertilization Management  
**Lead:** *Ashwin Visvanathan (IT22204448)*

- Multi-depth NPK & pH sensing  
- TRI-compliant fertilizer rule engine  
- GSM-based SMS alerts  

**Design:** Solar-powered, offline IoT nodes

---

### ☕ 4. Tea Powder Grading & Market Valuation  
**Lead:** *Peiris M. D. T. N. (IT22109408)*

- Classification of tea powder grades (BOP, BOPF, PF1, Dust)  
- Regression-based market price estimation (Rs/kg)  
- Analyst dashboards & trend analytics  

---

## 🧪 Explainable AI (XAI)

- 🟢 **Grad-CAM** – visual explanation for vision models  
- 🟢 **SHAP** – interpretable tabular predictions  

> Ensures trust, auditability, and real-world adoption

---

## 🔌 Offline-First Design

- All AI inference runs **on-device**
- Logs stored locally (SQLite / SD Card)
- Optional cloud sync when connectivity exists  

Built for **remote tea estates** 🌄

---

## 🗣️ Multilingual User Interface

- 🇱🇰 Sinhala  
- 🇮🇳 Tamil  
- 🌍 English  

Designed for **farmers, supervisors, and analysts**

---

## ⚙️ Technology Stack

### 🧱 Hardware
- ESP32-WROOM-32  
- SIM800L GSM  
- NEO-6M GPS  
- NPK, pH, Moisture, Temperature Sensors  
- Solar–Battery Hybrid Power  

### 🧠 AI / ML
- YOLOv8n  
- MobileNetV3  
- ShuffleNetV2  
- Random Forest  
- XGBoost / CatBoost  
- TensorFlow Lite  
- OpenCV  

### 📱 Mobile & Frontend
- React Native  
- SQLite  

### 🖥️ Backend & Tools
- Node.js  
- Firebase  
- Google Cloud Platform  
- Python (Pandas, NumPy, Scikit-learn)  

---

## 🚀 Deployment (High Level)

1️⃣ Flash ESP32 firmware with TRI rules  
2️⃣ Calibrate sensors using standard solutions  
3️⃣ Install Android APK  
4️⃣ Pair IoT units via Bluetooth  
5️⃣ Operate fully offline or sync to cloud  

---

## 👥 Contributors

- **Kajanthan Kirubakaran (IT22197214)** – Tea Leaf Disease Detection & Environmental Monitoring
- **Kanzurrizk M R A (IT22166524)** – Tea Leaf Maturity Detection & Yield Decision Support  
- **Ashwin Visvanathan (IT22204448)** – Soild Monitoring  & Fertilization Management with enhanced IOT service. 
- **Peiris M. D. T. N. (IT22109408)** – Tea Powder Grading & Market Valuation  

---

## 📚 Research Context

This project is developed as part of an **undergraduate research initiative** applying:

> **AI • IoT • Explainable Machine Learning**  
to **real-world agricultural decision systems** in Sri Lanka 🇱🇰

---

<div align="center">

🌱 *From leaf to market — intelligently, transparently, offline.* 🤖  

</div>

<div align="center">

   
🔮 Upcoming Enhancements — iTeaBot (Next Phase) 📌

</div>

🤖 iTeaBot: Intelligent Assistant (Planned Extension)

                 🚧  iTeaBot — Under Development  🚧
            ───────────────────────────────────────────

                  🤖
                ┌───────────────────────┐
                │  Hi! I’m evolving…    │
                │ Soon I’ll explain,    │
                │ predict & guide tea   │
                │ decisions in real time│
                └──────────┬────────────┘
                           │
                      🤖  iTeaBot
                           │
        ───────────────────┼──────────────────────────
        🌱 Soil   📸 Leaf   🌧️ Climate   📊 Yield   ☕ Powder



