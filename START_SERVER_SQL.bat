@echo off
echo ================================================
echo   Bus Tracking System - Starting Server
echo   Database: SQL Server (Windows Authentication)
echo   Server: Daphne ASGI
echo ================================================
echo.

cd /d "%~dp0"

echo [1/3] Checking database connection...
python test_sql_connection.py
if errorlevel 1 (
    echo.
    echo ERROR: Database connection failed!
    echo Please check SQL Server is running.
    pause
    exit /b 1
)

echo.
echo [2/3] Applying database migrations...
python manage.py migrate --noinput

echo.
echo [3/3] Starting Daphne server...
echo.
echo ================================================
echo   Server will be available at:
echo   - http://localhost:8000
echo   - http://127.0.0.1:8000
echo.
echo   Press Ctrl+C to stop the server
echo ================================================
echo.

daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application

pause
