param(
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot 'build\app\outputs\flutter-apk'

Push-Location $projectRoot
try {
    flutter analyze
    if (-not $SkipTests) {
        flutter test --reporter compact
    }

    flutter build apk --debug
    Copy-Item `
        -LiteralPath (Join-Path $outputDirectory 'app-debug.apk') `
        -Destination (Join-Path $outputDirectory 'hesabim-debug.apk') `
        -Force

    flutter build apk --release
    Copy-Item `
        -LiteralPath (Join-Path $outputDirectory 'app-release.apk') `
        -Destination (Join-Path $outputDirectory 'hesabim-release.apk') `
        -Force
}
finally {
    Pop-Location
}

Write-Host "APK files created:"
Write-Host (Join-Path $outputDirectory 'hesabim-debug.apk')
Write-Host (Join-Path $outputDirectory 'hesabim-release.apk')
