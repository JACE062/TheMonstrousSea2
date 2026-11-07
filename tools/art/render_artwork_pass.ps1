# Candidate review composites only. Original generated PNGs remain unchanged.
param([string]$Revision = '', [switch]$PatchAlternatives, [switch]$PatchProposal)
# Run with Windows PowerShell: powershell.exe -NoProfile -File tools/art/render_artwork_pass.ps1
$ErrorActionPreference = 'Stop'
if ($Revision -and $Revision -notmatch '^v[0-9]+$') { throw 'Revision must be v followed by digits' }
if ($PatchAlternatives -and $PatchProposal) { throw 'Choose one patch-kit proof mode' }
$suffix = if ($Revision) { '-' + $Revision } else { '' }
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class ArtworkAlphaCheck {
  public static double[] Inspect(string path) {
    using (var image = new Bitmap(path)) {
      var data = image.LockBits(new Rectangle(0, 0, image.Width, image.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      try {
        byte[] bytes = new byte[Math.Abs(data.Stride) * image.Height];
        Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
        long clear = 0, painted = 0, edges = 0;
        int left = image.Width, top = image.Height, right = 0, bottom = 0;
        for (int y = 0; y < image.Height; y++) for (int x = 0; x < image.Width; x++) {
          byte alpha = bytes[y * Math.Abs(data.Stride) + x * 4 + 3];
          if (alpha == 0) clear++;
          if (alpha > 200) painted++;
          if (alpha > 16) {
            left = Math.Min(left, x); top = Math.Min(top, y);
            right = Math.Max(right, x); bottom = Math.Max(bottom, y);
            if (x == 0 || y == 0 || x == image.Width - 1 || y == image.Height - 1) edges++;
          }
        }
        double count = image.Width * image.Height;
        return new double[] {image.Width, image.Height, clear / count, painted / count, edges, left, top, right, bottom};
      } finally { image.UnlockBits(data); }
    }
  }
}
'@
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$artRoot = Join-Path $repoRoot 'docs/art'
$review = Get-Content -LiteralPath (Join-Path $artRoot 'artwork_pass_2026_11_06.json') -Raw | ConvertFrom-Json
$outputRoot = Join-Path $artRoot 'candidates/artwork-pass-2026-11-06'
$ink = [Drawing.ColorTranslator]::FromHtml('#1B1612')
$paper = [Drawing.ColorTranslator]::FromHtml('#F4ECD8')
$chartPaper = [Drawing.ColorTranslator]::FromHtml('#ECD39A')
$bodyFont = New-Object Drawing.Font('Georgia', 17, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$smallFont = New-Object Drawing.Font('Georgia', 13, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$titleFont = New-Object Drawing.Font('Georgia', 25, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
$brush = New-Object Drawing.SolidBrush($ink)
$rule = New-Object Drawing.Pen([Drawing.Color]::FromArgb(65, $ink), 1)

function New-Proof([int]$width, [int]$height, [Drawing.Color]$background) {
  $bitmap = New-Object Drawing.Bitmap($width, $height)
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear($background)
  $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  return @{ Bitmap = $bitmap; G = $graphics }
}
function Draw-Art($graphics, [string]$sourcePath, [int]$x, [int]$y, [int]$size, [single]$alpha = 1) {
  $image = [Drawing.Image]::FromFile($sourcePath)
  $attrs = New-Object Drawing.Imaging.ImageAttributes
  try {
    $matrix = New-Object Drawing.Imaging.ColorMatrix
    $matrix.Matrix33 = $alpha
    $attrs.SetColorMatrix($matrix)
    $rect = New-Object Drawing.Rectangle($x, $y, $size, $size)
    $graphics.DrawImage($image, $rect, 0, 0, $image.Width, $image.Height, [Drawing.GraphicsUnit]::Pixel, $attrs)
  } finally { $attrs.Dispose(); $image.Dispose() }
}
function Save-Proof($proof, [string]$name) {
  try { $proof.Bitmap.Save((Join-Path $outputRoot $name), [Drawing.Imaging.ImageFormat]::Png) }
  finally { $proof.G.Dispose(); $proof.Bitmap.Dispose() }
}

$checkAssets = @(if ($PatchProposal) { $review.assets[0].proposal } elseif ($PatchAlternatives) { $review.assets[0].alternatives } else { $review.assets })
$checks = foreach ($asset in $checkAssets) {
  $assetPath = Join-Path $repoRoot $asset.path
  $check = [ArtworkAlphaCheck]::Inspect($assetPath)
  if ($check[0] -ne $check[1] -or $check[0] -lt 1024 -or $check[2] -lt .1 -or $check[3] -lt .03 -or $check[4] -ne 0) {
    throw "Invalid size, alpha or clipped edges: $($asset.id)"
  }
  $hash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash
  if (Test-Path -LiteralPath $asset.source) {
    if ((Get-FileHash -LiteralPath $asset.source -Algorithm SHA256).Hash -ne $hash) { throw "Generated source changed: $($asset.id)" }
  }
  [ordered]@{ id = $asset.id; width = $check[0]; height = $check[1]; transparentFraction = $check[2]; paintedFraction = $check[3]; edgePixels = $check[4]; visibleBounds = $check[5..8]; sha256 = $hash }
}
$patchStem = if ($PatchProposal) { 'patch-kit-packed' } else { 'patch-kit-variations' }
$checksName = if ($PatchAlternatives -or $PatchProposal) { $patchStem + $suffix + '-alpha-checks.json' } else { 'alpha-checks' + $suffix + '.json' }
$checks | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputRoot $checksName) -Encoding UTF8

if ($PatchAlternatives -or $PatchProposal) {
  $expectedCount = if ($PatchProposal) { 1 } else { 2 }
  if ($checkAssets.Count -ne $expectedCount) { throw 'Unexpected patch-kit candidate count' }
  $proof = New-Proof 900 650 $paper
  $heading = if ($PatchProposal) { 'Hull Patch Kit - packed repair supplies' } else { 'Hull Patch Kit - two new variations' }
  $proof.G.DrawString($heading, $titleFont, $brush, 24, 18)
  $proof.G.DrawString('Large preview and actual 28 / 48 / 96 px samples. Candidate artwork.', $smallFont, $brush, 24, 56)
  for ($i = 0; $i -lt $checkAssets.Count; $i++) {
    $asset = $checkAssets[$i]; $x = $i * 450 + (900 - $checkAssets.Count * 450) / 2
    $proof.G.DrawString($asset.title, $bodyFont, $brush, $x + 28, 100)
    Draw-Art $proof.G (Join-Path $repoRoot $asset.path) ($x + 65) 135 320
    $offset = 60
    foreach ($size in @(28, 48, 96)) {
      Draw-Art $proof.G (Join-Path $repoRoot $asset.path) ($x + $offset) (485 + (96 - $size) / 2) $size
      $proof.G.DrawString([string]$size, $smallFont, $brush, $x + $offset, 597)
      $offset += $size + 55
    }
    $proof.G.DrawRectangle($rule, $x + 14, 88, 422, 545)
  }
  Save-Proof $proof ($patchStem + $suffix + '.png')
  $bodyFont.Dispose(); $smallFont.Dispose(); $titleFont.Dispose(); $brush.Dispose(); $rule.Dispose()
  Write-Output ($checkAssets.Count.ToString() + ' patch-kit candidate originals verified; review sheet rendered.')
  return
}

$proof = New-Proof 1080 820 $paper
$proof.G.DrawString('Consumables and chart controls - review candidates', $titleFont, $brush, 24, 18)
$proof.G.DrawString('Item samples: 28 / 48 / 96 px. Control samples: 22 / 28 / 36 px. Original PNG padding retained.', $smallFont, $brush, 24, 54)
$main = @($review.assets | Where-Object { $_.kind -ne 'ornament' })
for ($i = 0; $i -lt $main.Count; $i++) {
  $asset = $main[$i]
  $x = ($i % 3) * 360; $y = [Math]::Floor($i / 3) * 365 + 85
  $proof.G.DrawString(('A{0:00} - {1}' -f ($i + 1), $asset.title), $bodyFont, $brush, $x + 20, $y)
  Draw-Art $proof.G (Join-Path $repoRoot $asset.path) ($x + 90) ($y + 32) 180
  $offset = 28
  $samples = if ($asset.kind -eq 'control') { @(22, 28, 36) } else { @(28, 48, 96) }
  foreach ($size in $samples) {
    Draw-Art $proof.G (Join-Path $repoRoot $asset.path) ($x + $offset) ($y + 230 + (96 - $size) / 2) $size
    $proof.G.DrawString([string]$size, $smallFont, $brush, $x + $offset, $y + 330)
    $offset += $size + 42
  }
  $proof.G.DrawRectangle($rule, $x + 10, $y - 5, 340, 358)
}
Save-Proof $proof ('items-and-controls' + $suffix + '.png')

$proof = New-Proof 1080 620 $chartPaper
$proof.G.DrawString('Regional marginalia - placement study', $titleFont, $brush, 24, 18)
$proof.G.DrawString('Full-strength samples above; faded chart treatments below. Diagram only, not a gameplay screenshot.', $smallFont, $brush, 24, 54)
$ornaments = @(
  @{ Title = 'A07 - Sargasso kelp'; Path = (Join-Path $repoRoot $review.assets[6].path) },
  @{ Title = 'Existing approved fog'; Path = (Join-Path $repoRoot $review.reuse[0].path) },
  @{ Title = 'A08 - Boiling Reach'; Path = (Join-Path $repoRoot $review.assets[7].path) }
)
for ($i = 0; $i -lt $ornaments.Count; $i++) {
  $x = $i * 360
  $proof.G.DrawString($ornaments[$i].Title, $bodyFont, $brush, $x + 30, 91)
  Draw-Art $proof.G $ornaments[$i].Path ($x + 75) 120 200
}
for ($x = 20; $x -lt 1080; $x += 72) { $proof.G.DrawLine($rule, $x, 350, $x, 606) }
for ($y = 350; $y -lt 620; $y += 64) { $proof.G.DrawLine($rule, 16, $y, 1064, $y) }
Draw-Art $proof.G $ornaments[0].Path 70 372 190 .24
Draw-Art $proof.G $ornaments[1].Path 360 358 235 .22
Draw-Art $proof.G $ornaments[2].Path 780 366 220 .27
$routePen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(170, $ink), 2)
$routePen.DashStyle = [Drawing.Drawing2D.DashStyle]::Dot
$route = [Drawing.Point[]]@((New-Object Drawing.Point(60, 555)), (New-Object Drawing.Point(320, 500)), (New-Object Drawing.Point(560, 550)), (New-Object Drawing.Point(740, 450)))
$proof.G.DrawLines($routePen, $route)
foreach ($point in $route) { $proof.G.DrawEllipse($rule, $point.X - 12, $point.Y - 12, 24, 24) }
$routePen.Dispose()
Save-Proof $proof ('regional-context' + $suffix + '.png')
$bodyFont.Dispose(); $smallFont.Dispose(); $titleFont.Dispose(); $brush.Dispose(); $rule.Dispose()
Write-Output "8 original transparent PNGs verified; generated copies match sources. Two review sheets rendered."
