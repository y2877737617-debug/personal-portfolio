$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $root "portfolio-projects.json"
$updateScript = Join-Path $root "update-publish.ps1"
$projects = @((Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })

function Normalize-DroppedPath {
  param([string]$Path)
  return $Path.Trim().Trim('"').Trim("'")
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  Add image to an existing project" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""
$projects | ForEach-Object { Write-Host "  $($_.folder) = $($_.title)" }
Write-Host ""

$folder = (Read-Host "Enter project number").Trim()
$project = $projects | Where-Object { $_.folder -eq $folder }
if ($null -eq $project) { throw "Project number does not exist." }

Write-Host ""
Write-Host "Drag the new image file into this window, then press Enter." -ForegroundColor Cyan
$newImagePath = Normalize-DroppedPath -Path (Read-Host "New image path")
if (-not (Test-Path -LiteralPath $newImagePath -PathType Leaf)) { throw "The new image file does not exist." }
$newImage = Get-Item -LiteralPath $newImagePath
if ($newImage.Extension -notmatch "^\.(jpg|jpeg|png)$") { throw "The new image must be a JPG, JPEG, or PNG file." }

$existingNumbers = @($project.files | ForEach-Object { [int][System.IO.Path]::GetFileNameWithoutExtension($_) })
$nextNumber = if ($existingNumbers.Count) { ($existingNumbers | Measure-Object -Maximum).Maximum + 1 } else { 1 }
$newFileName = "$nextNumber$($newImage.Extension.ToLowerInvariant())"
$destination = Join-Path (Join-Path $root $folder) $newFileName
Copy-Item -LiteralPath $newImage.FullName -Destination $destination

$project.files = @($project.files) + $newFileName
[System.IO.File]::WriteAllText($configPath, ($projects | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Added: project $folder / $newFileName" -ForegroundColor Green
& $updateScript
