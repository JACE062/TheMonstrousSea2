param([switch]$Apply, [string]$ArchiveDate = '2026-10-12')
$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$artRoot = [IO.Path]::GetFullPath((Join-Path $workspace 'apps/monstrous_sea/assets/art'))
$archiveRoot = [IO.Path]::GetFullPath((Join-Path $workspace 'docs/art/archive'))
function Assert-Within([string]$Path, [string]$Root) {
  $resolved = [IO.Path]::GetFullPath($Path)
  $prefix = $Root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
  if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes intended workspace directory: $resolved"
  }
}
Assert-Within $artRoot $workspace
Assert-Within $archiveRoot $workspace
$catalog = Get-Content -LiteralPath (Join-Path $workspace 'apps/monstrous_sea/lib/src/widgets/pilot_art.dart') -Raw
$active = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($match in [regex]::Matches($catalog, "static const \w+\s*=\s*'assets/art/([^']+)'")) {
  [void]$active.Add($match.Groups[1].Value)
}
$manifest = Get-Content -LiteralPath (Join-Path $workspace 'docs/art/sea_map_art_manifest.json') -Raw | ConvertFrom-Json
if ($active.Count -ne $manifest.assets.Count) { throw 'Runtime art catalog and manifest count differ' }
foreach ($asset in $manifest.assets) {
  if (-not $active.Contains($asset.filename)) { throw "Manifest artwork is not in the runtime catalog: $($asset.filename)" }
}
$candidates = @(Get-ChildItem -LiteralPath $artRoot -File | Where-Object {
  ($_.Extension -in '.png', '.svg') -and -not $active.Contains($_.Name)
} | Sort-Object Name)
$archivedFiles = @()
foreach ($file in $candidates) {
  $relative = 'docs/art/archive/' + $file.Extension.TrimStart('.') + '/' + $file.Name
  $destination = [IO.Path]::GetFullPath((Join-Path $workspace $relative))
  Assert-Within $file.FullName $artRoot
  Assert-Within $destination $archiveRoot
  if (Test-Path -LiteralPath $destination) { throw "Archive destination already exists: $destination" }
  $archivedFiles += [ordered]@{
    filename = $file.Name
    originalRelativePath = 'apps/monstrous_sea/assets/art/' + $file.Name
    archivedRelativePath = $relative
    bytes = $file.Length
    sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  }
}
$activeFiles = @()
foreach ($name in ($active | Sort-Object)) {
  $file = Get-Item -LiteralPath (Join-Path $artRoot $name)
  Assert-Within $file.FullName $artRoot
  $activeFiles += [ordered]@{
    filename = $name
    relativePath = 'apps/monstrous_sea/assets/art/' + $name
    bytes = $file.Length
    sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  }
}
$bytes = ($candidates | Measure-Object Length -Sum).Sum
if (-not $Apply) {
  [ordered]@{ activeFiles = $active.Count; archiveCandidates = $candidates.Count; bytesRemovedFromBundle = $bytes; pathsVerified = $true } | ConvertTo-Json
  return
}
if ($candidates.Count -eq 0) { throw 'No unused files to archive' }
foreach ($folder in @($archiveRoot, (Join-Path $archiveRoot 'png'), (Join-Path $archiveRoot 'svg'))) {
  [void](New-Item -ItemType Directory -Path $folder -Force)
}
$indexPath = Join-Path $archiveRoot 'manifest.json'
if (Test-Path -LiteralPath $indexPath) { throw 'Archive manifest already exists; inspect it before extending the archive' }
$plan = [ordered]@{
  createdOn = $ArchiveDate
  state = 'planned'
  note = 'Unused source artwork moved outside the Flutter asset bundle. All originals preserved byte-for-byte.'
  bytesRemovedFromBundle = $bytes
  archivedFiles = $archivedFiles
  activeFiles = $activeFiles
}
$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $indexPath -Encoding utf8
foreach ($record in $archivedFiles) {
  $source = [IO.Path]::GetFullPath((Join-Path $workspace $record.originalRelativePath))
  $destination = [IO.Path]::GetFullPath((Join-Path $workspace $record.archivedRelativePath))
  Assert-Within $source $artRoot
  Assert-Within $destination $archiveRoot
  Move-Item -LiteralPath $source -Destination $destination
  if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $record.sha256) {
    throw "Archived content hash changed: $($record.filename)"
  }
}
foreach ($record in $activeFiles) {
  $source = Join-Path $workspace $record.relativePath
  if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $record.sha256) {
    throw "Active artwork changed: $($record.filename)"
  }
}
$plan.state = 'archived'
$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $indexPath -Encoding utf8
[ordered]@{ activeFiles = $active.Count; archivedFiles = $archivedFiles.Count; bytesRemovedFromBundle = $bytes; allHashesVerified = $true } | ConvertTo-Json

