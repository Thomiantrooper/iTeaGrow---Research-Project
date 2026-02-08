# iTeaGrow - Mobile Deployment Manual

**Goal:** Run the iTeaGrow app on an Android phone with full backend connectivity.

---

## 🛑 REQUIREMENT: You need 2 Terminal Windows
To run the app correctly, you will need **two separate PowerShell windows** open at the same time.
*   **Terminal 1:** Runs the Backend (Must stay open forever).
*   **Terminal 2:** Runs the Bridge & The App.

---

## 🚀 Daily Start-Up Routine (Step-by-Step)

### Step 1: Open Terminal 1 (Backend)
1.  Open PowerShell in the project folder: `iTeaGrow-Prod`
2.  Run this command:
    ```powershell
    .\start_backend.bat
    ```
3.  **Wait for Success Message:**
    > `Starting FastAPI server on http://localhost:8000`
    > `Application startup complete.`
4.  **DO NOT CLOSE THIS WINDOW.** Minimize it.

---

### Step 2: Open Terminal 2 (Bridge & App)
1.  Open a **NEW** PowerShell window in the same folder.
2.  **Plug in your phone** via USB.
3.  **Run the Bridge Command (CRITICAL):**
    This lets your phone talk to the PC. Run this **exact** command:
    
    ```powershell
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
    ```
    
    *   **Success Check:** It should print just one number: `8000`.
    *   *If it says nothing:* Run it again.
    *   *If it says "more than one device":* You have an emulator open. Close it.
    
    > **⚠️ IMPORTANT:** If you unplug the cable, **RUN THIS COMMAND AGAIN** immediately after replugging.

4.  **Find your Device ID:**
    Run:
    ```powershell
    flutter devices
    ```
    *   **Example Output:**
        ```text
        SM A556E (mobile) • R5CX23RLBSE • android-arm64 • Android 14 (API 34)
        ```
    *   Copy the code from the second column (e.g., `R5CX23RLBSE`).

5.  **Run the App:**
    Replace `<YOUR_ID>` with the code you copied:
    ```powershell
    flutter run -d <YOUR_ID>
    ```
    *   **Real Example (for reference):** `flutter run -d R5CX23RLBSE`

---

## 💡 Pro Tip: Stop typing long paths!

You can teach your computer where `adb` is so you don't have to type `%LOCALAPPDATA%...` every time.

1.  **Find your Path:**
    It usually looks like this (replace `YourUserName`):
    `C:\Users\YourUserName\AppData\Local\Android\Sdk\platform-tools`
    
    *(On this specific machine, it is: `C:\Users\HP\AppData\Local\Android\Sdk\platform-tools`)*

2.  **Add to Windows:**
    *   Press `Windows Key`, type **"env"**, and select **Edit the system environment variables**.
    *   Click **Environment Variables**.
    *   In the top box (**User variables**), find **Path** -> **Edit** -> **New**.
    *   Paste the path from Step 1.
    *   Click **OK** -> **OK** -> **OK**.

3.  **Restart Terminal:**
    Close all black windows and open them again. Now you can just type:
    `adb reverse tcp:8000 tcp:8000`

---

## ❓ Troubleshooting (Q&A)

**Q: The app opens, but I can't login. It just spins.**
*   **A:** Your "Bridge" is down.
    1.  Go to **Terminal 2**.
    2.  Run the bridge command again (`adb reverse...`).
    3.  Restart the app.

**Q: "adb" is not recognized as a command.**
*   **A:** You haven't done the "Pro Tip" setup yet.
    *   **Fix:** Use the long command starting with `"%LOCALAPPDATA%..."` shown in Step 2.

**Q: "Device not found" or empty list.**
*   **A:** Your computer doesn't see the phone.
    1.  Check USB cable.
    2.  Check if phone screen has a popup "Allow USB Debugging?". Tap **Allow**.
    3.  Install Samsung USB Drivers.

**Q: Which IP address should I use in the app?**
*   **A:** None! The app is configured to use `localhost` automatically. The `adb reverse` command makes this work magically.
