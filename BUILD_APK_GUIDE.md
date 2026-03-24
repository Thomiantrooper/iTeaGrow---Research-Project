# Building iTeaGrow APK

## Option 1: GitHub Actions (Recommended - No Setup Required)


### To build debug:
flutter build apk --debug; flutter install --debug


The easiest way to get an APK is through GitHub Actions:

### Steps:
1. **Commit and push your changes:**
   ```bash
   git add .
   git commit -m "Build APK"
   git push origin tea-leaf-detector
   ```

2. **Go to GitHub Actions:**
   - Visit: https://github.com/YOUR_USERNAME/YOUR_REPO/actions
   - Click on the "Build Android APK" workflow
   - Click "Run workflow" button (or wait for automatic trigger)

3. **Download the APK:**
   - Once the workflow completes (green checkmark)
   - Click on the workflow run
   - Scroll down to "Artifacts"
   - Download `release-apk` or `debug-apk`

4. **Install on your phone:**
   - Transfer the APK to your phone
   - Enable "Install from unknown sources" in settings
   - Tap the APK file to install

---

## Option 2: Local Build (Requires Android SDK)

### Step 1: Install Android Studio (includes SDK)

1. Download Android Studio from:
   https://developer.android.com/studio

2. Run the installer and follow the setup wizard

3. During installation, select:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (optional)

### Step 2: Configure Flutter

After Android Studio installation:

```powershell
# Set Android SDK path (adjust path if different)
flutter config --android-sdk "C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk"

# Accept licenses
flutter doctor --android-licenses

# Verify setup
flutter doctor
```

### Step 3: Build the APK

```powershell
cd frontend\iTeaGrow---Research-Project

# Build debug APK (faster, larger)
flutter build apk --debug

# Build release APK (optimized, smaller)
flutter build apk --release
```

### Step 4: Find the APK

APK location:
```
frontend\iTeaGrow---Research-Project\build\app\outputs\flutter-apk\
├── app-debug.apk      (Debug version)
└── app-release.apk    (Release version)
```

---

## Option 3: Quick SDK Installation (Command Line)

If you don't want to install Android Studio:

### Download Command Line Tools:

```powershell
# Create SDK directory
mkdir C:\Android\Sdk
cd C:\Android

# Download command line tools (manual download required)
# Visit: https://developer.android.com/studio#command-tools
# Download: commandlinetools-win-xxxxx_latest.zip

# Extract to C:\Android\Sdk\cmdline-tools\latest\

# Set environment variables
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Android\Sdk", "User")

# Add to PATH
$path = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$path;C:\Android\Sdk\cmdline-tools\latest\bin;C:\Android\Sdk\platform-tools", "User")

# Restart terminal, then install required components
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Accept licenses
flutter doctor --android-licenses
```

---

## Bluetooth Testing on Phone

Once installed on your phone:

1. **Enable Bluetooth** on your phone
2. **Power on your ESP32/Arduino sensor**
3. **Open the app** and go to IoT section
4. **Tap "Scan"** to find nearby Bluetooth sensors
5. **Connect** to your sensor device
6. **View real-time data** from the sensor

### Sensor Device Names to Look For:
- `TeaSensor_XXX`
- `iTeaGrow_XXX`
- Any device with our service UUID

### Offline Mode:
- Data is stored locally when offline
- Syncs automatically when you have network
- Tap "Sync" button to force sync

---

## Troubleshooting

### APK won't install:
- Enable "Install from unknown sources" in phone settings
- On newer Android: Settings > Apps > Special access > Install unknown apps

### Bluetooth not working:
- Grant location permission (required for BLE scanning)
- Grant Bluetooth permission
- Ensure Bluetooth is enabled

### App crashes on start:
- Use debug APK for better error messages
- Check logcat: `adb logcat | grep flutter`

---

## Backend Connection

Make sure your phone can reach the backend:

1. **Find your computer's IP:**
   ```powershell
   ipconfig | findstr IPv4
   ```

2. **Update the app's API URL** (in app settings or code):
   ```
   http://YOUR_COMPUTER_IP:8000
   ```

3. **Ensure firewall allows port 8000**

4. **Both devices must be on same WiFi network**
