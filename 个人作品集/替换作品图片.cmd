@echo off
cd /d "%~dp0"
title Replace DaYE Portfolio Image

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0replace-image.ps1"

echo.
if errorlevel 1 (
  echo Image replacement failed. Please check the error message above.
) else (
  echo Image replaced. Upload the publish folder to Netlify again.
)
echo.
pause
