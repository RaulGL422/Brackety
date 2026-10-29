#!/usr/bin/env bash
# Usage: ./restore.sh <backup.dump.age> <age-identity-file> [database]
# By default restores into a scratch database (restore_check) to verify a backup without touching production.
# Passing "brackety" replaces production: asks for confirmation and stops the api meanwhile.
set -euo pipefail
cd "$(dirname "$0")"

[[ $# -ge 2 ]] || { echo "Usage: $0 <backup.dump.age> <age-identity-file> [database]" >&2; exit 2; }
backup="$1"
identity="$2"
target="${3:-restore_check}"
[[ "$target" =~ ^[a-z_][a-z0-9_]*$ ]] || { echo "Invalid database name: $target" >&2; exit 2; }

sql() { docker compose exec -T db sh -c 'psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "$1"' sh "$1"; }

if [[ "$target" == brackety ]]; then
  read -r -p "This replaces the production database. Type 'brackety' to continue: " answer
  [[ "$answer" == brackety ]] || { echo "Cancelled" >&2; exit 1; }
  docker compose stop api
fi

sql "DROP DATABASE IF EXISTS \"$target\" WITH (FORCE)"
sql "CREATE DATABASE \"$target\""
age -d -i "$identity" "$backup" |
  docker compose exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d "$1" --no-owner --exit-on-error' sh "$target"

if [[ "$target" == brackety ]]; then
  docker compose start api
fi

echo "Restored $backup into database '$target'"
[[ "$target" == brackety ]] || echo "Check it, then drop it: docker compose exec db psql -U <DB_USER> -d postgres -c 'DROP DATABASE $target'"
