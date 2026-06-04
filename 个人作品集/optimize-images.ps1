$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputRoot = Join-Path $root "web-images"
$configPath = Join-Path $root "portfolio-projects.json"
$maxWidth = 1800
$jpegQuality = 84L
$projects = @((Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq "image/jpeg" }

$encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
  [System.Drawing.Imaging.Encoder]::Quality,
  $jpegQuality
)

@($projects) |
  ForEach-Object {
    $sourceDirectory = Get-Item -LiteralPath (Join-Path $root $_.folder)
    $outputDirectory = Join-Path $outputRoot $sourceDirectory.Name
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

    Get-ChildItem -LiteralPath $sourceDirectory.FullName -File |
      Where-Object { $_.Extension -match "^\.(jpg|jpeg|png)$" } |
      ForEach-Object {
        $source = $_
        $destination = Join-Path $outputDirectory $source.Name
        $image = [System.Drawing.Image]::FromFile($source.FullName)

        try {
          $width = [Math]::Min($image.Width, $maxWidth)
          $height = [Math]::Round($image.Height * $width / $image.Width)
          $bitmap = New-Object System.Drawing.Bitmap($width, $height)

          try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
              $graphics.Clear([System.Drawing.Color]::White)
              $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
              $graphics.DrawImage($image, 0, 0, $width, $height)
            } finally {
              $graphics.Dispose()
            }

            if ($source.Extension -match "^\.(jpg|jpeg)$") {
              $bitmap.Save($destination, $jpegCodec, $encoderParameters)
            } else {
              $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
            }
          } finally {
            $bitmap.Dispose()
          }
        } finally {
          $image.Dispose()
        }
      }
  }

$encoderParameters.Dispose()

$originals = @($projects) | ForEach-Object {
  Get-ChildItem -LiteralPath (Join-Path $root $_.folder) -File
}
$optimized = Get-ChildItem -Path $outputRoot -Recurse -File

[PSCustomObject]@{
  OriginalImages = $originals.Count
  OriginalMB = [Math]::Round((($originals | Measure-Object Length -Sum).Sum / 1MB), 2)
  OptimizedImages = $optimized.Count
  OptimizedMB = [Math]::Round((($optimized | Measure-Object Length -Sum).Sum / 1MB), 2)
}
