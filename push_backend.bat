@echo off
title Push Backend to GitHub
color 0B
echo ========================================================
echo        AAKRITI BACKEND - GITHUB UPLOADER
echo ========================================================
echo.
cd /d "%~dp0aakriti_backend"
echo Pushing code to GitHub (Aakriti_backend)...
git push -u origin main
echo.
echo ========================================================
echo If you saw "Branch 'main' set up to track", IT IS DONE!
echo ========================================================
pause
