@echo off
title Aakriti Diagnostic Backend Server
color 0A
echo ========================================================
echo   AAKRITI ULTRASOUND & DIAGNOSTIC - BACKEND SERVER
echo ========================================================
echo.
echo Starting FastAPI Backend on 0.0.0.0:8000...
echo Both User App and Admin App on phone will connect to this.
echo Keep this window open while testing the apps.
echo.
cd /d "%~dp0aakriti_backend"
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
