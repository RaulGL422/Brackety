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
    .\run-server.ps1 -Scenario yoseikan-f1 -LocalClaude
.PARAMETER LocalClaude
    Importar alumnos con el `claude` y la sesión de quien desarrolla (suscripción, no la API).
    Solo con listas ficticias; en producción se ignora.
#>
param(
    [string]$Scenario = "empty",
    [string]$Today = "",
    [switch]$LocalClaude
)

$ErrorActionPreference = "Stop"

# By the JDK's own release file, not the folder name: "jbr-21.0.25" would also match "*25*".
$jdk = Get-ChildItem "$env:USERPROFILE\.jdks" -Directory -ErrorAction SilentlyContinue |
    Where-Object { Select-String -Path "$($_.FullName)\release" -Pattern '^JAVA_VERSION="25[."]' -Quiet -ErrorAction SilentlyContinue } |
    Sort-Object Name -Descending | Select-Object -First 1
if ($jdk) {
    $env:JAVA_HOME = $jdk.FullName
} elseif (-not $env:JAVA_HOME) {
    Write-Error "No se encuentra un JDK 25 en ~/.jdks ni JAVA_HOME."
}

$appArgs = "--brackety.scenario=$Scenario"
if ($Today) { $appArgs += " --brackety.clock.today=$Today" }
if ($LocalClaude) { $appArgs += " --brackety.import.local-cli=true" }

& "$PSScriptRoot\server\mvnw.cmd" -q -f "$PSScriptRoot\server\pom.xml" spring-boot:test-run `
    "-Dspring-boot.run.main-class=dev.rgal.brackety.local.LocalBracketyApplication" `
    "-Dspring-boot.run.arguments=$appArgs"
