# Flutter Installation & Setup Guide

This guide will help you set up the development environment required to run **iTeaGrow**.

## 1. Prerequisites

Before installing Flutter, ensure you have:
*   **Operating System**: Windows 10 or later (64-bit).
*   **Disk Space**: 10 GB (for IDEs and tools).
*   **Tools**: Git for Windows (optional but recommended).

## 2. Install Flutter SDK

1.  **Download**: Get the latest stable release from the [Flutter Website](https://docs.flutter.dev/get-started/install/windows).
2.  **Extract**: Unzip the folder to a prominent place, e.g., `C:\flutter`.
    *   *Note: Do not install in "Program Files" due to permission issues.*
3.  **Update Path**:
    *   Search for "Edit the system environment variables" in Windows Start.
    *   Click **Environment Variables**.
    *   Under **User variables**, find `Path` and click **Edit**.
    *   Click **New** and add `C:\flutter\bin`.
    *   Click **OK** to save.

## 3. Verify Installation

Open a **new** Command Prompt or PowerShell window and run:
```bash
flutter doctor
```
Follow the output instructions to install any missing components (Android Studio, Visual Studio Build Tools, etc.).

## 4. Editor Setup (VS Code)

1.  Download and install **Visual Studio Code**.
2.  Open VS Code.
3.  Go to the **Extensions** tab (Ctrl+Shift+X).
4.  Search for and install the **Flutter** extension.
5.  Similarly, install the **Dart** extension.

## 5. Setting Up This Project

Once Flutter is ready:

1.  **Open Project**: Open the `flutter-iteagrow` folder in VS Code.
2.  **Get Dependencies**:
    Open the terminal (Ctrl+`) and run:
    ```bash
    flutter pub get
    ```
3.  **Generate Translations**:
    ```bash
    flutter gen-l10n
    ```

## 6. Troubleshooting Common Issues

*   **"flutter is not recognized..."**: Restart your computer or double-check the Path variable.
*   **Android License Issues**: Run `flutter doctor --android-licenses` and accept all.
*   **Device Not Found**: Ensure your phone has USB Debugging enabled, or use Chrome (`flutter run -d chrome`).

You are now ready to run the app! See `README.md` for running instructions.
