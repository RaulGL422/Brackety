<#
.SYNOPSIS
    Arranca la app o el admin de Flutter apuntando al backend que se elija.
.DESCRIPTION
    web      -> Chrome, API en http://localhost:8080 (app en puerto 5000, admin en 5001)
    emulator -> emulador Android, API en http://10.0.2.2:8080 (el PC visto desde el emulador)
    device   -> móvil físico en la misma wifi, API en la IP LAN del PC (detectada; se guarda en env/device.json)
    url      -> cualquier backend: -Url https://api.ejemplo.dev
    Detalle en docs/08-ejecucion-local.md.
.EXAMPLE
    .\run-app.ps1
    .\run-app.ps1 -Target emulator
    .\run-app.ps1 -Target device
    .\run-app.ps1 -Target url -Url http://192.168.1.20:8080 -Device emulator
    .\run-app.ps1 -App admin
#>
param(
    [ValidateSet("app", "admin")]
    [string]$App = "app",
    [ValidateSet("web", "emulator", "device", "url")]
    [string]$Target = "web",
    [string]$Url = "",
    [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$project = Join-Path $PSScriptRoot $App

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = "C:\dev\flutter\bin\flutter.bat" }

if ($App -eq "admin" -and $Target -in @("emulator", "device")) {
    Write-Error "El admin es solo web: usa -Target web o -Target url."
}

function Get-LanIp {
    $ip = Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq "Up" } |
        ForEach-Object { $_.IPv4Address.IPAddress } |
        Where-Object { $_ -match '^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)' } |
        Select-Object -First 1
    if (-not $ip) { Write-Error "No se encuentra la IP de la red local. Usa -Target url -Url http://<ip>:8080." }
    return $ip
}

$runArgs = @("run")
switch ($Target) {
    "web" {
        $port = if ($App -eq "admin") { 5001 } else { 5000 }
        $runArgs += @("--dart-define-from-file=env/web.json", "--web-port=$port")
        if (-not $Device) { $Device = "chrome" }
    }
    "emulator" {
        $runArgs += "--dart-define-from-file=env/emulator.json"
        if (-not $Device) { $Device = "emulator" }
    }
    "device" {
        $apiUrl = "http://$(Get-LanIp):8080"
        Set-Content -Path (Join-Path $project "env\device.json") -Encoding ascii `
            -Value "{`n  `"API_BASE_URL`": `"$apiUrl`",`n  `"APP_ENV`": `"dev`"`n}"
        Write-Host "Móvil -> $apiUrl (el móvil debe estar en la misma wifi)"
        $runArgs += "--dart-define-from-file=env/device.json"
    }
    "url" {
        if (-not $Url) { Write-Error "Falta -Url, p. ej. -Url https://api.brackety.rgal.dev" }
        $runArgs += "--dart-define=API_BASE_URL=$($Url.TrimEnd('/'))"
        if (-not $Device) { $Device = "chrome" }
    }
}
if ($Device) { $runArgs += @("-d", $Device) }

Push-Location $project
try {
    & $flutter @runArgs
} finally {
    Pop-Location
}
