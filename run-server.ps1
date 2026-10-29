<#
.SYNOPSIS
    Arranca el servidor local con PostgreSQL 18 embebido (BD temporal) y un escenario de datos.
.DESCRIPTION
    La BD se crea al arrancar y se borra al parar. API en http://localhost:8080, BD en localhost:15432.
    Escenarios y destinos: docs/08-ejecucion-local.md. Un escenario desconocido lista los disponibles.
.EXAMPLE
    .\run-server.ps1
    .\run-server.ps1 -Scenario empty -Today 2027-03-10
    .\run-server.ps1 -Scenario ?
#>
param(
    [string]$Scenario = "empty",
    [string]$Today = ""
)

$ErrorActionPreference = "Stop"

$jdk = Get-ChildItem "$env:USERPROFILE\.jdks" -Directory -Filter "*25*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if ($jdk) {
    $env:JAVA_HOME = $jdk.FullName
} elseif (-not $env:JAVA_HOME) {
    Write-Error "No se encuentra un JDK 25 en ~/.jdks ni JAVA_HOME."
}

$appArgs = "--brackety.scenario=$Scenario"
if ($Today) { $appArgs += " --brackety.clock.today=$Today" }

& "$PSScriptRoot\server\mvnw.cmd" -q -f "$PSScriptRoot\server\pom.xml" spring-boot:test-run `
    "-Dspring-boot.run.main-class=dev.rgal.brackety.local.LocalBracketyApplication" `
    "-Dspring-boot.run.arguments=$appArgs"
