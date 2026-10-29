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

if (-not (Test-Path .env)) {
    Write-Host 'Missing deploy/.env: copy .env.example and fill it in' -ForegroundColor Red
    exit 1
}

# Tag what is running now, so a failed deploy can go back to it.
$saved = 0
foreach ($s in $services) {
    $id = docker compose @profileArgs ps -q $s
    if ($id) {
        $image = docker inspect --format '{{.Image}}' $id
        docker tag $image "ghcr.io/raulgl422/brackety-${s}:rollback"
        $saved++
    }
}

if ($Mode -ne 'local' -and -not (Invoke-Compose pull --quiet)) {
    Write-Host 'Pull failed; nothing was changed' -ForegroundColor Red
    exit 1
}

if (Invoke-Compose up -d --wait --wait-timeout 300) {
    docker image prune -f | Out-Null
    Write-Host 'Deploy OK' -ForegroundColor Green
    exit 0
}

Write-Host 'Deploy failed: healthchecks did not pass' -ForegroundColor Red
Invoke-Compose ps | Out-Null

# Database migrations are not undone: Flyway ignores newer ones, so the previous api still starts.
if ($saved -eq $services.Count) {
    Write-Host 'Rolling back to the previous images' -ForegroundColor Yellow
    $env:IMAGE_TAG = 'rollback'
    try { Invoke-Compose up -d --wait --wait-timeout 300 | Out-Null }
    finally { Remove-Item Env:IMAGE_TAG }
    Write-Host 'Rollback done; fix the release and deploy again' -ForegroundColor Yellow
} else {
    Write-Host 'Nothing to roll back to (first deploy)' -ForegroundColor Yellow
}
exit 1
