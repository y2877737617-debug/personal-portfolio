$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$updateScript = Join-Path $root "update-publish.ps1"
$backupRoot = Join-Path $root "image-backups"
$configPath = Join-Path $root "portfolio-projects.json"
$projects = @((Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })

function Normalize-DroppedPath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return ""
  }

  return $Path.Trim().Trim('"').Trim("'")
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  Replace DaYE portfolio image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Projects:"
$projects | ForEach-Object { Write-Host "  $($_.folder) = $($_.title)" }
Write-Host ""

$project = (Read-Host "Enter project number").Trim()
if ($project -notin @($projects.folder)) {
  throw "Project number does not exist."
}

$projectDirectory = Join-Path $root $project
$availableFiles = Get-ChildItem -LiteralPath $projectDirectory -File |
  Where-Object { $_.Extension -match "^\.(jpg|jpeg|png)$" } |
  Sort-Object { [int]$_.BaseName }

Write-Host ""
Write-Host "Images in project ${project}:" -ForegroundColor Yellow
$availableFiles | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ""

$imageNumber = (Read-Host "Enter image number to replace, for example 1 or 12").Trim()
if ($imageNumber -notmatch "^\d+$") {
  throw "Image number must be numeric."
}

$targetCandidates = $availableFiles | Where-Object { $_.BaseName -eq $imageNumber }
if ($targetCandidates.Count -ne 1) {
  throw "Could not find exactly one image numbered $imageNumber in project $project."
}
$target = $targetCandidates[0]

Write-Host ""
Write-Host "Drag the new image file into this window, then press Enter." -ForegroundColor Cyan
$newImagePath = Normalize-DroppedPath -Path (Read-Host "New image path")
if (-not (Test-Path -LiteralPath $newImagePath -PathType Leaf)) {
  throw "The new image file does not exist."
}

$newImage = Get-Item -LiteralPath $newImagePath
if ($newImage.Extension -notmatch "^\.(jpg|jpeg|png)$") {
  throw "The new image must be a JPG, JPEG, or PNG file."
}

Add-Type -AssemblyName System.Drawing
$testImage = [System.Drawing.Image]::FromFile($newImage.FullName)
$testImage.Dispose()

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDirectory = Join-Path $backupRoot $timestamp
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
$backupPath = Join-Path $backupDirectory "${project}-$($target.Name)"
Copy-Item -LiteralPath $target.FullName -Destination $backupPath

Copy-Item -LiteralPath $newImage.FullName -Destination $target.FullName -Force

Write-Host ""
Write-Host "Image replaced: project $project / $($target.Name)" -ForegroundColor Green
Write-Host "Backup saved:   $backupPath"
Write-Host ""
Write-Host "Rebuilding publish files..." -ForegroundColor Yellow
& $updateScript

Write-Host ""
Write-Host "Image replacement complete." -ForegroundColor Green
Write-Host "Upload the publish folder to Netlify Drop again." -ForegroundColor Cyan
Write-Host ""
