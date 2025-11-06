@echo off
REM Start ASGI Server with WebSocket Support
echo ====================================
echo Starting Django ASGI Server (Daphne)
echo WebSocket Support: Enabled
echo Server Address: http://0.0.0.0:8000
echo WebSocket URL: ws://192.168.0.166:8000/ws/bus-locations/
echo ====================================
echo.
echo Press CTRL+C to stop the server
echo.

cd /d "%~dp0"
py -m daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application

pause
