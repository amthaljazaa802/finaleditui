@echo off
set DJANGO_SETTINGS_MODULE=BusTrackingSystem.settings
cd /d "%~dp0"
python -m daphne -b 127.0.0.1 -p 8000 -v 2 BusTrackingSystem.asgi:application
