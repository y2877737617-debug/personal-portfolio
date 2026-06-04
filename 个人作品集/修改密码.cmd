@echo off
cd /d "%~dp0"
title Change DaYE Portfolio Password

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0change-password.ps1"

echo.
if errorlevel 1 (
  echo Password update failed. Please check the error message above.
) else (
  echo Password updated. Upload the publish folder to Netlify again.
)
echo.
pause
