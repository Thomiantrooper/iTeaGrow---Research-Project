# iTeaGrow 🌿

> **Next-Gen AI-IoT System for Precision Tea Cultivation**
> *Developed for the Tea Research Institute (TRI) of Sri Lanka*

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B.svg?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![TensorFlow Lite](https://img.shields.io/badge/TFLite-On--Device-FF6F00.svg?style=for-the-badge&logo=tensorflow&logoColor=white)
![IoT](https://img.shields.io/badge/IoT-BLE%20%2F%20WiFi-32DE84.svg?style=for-the-badge&logo=arduino&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

**iTeaGrow** is a comprehensive mobile decision support system designed to modernize tea cultivation. By integrating **Artificial Intelligence (Computer Vision)** and **Internet of Things (IoT)** sensors, standardizes field operations, optimizes fertilizer usage, and ensures tea powder quality through a strict **Role-Based Access Control (RBAC)** architecture.

---

## 🏗️ Architecture & Design

### Design Principle: 70:20:10 Rule
The UI/UX is tailored to specific user personas:
*   **70% (Farmers)**: Simple, large-button interfaces for field use. Focus on speed and accessibility.
*   **20% (Managers)**: Analytical dashboards for decision making. Focus on data visualization.
*   **10% (Admins)**: Complex configuration screens. Focus on system control.

### Technical Architecture
The project follows a **Feature-First Clean Architecture**:
```
lib/
├── core/                   # Shared logic (Theme, Routes, ML Services)
└── features/               # Modular Feature Layers
    ├── auth/               # Authentication & RBAC
    ├── dashboard/          # Role-specific UI layouts
    ├── leaf_maturity/      # Computer Vision (TFLite)
    ├── disease_detection/  # Disease Diagnostics
    ├── soil_fertilization/ # NPK Recommendations
    └── iot_connectivity/   # BLE Sensor Interface
```

---

## ✨ Key Features

| Feature | Farmer (Field) | Manager (Office) | Admin (System) |
| :--- | :---: | :---: | :---: |
| **Login** | ✅ | ✅ | ✅ |
| **Leaf Maturity Scan** | ✅ (Capture) | ❌ | ❌ |
| **Disease Detection** | ✅ (Diagnose) | 👁️ (View Reports) | ❌ |
| **IoT Readings** | ✅ (Real-time) | ✅ (Historical) | ✅ (Status) |
| **Fertilizer Recs** | ✅ (Apply) | ✅ (Plan) | ❌ |
| **Yield Prediction** | ❌ | ✅ (What-If Sim) | ❌ |
| **Powder Grading** | ❌ | ✅ (Analyze) | ❌ |
| **User Management** | ❌ | ❌ | ✅ |
| **Device Config** | ❌ | ❌ | ✅ |

---

## 🤖 Machine Learning Models Setup (CRITICAL)

This project uses a hybrid approach for AI.

### 📱 1. Mobile App Models (TFLite)
The mobile app performs **offline inference** using TensorFlow Lite.

*   **Location**: You must place your model files in `assets/models/`.
*   **Required Files**:
    *   `disease_model.tflite` (Quantized model for disease detection)
    *   `maturity_model.tflite` (Quantized model for leaf maturity)
    *   `labels.txt` (Class labels for the models)

> **⚠️ NOTE**: If these files are missing, the app will use dummy data for demonstration purposes.

### 🖥️ 2. Backend / Training Files (.pkl, .h5, .keras)
**DO NOT** place your training files (Pickle, Keras, H5) inside the Flutter project `assets` folder.
*   **Reason**: These files are too large and widely unsupported by mobile TFLite interpreters.
*   **Action**:
    *   Keep them in a separate `ml_training/` folder outside the `lib/` directory.
    *   Convert `.h5`/`.keras` models to `.tflite` using the Python TFLite Converter.
    *   Port `.pkl` logic (e.g., Random Forest) to Dart code manually if simple, or host a Python API if complex.

---

## 🚀 Installation & Setup

### Prerequisites
*   **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Version 3.10+)
*   **VS Code** with Flutter/Dart Extensions.
*   **Git**: For version control.

### Step 1: Clone the Repository
```bash
git clone https://github.com/Thomiantrooper/iTeaGrow---Research-Project.git
cd iTeaGrow---Research-Project
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Setup Assets (Optional but Recommended)
If you have custom images or models:
1.  Create an `assets/` folder in the root.
2.  Add subfolders `images/` and `models/`.
3.  Place your files there.

### Step 4: Run the App
Connect a device (or use an emulator) and run:
```bash
flutter run
```

---

## 🔐 Demo Credentials

Use these accounts to explore the Role-Based features:

| Role | Username | Password | Features Accessible |
| :--- | :--- | :--- | :--- |
| **Farmer** | `farmer` | `farmer123` | Leaf Scan, Disease Detect, IoT View |
| **Manager** | `manager` | `manager123` | Yield Prediction, Powder Grading, Analytics |
| **Admin** | `admin` | `admin123` | User Management, Sensor Config |

---

## 🔧 Troubleshooting

### "Undefined name 'AppLocalizations'"
*   **Fix**: Run `flutter pub get` and restart your IDE. The localizations are auto-generated.

### "Asset not found" errors
*   **Fix**: Ensure your `pubspec.yaml` has the correct asset paths uncommented:
    ```yaml
    flutter:
      assets:
        - assets/models/
        - assets/images/
    ```

### "CocoaPods not installed" (macOS)
*   **Fix**: Run `sudo gem install cocoapods` followed by `cd ios && pod install`.

---

## 👥 Contributing
1.  Fork the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

