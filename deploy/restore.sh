#!/usr/bin/env bash
# Usage: ./restore.sh <backup.dump.age> <age-identity-file> [database]
# By default restores into a scratch database (restore_check) to verify a backup without touching production.
# Passing "brackety" replaces production, but only after the backup has restored cleanly into a scratch
# database; the old one is renamed, not dropped.
set -euo pipefail
cd "$(dirname "$0")"

[[ $# -ge 2 ]] || { echo "Usage: $0 <backup.dump.age> <age-identity-file> [database]" >&2; exit 2; }
backup="$1"
identity="$2"
target="${3:-restore_check}"
[[ "$target" =~ ^[a-z_][a-z0-9_]*$ ]] || { echo "Invalid database name: $target" >&2; exit 2; }
case "$target" in
  postgres | template0 | template1 | brackety_restore) echo "Reserved database name: $target" >&2; exit 2 ;;
esac

# </dev/null: exec -T would otherwise swallow the script's stdin, including the confirmation below.
sql() { docker compose exec -T db sh -c 'psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "$1"' sh "$1" < /dev/null; }

scratch="$target"
[[ "$target" == brackety ]] && scratch=brackety_restore

sql "DROP DATABASE IF EXISTS \"$scratch\" WITH (FORCE)"
sql "CREATE DATABASE \"$scratch\""
age -d -i "$identity" "$backup" |
  docker compose exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d "$1" --no-owner --exit-on-error' sh "$scratch"
echo "Restored $backup into database '$scratch'"

if [[ "$target" != brackety ]]; then
  echo "Check it, then drop it: docker compose exec db psql -U <DB_USER> -d postgres -c 'DROP DATABASE $target'"
  exit 0
fi

read -r -p "Replace the production database with it? Type 'brackety' to continue: " answer
[[ "$answer" == brackety ]] || { echo "Cancelled; production untouched, restored copy left in $scratch" >&2; exit 1; }

old="brackety_old_$(date +%Y%m%d_%H%M%S)"
trap 'echo "Swap failed: check the databases and run: docker compose start api" >&2' ERR
docker compose stop api
sql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'brackety' AND pid <> pg_backend_pid()" > /dev/null
sql "ALTER DATABASE brackety RENAME TO \"$old\""
sql "ALTER DATABASE \"$scratch\" RENAME TO brackety"
docker compose start api
trap - ERR
echo "Production restored. Previous database kept as '$old'; drop it once everything works."
