#!/usr/bin/env bash
# Usage: ./deploy.sh [pi|windows|local]
# pi/windows: pull the published images and start the tunnel. local: use images already built on this machine.
set -euo pipefail
cd "$(dirname "$0")"

mode="${1:-pi}"
services=(api web admin)

case "$mode" in
  pi | windows) compose=(docker compose --profile "$mode") ;;
  local) compose=(docker compose) ;;
  *) echo "Usage: $0 [pi|windows|local]" >&2; exit 2 ;;
esac

[[ -f .env ]] || { echo "Missing deploy/.env: copy .env.example and fill it in" >&2; exit 1; }
# An empty token makes the tunnel restart forever and would roll back a healthy release.
if [[ "$mode" != local ]] && ! grep -Eq '^CLOUDFLARE_TUNNEL_TOKEN=.+' .env; then
  echo "Set CLOUDFLARE_TUNNEL_TOKEN in deploy/.env" >&2
  exit 1
fi

# Tag what is running and healthy now, so a failed deploy can go back to it.
saved=0
for s in "${services[@]}"; do
  id=$("${compose[@]}" ps -q "$s" 2>/dev/null || true)
  if [[ -n "$id" && "$(docker inspect --format '{{.State.Health.Status}}' "$id")" == healthy ]]; then
    docker tag "$(docker inspect --format '{{.Image}}' "$id")" "ghcr.io/raulgl422/brackety-$s:rollback"
    saved=$((saved + 1))
  fi
done

if [[ "$mode" != local ]]; then
  "${compose[@]}" pull --quiet || { echo "Pull failed; nothing was changed" >&2; exit 1; }
fi

if "${compose[@]}" up -d --wait --wait-timeout 300; then
  docker image prune -f >/dev/null
  echo "Deploy OK"
  exit 0
fi

echo "Deploy failed: healthchecks did not pass" >&2
"${compose[@]}" ps >&2 || true

# Database migrations are not undone: Flyway ignores newer ones, so the previous api still starts.
if ((saved == ${#services[@]})); then
  echo "Rolling back to the previous images" >&2
  if ! IMAGE_TAG=rollback "${compose[@]}" up -d --wait --wait-timeout 300; then
    echo "Rollback failed: the service is down, check docker compose logs" >&2
    exit 1
  fi
  echo "Rollback done; fix the release and deploy again" >&2
else
  echo "Nothing to roll back to (first deploy)" >&2
fi
exit 1
