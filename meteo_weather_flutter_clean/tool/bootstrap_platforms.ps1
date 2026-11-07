$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("mcnc-flutter-" + [guid]::NewGuid().ToString())
$Scaffold = Join-Path $Temp "scaffold"
$SavedIndex = Join-Path $Temp "index.html"

New-Item -ItemType Directory -Path $Temp | Out-Null
try {
    $WebIndex = Join-Path $Root "web/index.html"
    if (Test-Path $WebIndex) {
        Copy-Item $WebIndex $SavedIndex
    }

    flutter create --platforms=android,web --android-language java --project-name flutter_meteo_weather --org com.mcnc.weather $Scaffold

    Remove-Item (Join-Path $Root "android") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Root "web") -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $Scaffold "android") (Join-Path $Root "android") -Recurse
    Copy-Item (Join-Path $Scaffold "web") (Join-Path $Root "web") -Recurse

    if (Test-Path $SavedIndex) {
        Copy-Item $SavedIndex (Join-Path $Root "web/index.html") -Force
    }

    Write-Host "Android and Web platform scaffolding generated."
}
finally {
    Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
}
