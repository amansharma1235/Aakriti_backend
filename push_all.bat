@echo off
title Push All Code to GitHub
color 0B
echo ========================================================
echo        AAKRITI COMPLETE PROJECT - GITHUB UPLOADER
echo ========================================================
echo.
cd /d "%~dp0"
echo Staging changes...
git add .
set /p commit_msg="Enter commit message (or press enter for default): "
if "%commit_msg%"=="" set commit_msg=Update project codebase
git commit -m "%commit_msg%"
echo Pushing code to GitHub...
git push -u origin main
echo.
echo ========================================================
echo Done! Code pushed to GitHub successfully.
echo ========================================================
pause
