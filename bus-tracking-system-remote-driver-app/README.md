# driver_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run & Setup

1. Copy `.env.example` to `.env` and fill in your API values:

```
API_BASE_URL=https://api.example.com
AUTH_TOKEN=your_token_here
```

2. Run the app (Android on Windows):

```powershell
flutter pub get
flutter run
```

3. Platform notes:
 - Android: Add required permissions in `android/app/src/main/AndroidManifest.xml` for foreground and background location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` on Android 10+). Use a foreground service notification for reliable background tracking.
 - iOS: Add `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` and enable `UIBackgroundModes` for `location` in `ios/Runner/Info.plist`. Building for iOS requires macOS.

4. Tests:

```powershell
flutter test
```

## Continuous Integration

This repository includes a GitHub Actions workflow at `.github/workflows/flutter-ci.yml` which runs `flutter analyze` and `flutter test` on pushes and PRs. The workflow caches the Dart pub cache to speed up runs.

If CI fails, run the same commands locally to reproduce and fix issues before pushing.

## Android toolchain (brief)

On Windows, to build for Android you need the Android SDK and Android Studio (or the command-line SDK):

1. Install Android Studio and open SDK Manager to install SDK, platform-tools and build-tools.
2. Set environment variables (example):

```powershell
setx ANDROID_HOME "C:\\Users\\<you>\\AppData\\Local\\Android\\sdk"
setx PATH "%PATH%;%ANDROID_HOME%\\platform-tools"
```

3. Install an emulator (AVD) or connect a physical device and run `flutter doctor` until the Android toolchain is green.


5. Security:
 - Do not commit `.env` with real secrets. Use `.env.example` as a template and CI secrets for production tokens.

