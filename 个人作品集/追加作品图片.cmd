@echo off
cd /d "%~dp0"
title Add DaYE Portfolio Image
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0add-image.ps1"
echo.
if errorlevel 1 (echo Add image failed. Check the message above.) else (echo Image added. Upload publish to Netlify again.)
echo.
pause
