@echo off
cd /d "%~dp0"
title Add DaYE Portfolio Project
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0add-project.ps1"
echo.
if errorlevel 1 (echo Add project failed. Check the message above.) else (echo Project added. Upload publish to Netlify again.)
echo.
pause
