@echo off
REM =====================================================================
REM Bus Tracking System - Quick Start Script
REM =====================================================================

echo ================================================
echo   Bus Tracking System - Backend Quick Start
echo ================================================
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo [1/6] Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        echo Please make sure Python is installed
        pause
        exit /b 1
    )
) else (
    echo [1/6] Virtual environment already exists
)

REM Activate virtual environment
echo [2/6] Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

REM Install dependencies
echo [3/6] Installing dependencies (including SQL Server support)...
pip install -q django djangorestframework django-cors-headers channels daphne python-dotenv mssql-django pyodbc
if errorlevel 1 (
    echo WARNING: Some packages may have failed to install
)

REM Check if .env exists
if not exist ".env" (
    echo [4/6] Creating .env file...
    copy .env.example .env
    echo WARNING: Please update .env with your settings
) else (
    echo [4/6] .env file already exists
)

REM Apply migrations
echo [5/6] Applying database migrations...
python manage.py makemigrations
python manage.py migrate
if errorlevel 1 (
    echo WARNING: Migration issues detected
)

REM Get IP address
echo [6/6] Getting network information...
echo.
echo ================================================
echo   Network Information
echo ================================================
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    echo Your IP Address: %%a
)
echo.

echo ================================================
echo   Setup Complete!
echo ================================================
echo.
echo Backend will start on:
echo   - Local: http://127.0.0.1:8000
echo   - Network: http://YOUR-IP:8000
echo.
echo IMPORTANT NEXT STEPS:
echo 1. Make sure SQL Server is running: Get-Service -Name "MSSQL$SQLEXPRESS"
echo 2. Create database: See SQL_SERVER_SETUP.md for instructions
echo 3. Run migrations: python manage.py migrate
echo 4. Create superuser: python manage.py createsuperuser
echo 5. Create authentication tokens (see COMPLETE_SETUP_GUIDE.md)
echo 6. Update mobile apps with your IP and tokens
echo.
echo NOTE: If SQL Server is not set up yet, read SQL_SERVER_SETUP.md first!
echo.
echo Starting server in 5 seconds...
timeout /t 5 /nobreak

REM Start server
echo.
echo Starting Django development server...
echo Press Ctrl+C to stop the server
echo.
python manage.py runserver 0.0.0.0:8000
