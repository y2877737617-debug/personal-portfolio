$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $root "portfolio-projects.json"
$coversPath = Join-Path $root "covers"
$updateScript = Join-Path $root "update-publish.ps1"
$projects = @((Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })

function Normalize-DroppedPath {
  param([string]$Path)
  return $Path.Trim().Trim('"').Trim("'")
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  Add new DaYE portfolio project" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "This creates a new project list and adds its first image." -ForegroundColor Yellow
Write-Host ""

$title = (Read-Host "Project title, for example NEW BRAND").Trim()
if ([string]::IsNullOrWhiteSpace($title)) { throw "Project title cannot be empty." }
$category = (Read-Host "Category, for example Food packaging").Trim()
if ([string]::IsNullOrWhiteSpace($category)) { throw "Category cannot be empty." }
$description = (Read-Host "Short project description").Trim()
if ([string]::IsNullOrWhiteSpace($description)) { throw "Description cannot be empty." }
$year = (Read-Host "Year, press Enter to use 2026").Trim()
if ([string]::IsNullOrWhiteSpace($year)) { $year = "2026" }

Write-Host ""
Write-Host "Drag the first project image into this window, then press Enter." -ForegroundColor Cyan
$newImagePath = Normalize-DroppedPath -Path (Read-Host "First image path")
if (-not (Test-Path -LiteralPath $newImagePath -PathType Leaf)) { throw "The image file does not exist." }
$newImage = Get-Item -LiteralPath $newImagePath
if ($newImage.Extension -notmatch "^\.(jpg|jpeg|png)$") { throw "The image must be a JPG, JPEG, or PNG file." }

$folder = [string](($projects | ForEach-Object { [int]$_.folder } | Measure-Object -Maximum).Maximum + 1)
$projectDirectory = Join-Path $root $folder
New-Item -ItemType Directory -Path $projectDirectory | Out-Null
$firstFile = "1$($newImage.Extension.ToLowerInvariant())"
Copy-Item -LiteralPath $newImage.FullName -Destination (Join-Path $projectDirectory $firstFile)

$coverFile = "$folder.jpg"
$coverDestination = Join-Path $coversPath $coverFile
$image = [System.Drawing.Image]::FromFile($newImage.FullName)
try {
  $width = 1100
  $height = [Math]::Round($image.Height * $width / $image.Width)
  $bitmap = New-Object System.Drawing.Bitmap($width, $height)
  try {
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $graphics.DrawImage($image, 0, 0, $width, $height)
    } finally {
      $graphics.Dispose()
    }
    $bitmap.Save($coverDestination, [System.Drawing.Imaging.ImageFormat]::Jpeg)
  } finally {
    $bitmap.Dispose()
  }
} finally {
  $image.Dispose()
}

$projects += [PSCustomObject]@{
  title = $title
  folder = $folder
  cover = "covers/$coverFile"
  category = $category
  year = $year
  desc = $description
  files = @($firstFile)
}
[System.IO.File]::WriteAllText($configPath, ($projects | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Created project $folder = $title" -ForegroundColor Green
& $updateScript
