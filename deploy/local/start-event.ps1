<#
.SYNOPSIS
    Arranca el servidor de Brackety del pabellón (portátil Windows sin Internet).
.DESCRIPTION
    PostgreSQL y la API con la web, todo dentro de esta carpeta. Los datos viven en brackety-data\ y se
    conservan entre arranques. Al parar (Ctrl+C) guarda una copia de la BD en brackety-data\backups\.
    Móviles: http://192.168.137.1:8080 (punto de acceso de Windows). Este portátil: http://localhost:8080.
    El primer arranque necesita el evento: -Package (el .zip o el .brackety que exporta el club) o -Demo.
.EXAMPLE
    .\start-event.ps1 -Package .\fase-1.brackety
    .\start-event.ps1 -Package .\fase-1.brackety -UsernamePasswords
    .\start-event.ps1
    .\start-event.ps1 -Demo -EventDate 2026-11-14
    .\start-event.ps1 -Backup
    .\start-event.ps1 -Reset
    .\start-event.ps1 -NoHotspot -NoFirewall
#>
param(
    # Event package (the club's full export .zip, or the .brackety) to load on the first start of an empty data folder.
    [string]$Package = "",
    # First start with the prototype's demo accounts and event instead of a package.
    [switch]$Demo,
    # With -Package: the staff accounts it creates get their username as password (risk accepted for the F1).
    [switch]$UsernamePasswords,
    # Day of the demo event (age categories), AAAA-MM-DD; empty = today. Only used when the accounts are created.
    [string]$EventDate = "",
    [string]$LegalOwnerName = "",
    [string]$PrivacyContactEmail = "",
    # Only a copy of the database, then exit.
    [switch]$Backup,
    # Renames brackety-data to brackety-data.old-<date> (never deletes it) to start again with an empty one.
    [switch]$Reset,
    [switch]$NoHotspot,
    [switch]$NoFirewall
)

$ErrorActionPreference = "Stop"

$PgPort = 15433
$ApiPort = 8080
$HotspotIp = "192.168.137.1"
$HallSubnet = "192.168.137.0/24"
$DbName = "brackety"
$DbUser = "brackety"
$KeptBackups = 20

$here = $PSScriptRoot
$data = Join-Path $here "brackety-data"
$pgData = Join-Path $data "pgdata"
$pgBin = Join-Path $here "pgsql\bin"
$java = Join-Path $here "jre\bin\java.exe"
$jar = Join-Path $here "api\brackety.jar"
$webDir = Join-Path $here "web"
# The superadmin web, served at /admin/ (only to this laptop).
$adminWebDir = Join-Path $here "admin"
$superadminFile = Join-Path $data "superadmin.txt"
$secretsFile = Join-Path $data "secrets.env"
$eventFile = Join-Path $data "event.env"
# What the first start loaded: the package or the demo event. Without either, that start went wrong.
$packageMark = Join-Path $data "package-loaded.txt"
$demoMark = Join-Path $data "demo-loaded.txt"
# Staff accounts the package created, with their random passwords (written by the API, never logged).
$credentialsFile = Join-Path $data "credentials.txt"

function Write-Step([string]$text) { Write-Host "-> $text" -ForegroundColor Cyan }
function Write-Warn([string]$text) { Write-Host "AVISO: $text" -ForegroundColor Yellow }

function New-Secret {
    $bytes = New-Object byte[] 48
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Read-EnvFile([string]$path) {
    $values = @{}
    if (Test-Path $path) {
        foreach ($line in Get-Content $path) {
            if ($line -match '^\s*([A-Z_]+)\s*=(.*)$') { $values[$Matches[1]] = $Matches[2].Trim() }
        }
    }
    return $values
}

# Data of minors: warns (never stops) if the disk of this folder is not encrypted.
function Test-BitLocker {
    $drive = Split-Path -Qualifier $here
    $status = $null
    try {
        $status = "$((Get-BitLockerVolume -MountPoint $drive -ErrorAction Stop).ProtectionStatus)"
    } catch {
        # Without administrator rights Get-BitLockerVolume fails; the Explorer's property does not need them.
        try {
            $value = (New-Object -ComObject Shell.Application).NameSpace("$drive\").Self.ExtendedProperty("System.Volume.BitLockerProtection")
            $status = switch ($value) { 1 { "On" } 2 { "Off" } default { $null } }
        } catch {
            $status = $null
        }
    }
    if ($status -eq "On") { return }
    if ($status -eq "Off") {
        Write-Warn "El disco $drive no tiene BitLocker activo y aquí se guardan datos de menores: actívalo antes del evento."
    } else {
        Write-Warn "No se ha podido comprobar si el disco $drive tiene BitLocker; compruébalo a mano (datos de menores)."
    }
}

# Only this Windows user (plus SYSTEM and Administrators) can open brackety-data: it holds data of minors,
# the database keys and the staff passwords. Everything created inside inherits it.
function Protect-DataFolder {
    $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    & icacls.exe $data /inheritance:r /grant:r "*${me}:(OI)(CI)F" "*S-1-5-18:(OI)(CI)F" "*S-1-5-32-544:(OI)(CI)F" > $null
    if ($LASTEXITCODE -ne 0) { Write-Warn "No se han podido restringir los permisos de brackety-data (icacls)." }
}

function Initialize-Data {
    foreach ($needed in @($java, $jar, "$pgBin\postgres.exe", "$webDir\index.html")) {
        if (-not (Test-Path $needed)) { throw "Falta $needed. Vuelve a generar la carpeta con build-event-bundle.ps1." }
    }
    $firstStart = -not (Test-Path $data)
    New-Item -ItemType Directory -Force -Path $data | Out-Null
    if ($firstStart) { Protect-DataFolder }
    New-Item -ItemType Directory -Force -Path (Join-Path $data "backups") | Out-Null
    if (-not (Test-Path $secretsFile)) {
        Set-Content -Path $secretsFile -Encoding ascii -Value @(
            "# Generado en el primer arranque. No lo compartas ni lo borres: sin él no se abre la BD.",
            "DB_PASSWORD=$(New-Secret)",
            "JWT_SECRET=$(New-Secret)")
    }
    if (-not (Test-Path $eventFile)) {
        Set-Content -Path $eventFile -Encoding utf8 -Value @(
            "# Datos legales que muestra la web (páginas legales). Edita y vuelve a arrancar.",
            "LEGAL_OWNER_NAME=",
            "PRIVACY_CONTACT_EMAIL=")
    }
}

function Initialize-Database([string]$password) {
    if (Test-Path "$pgData\PG_VERSION") { return }
    Write-Step "Primer arranque: creando la base de datos en $pgData"
    $pwFile = Join-Path $data "initdb.pw"
    Set-Content -Path $pwFile -Encoding ascii -Value $password -NoNewline
    try {
        # ICU with Spanish rules, like a real sort of names with accents; C for the rest (no system locale).
        & "$pgBin\initdb.exe" -D $pgData -U $DbUser --pwfile=$pwFile -A scram-sha-256 -E UTF8 `
            --locale=C --locale-provider=icu --icu-locale=es-ES > (Join-Path $data "initdb.log") 2>&1
        if ($LASTEXITCODE -ne 0) { throw "initdb ha fallado: mira brackety-data\initdb.log." }
    } finally {
        Remove-Item $pwFile -Force -ErrorAction SilentlyContinue
    }
    Add-Content -Path "$pgData\postgresql.conf" -Encoding ascii -Value @(
        "",
        "# Brackety: only this laptop reaches the database.",
        "listen_addresses = '127.0.0.1'",
        "port = $PgPort")
}

function Test-PgRunning {
    & "$pgBin\pg_ctl.exe" status -D $pgData *> $null
    return $LASTEXITCODE -eq 0
}

function Start-Postgres {
    if (Test-PgRunning) {
        & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p $PgPort -q
        if ($LASTEXITCODE -eq 0) {
            Write-Step "PostgreSQL ya estaba arrancado: se usa ese."
            return
        }
    }
    # Not running but its pid file is left (power cut, killed window): it would block the start.
    $pidFile = Join-Path $pgData "postmaster.pid"
    if (Test-Path $pidFile) {
        $oldPid = [int](Get-Content $pidFile -TotalCount 1)
        $process = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if (-not $process -or $process.ProcessName -ne "postgres") { Remove-Item $pidFile -Force }
    }
    Write-Step "Arrancando PostgreSQL (127.0.0.1:$PgPort)"
    # Its own hidden console: Ctrl+C here must stop the API, not PostgreSQL before the copy. And not
    # "& pg_ctl > $null": postgres would inherit that pipe and PowerShell would wait for it forever.
    $logFile = Join-Path $data "pg.log"
    $pgCtl = Start-Process -FilePath "$pgBin\pg_ctl.exe" -WindowStyle Hidden -PassThru `
        -ArgumentList "start -s -w -t 60 -D `"$pgData`" -l `"$logFile`""
    $null = $pgCtl.Handle
    $pgCtl.WaitForExit()
    if ($pgCtl.ExitCode -ne 0) {
        if (Get-NetTCPConnection -LocalPort $PgPort -State Listen -ErrorAction SilentlyContinue) {
            throw "PostgreSQL no arranca: el puerto $PgPort ya está en uso (¿otra copia de Brackety abierta?)."
        }
        throw "PostgreSQL no arranca: mira brackety-data\pg.log."
    }
}

function Start-Api {
    $process = Start-Process -FilePath $java -ArgumentList "-jar `"$jar`"" -WorkingDirectory $data -NoNewWindow -PassThru
    # Reading the handle now keeps ExitCode available after the process ends.
    $null = $process.Handle
    return $process
}

function Stop-Postgres {
    if (Test-PgRunning) {
        Write-Step "Parando PostgreSQL"
        & "$pgBin\pg_ctl.exe" stop -D $pgData -m fast -w > $null
    }
}

function Confirm-DatabaseExists {
    $exists = & "$pgBin\psql.exe" -h 127.0.0.1 -p $PgPort -U $DbUser -d postgres -tAc `
        "select 1 from pg_database where datname = '$DbName'"
    if ($exists -ne "1") {
        & "$pgBin\createdb.exe" -h 127.0.0.1 -p $PgPort -U $DbUser $DbName
        if ($LASTEXITCODE -ne 0) { throw "No se ha podido crear la base de datos $DbName." }
    }
}

function Invoke-Backup {
    $dir = Join-Path $data "backups"
    $file = Join-Path $dir ("brackety-{0}.dump" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    & "$pgBin\pg_dump.exe" -h 127.0.0.1 -p $PgPort -U $DbUser -d $DbName -Fc -f "$file.partial"
    if ($LASTEXITCODE -ne 0) {
        Remove-Item "$file.partial" -Force -ErrorAction SilentlyContinue
        Write-Warn "No se ha podido guardar la copia de la base de datos."
        return
    }
    Move-Item "$file.partial" $file
    Get-ChildItem $dir -Filter "brackety-*.dump" | Sort-Object Name -Descending |
        Select-Object -Skip $KeptBackups | Remove-Item -Force
    Write-Step ("Copia guardada: {0} ({1:N0} KB)" -f $file, ((Get-Item $file).Length / 1KB))
}

# Runs in Windows PowerShell 5.1: PowerShell 7 cannot load the WinRT types of the hotspot.
function Enable-Hotspot {
    $script = @'
$ErrorActionPreference = "Stop"
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    $null = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]
    $null = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]
    $null = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]
    $p = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
    if (-not $p) { "NO_UPSTREAM"; exit }
    $m = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($p)
    if ($m.TetheringOperationalState -eq 'On') { "ON $($m.ClientCount)"; exit }
    $t = $asTask.MakeGenericMethod([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult]).Invoke($null, @($m.StartTetheringAsync()))
    $null = $t.Wait(20000)
    if ($t.IsCompleted -and "$($t.Result.Status)" -eq 'Success') { "STARTED" } else { "FAILED $($t.Result.Status)" }
} catch {
    "FAILED $($_.Exception.Message)"
}
'@
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script))
    $result = (& powershell.exe -NoProfile -NonInteractive -EncodedCommand $encoded | Select-Object -Last 1)
    switch -Wildcard ("$result") {
        "ON *" { Write-Step "Punto de acceso ya activo ($($result.Substring(3)) dispositivos conectados)." }
        "STARTED" { Write-Step "Punto de acceso activado." }
        "NO_UPSTREAM" {
            Write-Warn "Windows solo activa el punto de acceso si el portátil tiene una conexión que compartir."
            Write-Warn "Conecta antes el portátil a la wifi del móvil (compartir Internet) y vuelve a arrancar."
        }
        default {
            Write-Warn "No se ha podido activar el punto de acceso ($result)."
            Write-Warn "Actívalo a mano: Configuración > Red e Internet > Zona con cobertura inalámbrica móvil;"
            Write-Warn "y desactiva allí el ahorro de energía para que no se apague solo."
        }
    }
}

# Only the hotspot's network: another wifi the laptop joins (a hotel, the sports hall's) cannot reach the API.
# Loopback is never filtered, so http://localhost keeps working.
function Test-HallOnly($rule) {
    $remote = @(($rule | Get-NetFirewallAddressFilter).RemoteAddress)
    return $remote.Count -eq 1 -and $remote[0] -in @($HallSubnet, "192.168.137.0/255.255.255.0")
}

function Confirm-FirewallRule {
    $rules = Get-NetFirewallApplicationFilter -Program $java -ErrorAction SilentlyContinue |
        Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq "True" -and $_.Direction -eq "Inbound" }
    $blocked = $rules | Where-Object { $_.Action -eq "Block" }
    $allowed = @($rules | Where-Object { $_.Action -eq "Allow" })
    $open = @($allowed | Where-Object { -not (Test-HallOnly $_) })
    if ($allowed.Count -gt 0 -and -not $blocked -and $open.Count -eq 0) { return }
    $problem = if ($open.Count -gt 0) {
        "La regla del firewall deja entrar al servidor desde cualquier red; hay que limitarla al punto de acceso ($HallSubnet)."
    } else {
        "Falta la regla del firewall para que los móviles lleguen al servidor (puerto $ApiPort, solo desde $HallSubnet)."
    }
    if ([Console]::IsInputRedirected) {
        Write-Warn "$problem Arranca a mano una vez para corregirla."
        return
    }
    Write-Host $problem
    $answer = Read-Host "¿Corregirla ahora? Windows pedirá permiso de administrador (S/n)"
    if ($answer -match '^[nN]') {
        Write-Warn "Sin corregirla los móviles pueden no llegar al servidor (o llegaría cualquiera); desde este portátil sí funciona."
        return
    }
    # Every inbound rule of this java.exe goes first: Windows' own "Java" block rules (a declined pop-up) win
    # over any allow rule, and its allow rules (an accepted pop-up) open every port from any network.
    $ruleScript = @"
Get-NetFirewallApplicationFilter -Program '$java' -ErrorAction SilentlyContinue | Get-NetFirewallRule | Where-Object { `$_.Direction -eq 'Inbound' } | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName 'Brackety pabellon (API $ApiPort)' -Direction Inbound -Action Allow -Program '$java' -Protocol TCP -LocalPort $ApiPort -RemoteAddress '$HallSubnet' -Profile Private,Public | Out-Null
"@
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ruleScript))
    try {
        Start-Process powershell.exe -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -EncodedCommand $encoded"
        Write-Step "Regla del firewall lista (puerto $ApiPort, solo desde $HallSubnet)."
    } catch {
        Write-Warn "No se ha corregido la regla del firewall: los móviles pueden no llegar al servidor."
    }
}

function Invoke-Reset {
    if (-not (Test-Path $data)) {
        Write-Step "No hay brackety-data: nada que archivar."
        return
    }
    if ((Get-NetTCPConnection -LocalPort $ApiPort -State Listen -ErrorAction SilentlyContinue) -or (Test-PgRunning)) {
        throw "El servidor está en marcha: páralo (Ctrl+C en su ventana) antes de usar -Reset."
    }
    $archive = "brackety-data.old-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Se renombrará brackety-data a $archive (no se borra nada) y el próximo arranque empezará de cero."
    $answer = Read-Host "¿Seguir? (s/N)"
    if ($answer -notmatch '^[sS]') { throw "Cancelado: no se ha tocado nada." }
    Rename-Item -Path $data -NewName $archive
    Write-Step "Datos archivados en $(Join-Path $here $archive). Bórralos a mano cuando ya no hagan falta (datos de menores)."
}

# new-package / new-demo on the first start of an empty data folder; package / demo afterwards.
function Get-StartMode {
    if ($Package -and $Demo) { throw "Usa -Package o -Demo, no los dos." }
    if (Test-Path "$pgData\PG_VERSION") {
        if ($Package -or $Demo) {
            throw ("brackety-data ya tiene un evento: arranca sin -Package ni -Demo para seguir con él, " +
                "o archiva los datos con -Reset (no borra nada) y vuelve a cargar el evento.")
        }
        if (Test-Path $packageMark) { return "package" }
        if (Test-Path $demoMark) { return "demo" }
        throw ("El primer arranque no terminó bien (¿falló la carga del paquete? mira brackety-data\api.log). " +
            "Archiva los datos con -Reset y vuelve a arrancar con -Package o -Demo.")
    }
    if ($Package) {
        if (-not (Test-Path $Package -PathType Leaf)) { throw "No se encuentra el paquete $Package." }
        return "new-package"
    }
    if ($Demo) { return "new-demo" }
    throw ("Primer arranque: indica el evento con -Package <fichero .zip o .brackety> (el que exporta el club) " +
        "o -Demo (evento de prueba con las cuentas demo).")
}

# Keeps the package with the data it brings (both hold data of minors and are deleted together).
function Copy-Package {
    $target = Join-Path $data (Split-Path $Package -Leaf)
    if ((Resolve-Path $Package).Path -ne $target) { Copy-Item -Path $Package -Destination $target -Force }
    return $target
}

# The package of the first start, from package-loaded.txt ("Paquete: <file>"); empty if it is not there.
function Get-LoadedPackage {
    if (-not (Test-Path $packageMark)) { return "" }
    $line = Get-Content $packageMark -Encoding UTF8 | Where-Object { $_ -like "Paquete: *" } | Select-Object -First 1
    if (-not $line) { return "" }
    $file = Join-Path $data $line.Substring("Paquete: ".Length).Trim()
    if (Test-Path $file -PathType Leaf) { return $file }
    return ""
}

function Show-PackageError {
    $log = Join-Path $data "api.log"
    $reason = if (Test-Path $log) {
        Select-String -Path $log -Pattern 'Event package .* not loaded: .*' | Select-Object -Last 1
    }
    if ($reason) { Write-Warn "Paquete rechazado: $($reason.Matches[0].Value)" }
    Write-Warn "No se ha cargado nada. Corrige el paquete (o exporta otro) y vuelve a cargarlo con -Reset -Package <fichero>."
}

function Set-ApiEnvironment([hashtable]$secrets, [string]$mode, [string]$packageFile) {
    $legal = Read-EnvFile $eventFile
    $owner = if ($LegalOwnerName) { $LegalOwnerName } else { $legal["LEGAL_OWNER_NAME"] }
    $privacy = if ($PrivacyContactEmail) { $PrivacyContactEmail } else { $legal["PRIVACY_CONTACT_EMAIL"] }
    # Kept for the next start: after a power cut the plain command must bring the same legal data back.
    if ($LegalOwnerName -or $PrivacyContactEmail) {
        Set-Content -Path $eventFile -Encoding utf8 -Value @(
            "# Datos legales que muestra la web (páginas legales). Edita y vuelve a arrancar.",
            "LEGAL_OWNER_NAME=$owner",
            "PRIVACY_CONTACT_EMAIL=$privacy")
    }
    $day = if ($EventDate) { $EventDate } else { Get-Date -Format "yyyy-MM-dd" }
    $null = [datetime]::ParseExact($day, "yyyy-MM-dd", $null)

    $env:SERVER_PORT = "$ApiPort"
    $env:DB_URL = "jdbc:postgresql://127.0.0.1:$PgPort/$DbName"
    $env:DB_USER = $DbUser
    $env:DB_PASSWORD = $secrets["DB_PASSWORD"]
    $env:JWT_SECRET = $secrets["JWT_SECRET"]
    $env:PUBLIC_BASE_URL = "http://${HotspotIp}:$ApiPort"
    $env:CORS_ALLOWED_ORIGINS = ""
    # Phones without signal for a while keep their session; the refresh token still rotates.
    $env:ACCESS_TTL = "12h"
    # Plain http in the hall: a Secure refresh cookie never comes back and a page reload would lose the session.
    $env:REFRESH_COOKIE_SECURE = "false"
    # No proxy in front: Tomcat would trust X-Forwarded-For from any private IP, so a phone of the hotspot
    # could pick its own IP and dodge the sign-in lockout and the rate limiter.
    $env:SERVER_FORWARD_HEADERS_STRATEGY = "none"
    $env:WEB_DIR = $webDir
    $env:LEGAL_OWNER_NAME = $owner
    $env:PRIVACY_CONTACT_EMAIL = $privacy
    # Only the demo data folder creates demo accounts: a package brings its own and must not get a second event.
    $env:DEMO_ACCOUNTS_ENABLED = if ($mode -like "*demo") { "true" } else { "false" }
    $env:DEMO_EVENT_DATE = $day
    if ($packageFile) {
        $env:BRACKETY_PACKAGE = $packageFile
        $env:BRACKETY_PACKAGE_CREDENTIALS = $credentialsFile
    } else {
        Remove-Item Env:BRACKETY_PACKAGE, Env:BRACKETY_PACKAGE_CREDENTIALS -ErrorAction SilentlyContinue
    }
    $env:BRACKETY_PACKAGE_USERNAME_PASSWORDS = if ($UsernamePasswords) { "true" } else { "false" }
    # The superadmin can start the event again from the package it was loaded from (kept in brackety-data).
    $resetPackage = if ($packageFile) { $packageFile } else { Get-LoadedPackage }
    if ($resetPackage) {
        $env:BRACKETY_RESET_PACKAGE = $resetPackage
    } else {
        Remove-Item Env:BRACKETY_RESET_PACKAGE -ErrorAction SilentlyContinue
    }
    $env:LOGGING_FILE_NAME = Join-Path $data "api.log"
    foreach ($offline in @("RESEND_API_KEY", "GOOGLE_CLIENT_ID", "CF_ACCESS_TEAM_DOMAIN", "CF_ACCESS_AUD",
            "ANTHROPIC_API_KEY")) {
        Remove-Item "env:$offline" -ErrorAction SilentlyContinue
    }
    # No Cloudflare Access here: the superadmin API and web answer only this laptop (loopback).
    $env:ADMIN_LOCAL_ONLY = "true"
    $env:SUPERADMIN_EMAIL = $secrets["SUPERADMIN_EMAIL"]
    $env:SUPERADMIN_PASSWORD_HASH = $secrets["SUPERADMIN_PASSWORD_HASH"]
    if (Test-Path "$adminWebDir\index.html") {
        $env:ADMIN_WEB_DIR = $adminWebDir
    } else {
        Remove-Item Env:ADMIN_WEB_DIR -ErrorAction SilentlyContinue
    }
    if (-not $privacy) { Write-Warn "Sin PRIVACY_CONTACT_EMAIL (brackety-data\event.env) no se pueden publicar eventos." }
}

# First start: a random superadmin password for this laptop, hashed by the API's own encoder. Only the hash
# stays in secrets.env; the password goes to superadmin.txt, like the staff passwords.
function Initialize-Superadmin {
    if ((Read-EnvFile $secretsFile)["SUPERADMIN_PASSWORD_HASH"]) { return }
    $email = "superadmin@pabellon.local"
    $password = (New-Secret).Substring(0, 20)
    $hash = ($password | & $java -jar $jar --superadmin-hash | Select-Object -Last 1)
    if ($LASTEXITCODE -ne 0 -or -not $hash) { throw "No se ha podido generar la contraseña del superadmin." }
    Add-Content -Path $secretsFile -Encoding ascii -Value @("SUPERADMIN_EMAIL=$email", "SUPERADMIN_PASSWORD_HASH=$hash")
    Set-Content -Path $superadminFile -Encoding utf8 -Value @(
        "Superadmin de este portátil (solo funciona en http://localhost:$ApiPort/admin/):",
        "  Email: $email",
        "  Contraseña: $password")
    Write-Step "Superadmin creado: datos en $superadminFile"
}

function Show-Credentials {
    if (-not (Test-Path $credentialsFile)) { return }
    Write-Host ""
    Write-Host "Cuentas del staff creadas por el paquete (también en $credentialsFile):" -ForegroundColor Green
    Get-Content $credentialsFile -Encoding UTF8 | ForEach-Object { Write-Host "  $_" }
    Write-Warn "Reparte cada contraseña a mano solo a su dueño (no por grupos de mensajería)."
    Write-Warn "Borra credentials.txt cuando acabe la fase."
}

function Wait-ApiReady([System.Diagnostics.Process]$api) {
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Date) -lt $deadline) {
        if ($api.HasExited) { throw "La API se ha parado al arrancar: mira brackety-data\api.log." }
        try {
            $null = Invoke-RestMethod -Uri "http://localhost:$ApiPort/api/v1/info" -TimeoutSec 2
            return
        } catch {
            Start-Sleep -Seconds 1
        }
    }
    throw "La API no responde tras 3 minutos: mira brackety-data\api.log."
}

function Stop-Api([System.Diagnostics.Process]$api) {
    if (-not $api -or $api.HasExited) { return }
    Write-Step "Parando la API"
    # Ctrl+C already reached Java (same console) and it is closing on its own; give it time to finish.
    if (-not $api.WaitForExit(30000)) { Stop-Process -Id $api.Id -Force }
}

if ($Reset) {
    Invoke-Reset
    if (-not $Package -and -not $Demo) { return }
}
# Before anything is created: a first start without the event must leave the folder empty.
$mode = if ($Backup) { "" } else { Get-StartMode }

Initialize-Data
if (-not $Backup) { Initialize-Superadmin }
$secrets = Read-EnvFile $secretsFile
$env:PGPASSWORD = $secrets["DB_PASSWORD"]
Initialize-Database $secrets["DB_PASSWORD"]

if ($Backup) {
    $wasRunning = Test-PgRunning
    Start-Postgres
    try {
        Confirm-DatabaseExists
        Invoke-Backup
    } finally {
        if (-not $wasRunning) { Stop-Postgres }
    }
    return
}

if (Get-NetTCPConnection -LocalPort $ApiPort -State Listen -ErrorAction SilentlyContinue) {
    throw "El puerto $ApiPort ya está en uso (¿otro servidor de Brackety abierto?). Ciérralo y vuelve a arrancar."
}
Test-BitLocker
if (-not $NoHotspot) { Enable-Hotspot }
if (-not $NoFirewall) { Confirm-FirewallRule }

$api = $null
try {
    Start-Postgres
    Confirm-DatabaseExists
    $packageFile = if ($mode -eq "new-package") { Copy-Package } else { "" }
    Set-ApiEnvironment $secrets $mode $packageFile
    $loading = if ($packageFile) { " y cargando el paquete $(Split-Path $packageFile -Leaf)" } else { "" }
    Write-Step "Arrancando la API$loading (puede tardar un minuto)"
    $api = Start-Api
    try {
        Wait-ApiReady $api
    } catch {
        if ($packageFile) { Show-PackageError }
        throw
    }
    $loaded = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    if ($mode -eq "new-package") {
        Set-Content -Path $packageMark -Encoding utf8 -Value @("Paquete: $(Split-Path $packageFile -Leaf)", "Cargado: $loaded")
        Write-Step "Paquete $(Split-Path $packageFile -Leaf) cargado."
        Show-Credentials
    } elseif ($mode -eq "new-demo") {
        Set-Content -Path $demoMark -Encoding utf8 -Value @("Evento demo y cuentas demo", "Creado: $loaded")
    }
    Write-Host ""
    Write-Host "Brackety listo." -ForegroundColor Green
    Write-Host "  Móviles (wifi del punto de acceso): http://${HotspotIp}:$ApiPort"
    Write-Host "  Este portátil:                      http://localhost:$ApiPort"
    if ($env:ADMIN_WEB_DIR) {
        Write-Host "  Superadmin (solo este portátil):    http://localhost:$ApiPort/admin/ (cuenta en superadmin.txt)"
    }
    Write-Host "  Datos: $data"
    Write-Host "  Para parar: Ctrl+C (guarda una copia de la base de datos al salir)."
    Write-Host ""
    # The package is in the database now: a restart must not try to load it again.
    Remove-Item Env:BRACKETY_PACKAGE, Env:BRACKETY_PACKAGE_CREDENTIALS -ErrorAction SilentlyContinue
    $crashes = @()
    while ($true) {
        while (-not $api.HasExited) { Start-Sleep -Milliseconds 500 }
        Write-Warn "La API se ha parado (código $($api.ExitCode)): mira brackety-data\api.log."
        # A crash mid-event must not leave the phones without server; one that keeps failing needs a person.
        $crashes = @($crashes | Where-Object { $_ -gt (Get-Date).AddMinutes(-10) }) + (Get-Date)
        if ($crashes.Count -gt 3) {
            Write-Warn "Se ha parado $($crashes.Count) veces en 10 minutos: no se vuelve a arrancar sola."
            break
        }
        if (-not (Test-PgRunning)) { Start-Postgres }
        try { Invoke-Backup } catch { Write-Warn "No se ha podido guardar la copia: $($_.Exception.Message)" }
        Write-Step "Volviendo a arrancar la API (los móviles conservan sus acciones sin enviar)"
        $api = Start-Api
        Wait-ApiReady $api
        Write-Host "Brackety listo de nuevo." -ForegroundColor Green
    }
} finally {
    Write-Host "Cerrando: no cierres la ventana hasta que termine la copia."
    Stop-Api $api
    try {
        # PostgreSQL may have stopped on its own meanwhile: start it again just for the copy.
        if (-not (Test-PgRunning)) { Start-Postgres }
        Invoke-Backup
    } catch {
        Write-Warn "No se ha podido guardar la copia: $($_.Exception.Message)"
    }
    Stop-Postgres
    Remove-Item Env:PGPASSWORD, Env:DB_PASSWORD, Env:JWT_SECRET, Env:BRACKETY_PACKAGE,
        Env:BRACKETY_PACKAGE_CREDENTIALS, Env:BRACKETY_RESET_PACKAGE -ErrorAction SilentlyContinue
}
