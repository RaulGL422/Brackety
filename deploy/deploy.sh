#!/usr/bin/env bash
# Usage: ./deploy.sh [pi|windows|local|debug|debug-stop]
# pi/windows: pull the published images and start the tunnel. local: use images already built on this machine.
# debug: the debug environment next to production on the Pi (.env.debug, docs/modulos/entornos.md).
# debug-stop: stop it (event days); ./deploy.sh debug starts it again.
set -euo pipefail
cd "$(dirname "$0")"

mode="${1:-pi}"
services=(api web admin)
env=.env
rollback=rollback

case "$mode" in
  pi | windows) compose=(docker compose --profile "$mode") ;;
  local) compose=(docker compose) ;;
  debug | debug-stop)
    env=.env.debug
    # Its own tag, so a debug deploy never overwrites production's way back.
    rollback=rollback-debug
    compose=(docker compose --env-file "$env" -f docker-compose.yml -f docker-compose.debug.yml --profile pi)
    ;;
  *) echo "Usage: $0 [pi|windows|local|debug|debug-stop]" >&2; exit 2 ;;
esac

[[ -f "$env" ]] || { echo "Missing deploy/$env: copy $env.example and fill it in" >&2; exit 1; }

if [[ "$mode" == debug-stop ]]; then
  "${compose[@]}" stop
  echo "Debug stopped; ./deploy.sh debug starts it again"
  exit 0
fi

# An empty token makes the tunnel restart forever and would roll back a healthy release.
if [[ "$mode" != local ]] && ! grep -Eq '^CLOUDFLARE_TUNNEL_TOKEN=.+' "$env"; then
  echo "Set CLOUDFLARE_TUNNEL_TOKEN in deploy/$env" >&2
  exit 1
fi

# Without it the api never becomes healthy and every deploy would roll back.
if ! grep -Eq '^JWT_SECRET=.{32,}' "$env"; then
  echo "Set JWT_SECRET in deploy/$env (at least 32 characters: openssl rand -base64 48)" >&2
  exit 1
fi

# A shared secret would let a debug token sign in to production.
secret() { grep -E '^JWT_SECRET=' "$1" | tail -1; }
if [[ "$env" == .env.debug && -f .env && "$(secret .env)" == "$(secret .env.debug)" ]]; then
  echo "Debug must not share JWT_SECRET with production: generate another one in deploy/.env.debug" >&2
  exit 1
fi

# Tag what is running and healthy now, so a failed deploy can go back to it.
saved=0
for s in "${services[@]}"; do
  id=$("${compose[@]}" ps -q "$s" 2>/dev/null || true)
  if [[ -n "$id" && "$(docker inspect --format '{{.State.Health.Status}}' "$id")" == healthy ]]; then
    docker tag "$(docker inspect --format '{{.Image}}' "$id")" "ghcr.io/raulgl422/brackety-$s:$rollback"
    saved=$((saved + 1))
  fi
done

if [[ "$mode" != local ]]; then
  "${compose[@]}" pull --quiet || { echo "Pull failed; nothing was changed" >&2; exit 1; }
fi

if "${compose[@]}" up -d --wait --wait-timeout 300; then
  docker image prune -f >/dev/null
  # Which build runs now, as the apps show it (0.8.2-dev.7 · 8c525af).
  built=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$("${compose[@]}" ps -q api)" \
    | sed -n 's/^BRACKETY_\(VERSION\|COMMIT\)=//p' | paste -sd ' ')
  echo "Deploy OK: ${built:-version unknown}"
  exit 0
fi

echo "Deploy failed: healthchecks did not pass" >&2
"${compose[@]}" ps >&2 || true

# Database migrations are not undone: Flyway ignores newer ones, so the previous api still starts.
if ((saved == ${#services[@]})); then
  echo "Rolling back to the previous images" >&2
  if ! IMAGE_TAG="$rollback" "${compose[@]}" up -d --wait --wait-timeout 300; then
    echo "Rollback failed: the service is down, check docker compose logs" >&2
    exit 1
  fi
  echo "Rollback done; fix the release and deploy again" >&2
else
  echo "Nothing to roll back to (first deploy)" >&2
fi
exit 1
