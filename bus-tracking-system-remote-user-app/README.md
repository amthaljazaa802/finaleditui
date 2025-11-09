# busesssss

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```markdown
# Bus Tracking App

Feature-focused Flutter app to view bus lines, stops, live buses, submit complaints, and scan QR for payments.

## Run it

1. Install Flutter (3.24+ recommended) and Android Studio/SDK.
2. Fetch packages and generate icons (optional):

	- flutter pub get
	- flutter pub run flutter_launcher_icons

3. Start a simulator/emulator or connect a device.
4. Run the app:

	- flutter run

## Permissions

Android: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, CAMERA are declared in `android/app/src/main/AndroidManifest.xml`.

iOS: `NSLocationWhenInUseUsageDescription` and `NSCameraUsageDescription` are declared in `ios/Runner/Info.plist`.

## Assets

Assets are under `lib/assets/` and declared in `pubspec.yaml`.

## Architecture

- Services: `TrackingService` provides cached lists and streams for buses, stops, and lines.
- State management: BLoC for map, routes, and complaints.
- UI: Feature-first layout under `lib/screens/`.
# Bus Tracking App

Feature-focused Flutter app to view bus lines, stops, live buses, submit complaints, and scan QR for payments.

## Run it

1. Install Flutter (3.24+ recommended) and Android Studio/SDK.
2. Fetch packages and (optionally) generate icons.

Commands (PowerShell):

```powershell
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

If you see authorization errors from pub.dev, add a token then retry:

```powershell
dart pub token add https://pub.dev
flutter pub get
```

## Permissions

- Android: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, CAMERA are in `android/app/src/main/AndroidManifest.xml`.
- iOS: `NSLocationWhenInUseUsageDescription` and `NSCameraUsageDescription` are in `ios/Runner/Info.plist`.

## Assets

Assets live under `lib/assets/` and are declared in `pubspec.yaml`.

## Architecture

- Services: `TrackingService` provides cached lists and streams for buses, stops, and lines.
- Repository: `TransportRepository` decouples BLoCs from the service.
- State management: BLoC for map, routes, and complaints.
- UI: Feature-first layout under `lib/screens/`.

## Testing

To run unit tests (requires dev dependencies):

```powershell
flutter pub add --dev bloc_test
flutter pub add --dev flutter_lints
flutter test
```

If you're offline or blocked by pub.dev, tests may be excluded by the analyzer until dependencies are installed.

## Troubleshooting

- If the analyzer complains about lints not found, run `flutter pub get`.
- To remove a stray folder named with a leading space (`lib/screens/map/ widgets/`), delete it in Explorer or run:

```powershell
Remove-Item -LiteralPath "$(Resolve-Path .)\lib\screens\map\ widgets" -Recurse -Force
```

- Location requires enabling device location services and granting permission.
- Camera (QR scan) requires camera permission and a supported device.
