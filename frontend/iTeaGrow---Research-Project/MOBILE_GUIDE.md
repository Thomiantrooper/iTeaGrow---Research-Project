# 📱 Mobile Deployment & Troubleshooting Guide (Android)

This guide covers how to install iTeaGrow on your Android device and fix common connection or build issues.

---

## ✅ Part 1: Initial Setup (Do this once)

### 1. Enable Developer Options
1.  Open **Settings** on your phone.
2.  Go to **About Phone** > **Software Information**.
3.  Tap **Build Number** 7 times rapidly until it says "You are now a developer!".

### 2. Enable USB Debugging
1.  Go back to **Settings** > **Developer Options** (usually at the very bottom).
2.  Scroll down and enable **USB Debugging**.
3.  (Optional but recommended) Enable **Stay Awake** so screen doesn't turn off during builds.

---

## 🚀 Part 2: Running the App

### 1. Connect via USB
1.  Plug your phone into the PC.
2.  **CRITICAL STEP**: Swipe down your notification shade.
3.  Look for "USB for charging". Tap it and select **"File Transfer"** or **"MTP"**.
4.  Look for a popup on your phone screen: **"Allow USB Debugging?"**.
5.  Check "Always allow from this computer" and tap **Allow**.

### 2. Launch the App
Run this command in your VS Code terminal (Terminal -> New Terminal):

```powershell
C:\ProgramData\flutter\bin\flutter.bat run
```

*Note: The first build can take 2-5 minutes. Please be patient.*

---

## 🛠️ Part 3: Troubleshooting Common Issues

### ❌ Issue 1: "Flutter is not recognized"
**Symptom**: You type `flutter run` and see red error text.
**Fix**: You need to add Flutter to your system Path, OR just use the full path command:
```powershell
C:\ProgramData\flutter\bin\flutter.bat run
```
```powershell
C:\ProgramData\flutter\bin\flutter.bat run -d R5CX23RLBSE
```

### ❌ Issue 2: "No devices found"
**Symptom**: `flutter devices` shows only Windows/Chrome, not your phone.
**Fixes**:
1.  **Check Cable**: Ensure your cable is a **Data Cable**, not just a cheap charging cable. Try a different cable.
2.  **Check Mode**: Ensure phone is in "File Transfer" mode (see Part 2, Step 1).
3.  **Restart ADB**: Run the following command to refresh connections:
    ```powershell
    C:\ProgramData\flutter\bin\flutter.bat devices
    ```

### ❌ Issue 3: "Missing AndroidManifest" / Build Failures
**Symptom**: Errors saying `android/` folder missing or Gradle build failed.
**Fix**: Repair the android project files:
```powershell
C:\ProgramData\flutter\bin\flutter.bat create --platforms android .
```

### ❌ Issue 4: "Install Failed" or "App not showing"
**Symptom**: The terminal says "Built" but app isn't on phone.
**Fix**:
1.  Uninstall any existing version of "iTeaGrow" or "Flutter Demo" from your phone.
2.  Run `flutter clean` then run the app again.

### ❌ Issue 5: "SocketException" or "Connection Aborted"
**Symptom**: Error like `java.net.SocketException: Connection reset` during `assembleDebug`.
**Cause**: The download of Gradle or dependencies was interrupted (Weak internet, Firewall, or Antivirus).
**Fix**:
1.  **Retry**: Simply run the command again. It usually works the second time.
2.  **Stable Internet**: Ensure you are on a stable connection.
3.  **Performance Fix**: I have updated `android/gradle.properties` to make builds more robust.

---

## 📦 How to Share the App (APK)
To create a file you can send via WhatsApp/Email:

1.  Run the build command:
    ```powershell
    C:\ProgramData\flutter\bin\flutter.bat build apk --release
    ```
2.  The file will be created at:
    `build/app/outputs/flutter-apk/app-release.apk`
3.  Copy this file to your phone and install it manually.
