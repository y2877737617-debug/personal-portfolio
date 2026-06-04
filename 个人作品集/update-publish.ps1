$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$webImages = Join-Path $root "web-images"
$publish = Join-Path $root "publish"
$optimizeScript = Join-Path $root "optimize-images.ps1"
$generateDataScript = Join-Path $root "generate-project-data.ps1"
$configPath = Join-Path $root "portfolio-projects.json"
$projects = @((Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })

function Remove-WorkspaceDirectory {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  $resolvedRoot = [System.IO.Path]::GetFullPath($root).TrimEnd("\")
  $resolvedPath = [System.IO.Path]::GetFullPath($Path).TrimEnd("\")
  if (-not $resolvedPath.StartsWith("$resolvedRoot\", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove a directory outside the portfolio workspace: $resolvedPath"
  }

  Remove-Item -LiteralPath $resolvedPath -Recurse -Force
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  Updating DaYE portfolio publish files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""

Write-Host "[1/3] Rebuilding optimized web images..." -ForegroundColor Yellow
Remove-WorkspaceDirectory -Path $webImages
& $generateDataScript
& $optimizeScript | Format-Table -AutoSize

Write-Host ""
Write-Host "[2/3] Rebuilding publish directory..." -ForegroundColor Yellow
Remove-WorkspaceDirectory -Path $publish
New-Item -ItemType Directory -Path $publish | Out-Null

Copy-Item -LiteralPath (Join-Path $root "index.html") -Destination $publish
Copy-Item -LiteralPath (Join-Path $root "styles.css") -Destination $publish
Copy-Item -LiteralPath (Join-Path $root "script.js") -Destination $publish
Copy-Item -LiteralPath (Join-Path $root "project-data.js") -Destination $publish
Copy-Item -LiteralPath (Join-Path $root "covers") -Destination $publish -Recurse
Copy-Item -LiteralPath $webImages -Destination $publish -Recurse

Write-Host ""
Write-Host "[3/3] Verifying publish files..." -ForegroundColor Yellow
$sourceImages = @($projects) |
  ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $root $_.folder) -File } |
  Where-Object { $_.Extension -match "^\.(jpg|jpeg|png)$" }
$optimizedImages = Get-ChildItem -LiteralPath $webImages -Recurse -File
$publishedImages = Get-ChildItem -LiteralPath (Join-Path $publish "web-images") -Recurse -File
$publishedFiles = Get-ChildItem -LiteralPath $publish -Recurse -File

if ($sourceImages.Count -ne $optimizedImages.Count) {
  throw "Optimized image count does not match source image count."
}
if ($optimizedImages.Count -ne $publishedImages.Count) {
  throw "Published image count does not match optimized image count."
}

Write-Host ""
Write-Host "Update complete." -ForegroundColor Green
Write-Host "Publish folder: $publish"
Write-Host "Source images:  $($sourceImages.Count)"
Write-Host "Publish files:  $($publishedFiles.Count)"
Write-Host "Publish size:   $([Math]::Round((($publishedFiles | Measure-Object Length -Sum).Sum / 1MB), 2)) MB"
Write-Host ""
Write-Host "Upload the publish folder to Netlify Drop again to update your public URL." -ForegroundColor Cyan
Write-Host ""
