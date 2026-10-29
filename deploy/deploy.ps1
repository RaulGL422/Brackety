# Usage: ./deploy.ps1 [-Mode windows|pi|local]
# windows/pi: pull the published images and start the tunnel. local: use images already built on this machine.
# Same steps as deploy.sh; keep both in sync.
param(
    [ValidateSet('windows', 'pi', 'local')]
    [string]$Mode = 'windows'
)

Set-Location $PSScriptRoot
$services = 'api', 'web', 'admin'
$profileArgs = if ($Mode -eq 'local') { @() } else { @('--profile', $Mode) }

function Invoke-Compose {
    docker compose @profileArgs @args | Out-Host
    return $LASTEXITCODE -eq 0
}

function Stop-Deploy([string]$message) {
    Write-Host $message -ForegroundColor Red
    exit 1
}

if (-not (Test-Path .env)) { Stop-Deploy 'Missing deploy/.env: copy .env.example and fill it in' }
# An empty token makes the tunnel restart forever and would roll back a healthy release.
if ($Mode -ne 'local' -and -not (Select-String -Path .env -Pattern '^CLOUDFLARE_TUNNEL_TOKEN=.+' -Quiet)) {
    Stop-Deploy 'Set CLOUDFLARE_TUNNEL_TOKEN in deploy/.env'
}

# Tag what is running and healthy now, so a failed deploy can go back to it.
$saved = 0
foreach ($s in $services) {
    $id = docker compose @profileArgs ps -q $s
    if ($id -and (docker inspect --format '{{.State.Health.Status}}' $id) -eq 'healthy') {
        $image = docker inspect --format '{{.Image}}' $id
        docker tag $image "ghcr.io/raulgl422/brackety-${s}:rollback"
        if (-not $image -or $LASTEXITCODE -ne 0) { Stop-Deploy "Could not tag the rollback image of $s" }
        $saved++
    }
}

if ($Mode -ne 'local' -and -not (Invoke-Compose pull --quiet)) { Stop-Deploy 'Pull failed; nothing was changed' }

if (Invoke-Compose up -d --wait --wait-timeout 300) {
    docker image prune -f | Out-Null
    Write-Host 'Deploy OK' -ForegroundColor Green
    exit 0
}

Write-Host 'Deploy failed: healthchecks did not pass' -ForegroundColor Red
Invoke-Compose ps | Out-Null

# Database migrations are not undone: Flyway ignores newer ones, so the previous api still starts.
if ($saved -ne $services.Count) { Stop-Deploy 'Nothing to roll back to (first deploy)' }

Write-Host 'Rolling back to the previous images' -ForegroundColor Yellow
$previousTag = $env:IMAGE_TAG
$env:IMAGE_TAG = 'rollback'
try { $rolledBack = Invoke-Compose up -d --wait --wait-timeout 300 }
finally { $env:IMAGE_TAG = $previousTag }
if (-not $rolledBack) { Stop-Deploy 'Rollback failed: the service is down, check docker compose logs' }
Write-Host 'Rollback done; fix the release and deploy again' -ForegroundColor Yellow
exit 1
