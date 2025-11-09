@echo off
echo Building User App Release APK with shader crash fix...
echo.

REM Set environment variables to bypass shader compilation issues
set FLUTTER_BUILD_MODE=release
set FLUTTER_SHADER_COMPILER_LEGACY=1

REM Build with specific flags to avoid crashes
cd /d "%~dp0..\.."
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo BUILD SUCCESS!
    echo ========================================
    echo APK Location: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
    echo.
) else (
    echo.
    echo ========================================
    echo BUILD FAILED! 
    echo ========================================
    echo.
)

pause
