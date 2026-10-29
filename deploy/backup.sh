#!/usr/bin/env bash
# Encrypted database dump, run daily by cron (see docs/09-despliegue.md).
# Keeps 14 daily and 8 weekly (Sunday) copies. Only the age public key lives on the server:
# whoever gets the server cannot read the backups.
set -euo pipefail
cd "$(dirname "$0")"

# Same reading rules as compose: last occurrence wins, CRLF and surrounding quotes are ignored.
env_value() { grep -E "^$1=" .env | tail -1 | cut -d= -f2- | tr -d '\r' | sed -E "s/^\"(.*)\"$/\1/; s/^'(.*)'$/\1/" || true; }
dir="${BACKUP_DIR:-$(env_value BACKUP_DIR)}"
recipient="${BACKUP_AGE_RECIPIENT:-$(env_value BACKUP_AGE_RECIPIENT)}"
[[ -n "$dir" && -n "$recipient" ]] || { echo "Set BACKUP_DIR and BACKUP_AGE_RECIPIENT in deploy/.env" >&2; exit 1; }

mkdir -p "$dir/daily" "$dir/weekly"
file="$dir/daily/brackety-$(date +%F).dump.age"
tmp="$file.partial"
trap 'rm -f "$tmp"' EXIT

docker compose exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d brackety --format=custom' | age -r "$recipient" -o "$tmp"
mv "$tmp" "$file"
[[ "$(date +%u)" == 7 ]] && cp "$file" "$dir/weekly/"

prune() { find "$1" -name 'brackety-*.dump.age' | sort -r | tail -n "+$(($2 + 1))" | xargs -r rm --; }
prune "$dir/daily" 14
prune "$dir/weekly" 8

echo "Backup OK: $file ($(du -h "$file" | cut -f1))"
