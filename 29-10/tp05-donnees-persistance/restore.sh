#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
compose_file="${COMPOSE_FILE:-$root/compose.yml}"
project_dir="${COMPOSE_PROJECT_DIR:-$root}"
dump="${1:?dump requis}"
if [ ! -f "$dump" ]; then
  printf 'dump introuvable: %s\n' "$dump" >&2
  exit 1
fi

winpath() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s\n' "$1"
  fi
}

compose() {
  MSYS_NO_PATHCONV=1 docker compose --project-directory "$(winpath "$project_dir")" -f "$(winpath "$compose_file")" "$@"
}

host_path() {
  local file="$1"
  printf '%s' "$(winpath "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")")"
}

compose up -d --wait db
compose cp "$(host_path "$dump")" "db:/tmp/restore.dump"
set +e
compose exec -T db pg_restore -U shop -d shop --clean --if-exists --no-owner --no-privileges /tmp/restore.dump
status=$?
set -e
compose exec -T db rm -f /tmp/restore.dump
if [ "$status" -gt 1 ]; then
  exit "$status"
fi
compose exec -T db psql -U shop -d shop -c "SELECT count(*) AS orders, md5(string_agg(id::text || status, ',' ORDER BY id)) AS checksum FROM orders;"
