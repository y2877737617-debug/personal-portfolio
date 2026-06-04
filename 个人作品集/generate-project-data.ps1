$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $root "portfolio-projects.json"
$outputPath = Join-Path $root "project-data.js"
$projects = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$json = $projects | ConvertTo-Json -Depth 10 -Compress
[System.IO.File]::WriteAllText($outputPath, "window.portfolioProjects = $json;`n", [System.Text.UTF8Encoding]::new($false))
