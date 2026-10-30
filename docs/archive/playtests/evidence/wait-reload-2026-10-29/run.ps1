$ErrorActionPreference = 'Stop'
$taskAudit = $PSScriptRoot
foreach ($taskVersion in @('before', 'after')) {
    Push-Location (Join-Path $taskAudit "$taskVersion/monstrous_sim")
    try {
        & 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' run audit.dart 30 $taskVersion
        if ($LASTEXITCODE -ne 0) { throw "Audit failed: $taskVersion" }
    } finally { Pop-Location }
}
python (Join-Path $taskAudit 'summarize.py')
python (Join-Path $taskAudit 'verify.py')
