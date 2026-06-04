@echo off
cd /d "%~dp0"
title Update DaYE Portfolio

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-publish.ps1"

echo.
if errorlevel 1 (
  echo Portfolio update failed. Please check the error message above.
) else (
  echo Portfolio updated. Upload the publish folder to Netlify again.
)
echo.
pause
