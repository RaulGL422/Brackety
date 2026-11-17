#!/usr/bin/env bash
# Hands the phase 1 data over to the entity's production account (docs/09-despliegue.md, "Datos de la F1").
# Usage, on the Pi with production running: ./f1-handover.sh <email> [club account, default club1]
# Shows what would change, asks, and only then commits. Run ./backup.sh first.
set -euo pipefail
cd "$(dirname "$0")"

email="${1:?Usage: $0 <email> [club account, default club1]}"
club="${2:-club1}"

read -rsp "New password for $email (at least 10 characters): " password
echo
((${#password} >= 10)) || { echo "At least 10 characters" >&2; exit 1; }
# The superadmin's hasher uses the same Argon2 settings as every account.
hash=$(printf '%s\n' "$password" | docker compose exec -T api java -jar /app/app.jar --superadmin-hash)

handover() {
  { echo 'begin;'; cat f1-handover.sql; echo "$1;"; } |
    docker compose exec -T db sh -c \
      'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d brackety -v club="$1" -v email="$2" -v hash="$3"' \
      sh "$club" "$email" "$hash"
}

echo "Dry run (nothing is saved):"
handover rollback
read -rp "Type HANDOVER to apply it: " answer
[[ "$answer" == HANDOVER ]] || { echo "Nothing changed" >&2; exit 1; }
handover commit
echo "Done: sign in with $email. The generic accounts can no longer sign in."
