$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root "script.js"
$updateScript = Join-Path $root "update-publish.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  Change DaYE portfolio password" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""

$newPassword = Read-Host "Enter the new password"
if ([string]::IsNullOrWhiteSpace($newPassword)) {
  throw "Password cannot be empty."
}
if ($newPassword.Contains('"') -or $newPassword.Contains("\")) {
  throw 'Password cannot contain double quotes or backslashes.'
}

$source = [System.IO.File]::ReadAllText($scriptPath, [System.Text.Encoding]::UTF8)
$pattern = 'const accessPassword = "[^"]*";'
$replacement = 'const accessPassword = "' + $newPassword + '";'

if (-not [System.Text.RegularExpressions.Regex]::IsMatch($source, $pattern)) {
  throw "Could not find the password setting in script.js."
}

$updated = [System.Text.RegularExpressions.Regex]::Replace($source, $pattern, $replacement, 1)
[System.IO.File]::WriteAllText($scriptPath, $updated, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Password updated. Rebuilding publish files..." -ForegroundColor Yellow
& $updateScript

Write-Host ""
Write-Host "Password change complete." -ForegroundColor Green
Write-Host "Upload the publish folder to Netlify Drop again." -ForegroundColor Cyan
Write-Host ""
