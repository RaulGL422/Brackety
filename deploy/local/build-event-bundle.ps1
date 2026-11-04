<#
.SYNOPSIS
    Prepara la carpeta portable del servidor del pabellón: dist/brackety-event.
.DESCRIPTION
    Se ejecuta en el PC de desarrollo (necesita Internet la primera vez para bajar PostgreSQL; el zip queda en
    dist/cache). La carpeta resultante se copia a cualquier portátil Windows 10/11 x64 y se arranca con
    start-event.ps1, sin instalar nada. Detalle en docs/modulos/servidor-local.md.
    Si la carpeta ya tiene datos (brackety-data), se conservan: solo se reemplazan los programas.
.EXAMPLE
    .\deploy\local\build-event-bundle.ps1
#>
$ErrorActionPreference = "Stop"

$PgVersion = "18.6-1"
$PgUrl = "https://get.enterprisedb.com/postgresql/postgresql-$PgVersion-windows-x64-binaries.zip"

$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$dist = Join-Path $root "dist"
$bundle = Join-Path $dist "brackety-event"
$cache = Join-Path $dist "cache"

function Invoke-Checked([string]$what, [scriptblock]$command) {
    & $command
    if ($LASTEXITCODE -ne 0) { throw "Ha fallado: $what (código $LASTEXITCODE)." }
}

# By the JDK's own release file, as run-server.ps1: the folder name is not reliable.
$jdk = Get-ChildItem "$env:USERPROFILE\.jdks" -Directory -ErrorAction SilentlyContinue |
    Where-Object { Select-String -Path "$($_.FullName)\release" -Pattern '^JAVA_VERSION="25[."]' -Quiet -ErrorAction SilentlyContinue } |
    Sort-Object Name -Descending | Select-Object -First 1
if (-not $jdk) { throw "No se encuentra un JDK 25 en ~/.jdks." }
$env:JAVA_HOME = $jdk.FullName

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = "C:\dev\flutter\bin\flutter.bat" }

New-Item -ItemType Directory -Force -Path $bundle, $cache | Out-Null
foreach ($old in @("api", "web", "jre", "pgsql", "start-event.ps1", "LEEME.txt")) {
    $path = Join-Path $bundle $old
    if (Test-Path $path) { Remove-Item -Recurse -Force $path }
}

Write-Host "1/5 API: jar de producción"
Invoke-Checked "el build de la API" { & "$root\server\mvnw.cmd" -q -B -f "$root\server\pom.xml" package -DskipTests }
$jar = Get-ChildItem "$root\server\target" -Filter "brackety-server-*.jar" | Select-Object -First 1
New-Item -ItemType Directory -Force -Path "$bundle\api" | Out-Null
Copy-Item $jar.FullName "$bundle\api\brackety.jar"

Write-Host "2/5 Web: build de Flutter servida por la propia API"
Push-Location "$root\app"
try {
    # No CDN: in the hall there is no Internet, CanvasKit and the fonts must come from the laptop.
    Invoke-Checked "el build web" {
        & $flutter build web --release --no-web-resources-cdn --dart-define-from-file=env/event-bundle.json
    }
} finally {
    Pop-Location
}
Copy-Item -Recurse "$root\app\build\web" "$bundle\web"

Write-Host "3/5 Java: runtime reducido con jlink"
Invoke-Checked "jlink" {
    & "$($jdk.FullName)\bin\jlink.exe" --module-path "$($jdk.FullName)\jmods" --add-modules ALL-MODULE-PATH `
        --strip-debug --no-header-files --no-man-pages --output "$bundle\jre"
}

Write-Host "4/5 PostgreSQL $PgVersion (binarios oficiales de EnterpriseDB)"
$zip = Join-Path $cache "postgresql-$PgVersion-windows-x64-binaries.zip"
if (-not (Test-Path $zip)) {
    Write-Host "   Descargando $PgUrl (unos 340 MB, solo la primera vez)"
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $PgUrl -OutFile "$zip.partial" -UseBasicParsing
    Move-Item "$zip.partial" $zip
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
try {
    # Only the server and its tools: no pgAdmin, StackBuilder, docs or headers.
    $wanted = $archive.Entries | Where-Object {
        $_.FullName -match '^pgsql/(bin|lib|share)/.+[^/]$' -and $_.FullName -notmatch '(stackbuilder|/wx[^/]*\.dll$|\.lib$)'
    }
    foreach ($entry in $wanted) {
        $target = Join-Path $bundle $entry.FullName
        New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
    }
} finally {
    $archive.Dispose()
}
# PostgreSQL needs the Visual C++ runtime, which a clean laptop may lack: the JDK ships the same DLLs.
foreach ($dll in @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll")) {
    Copy-Item "$($jdk.FullName)\bin\$dll" "$bundle\pgsql\bin\"
}

Write-Host "5/5 Scripts"
Copy-Item "$PSScriptRoot\start-event.ps1" $bundle
Copy-Item "$PSScriptRoot\LEEME.txt" $bundle

$size = (Get-ChildItem $bundle -Recurse -File | Where-Object { $_.FullName -notlike "*\brackety-data\*" } |
    Measure-Object Length -Sum).Sum / 1MB
Write-Host ("Listo: {0} ({1:N0} MB). Cópiala al portátil y arranca start-event.ps1." -f $bundle, $size)
