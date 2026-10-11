# Script to compile and execute the Java oracle against TheMonstrousSea_Original
$ErrorActionPreference = "Stop"

$outputDir = "tools/java_oracle/bin"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$javaSources = @(
    Get-ChildItem -Path "TheMonstrousSea_Original/src" -Recurse -Filter "*.java" | ForEach-Object { $_.FullName }
)
$oracleSource = (Get-Item "tools/java_oracle/OracleMain.java").FullName
$allSources = $javaSources + $oracleSource

Write-Host "Compiling Java Oracle with $($allSources.Count) source files..."
javac -d $outputDir $allSources

Write-Host "Executing OracleMain to generate statistical baseline fixtures..."
java -cp $outputDir tools.oracle.OracleMain

Write-Host "Fixtures successfully generated."
