#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
compose_file="${COMPOSE_FILE:-$root/compose.yml}"
project_dir="${COMPOSE_PROJECT_DIR:-$root}"
volume="${PGVOLUME:-shoplab_pgdata}"
keep="${KEEP:-7}"
consistent=0
if [ "${1:-}" = "--consistent" ]; then
  consistent=1
fi

out="$root/backups"
mkdir -p "$out/logical" "$out/raw"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"

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

host_dir() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  elif pwd -W >/dev/null 2>&1; then
    (cd "$1" && pwd -W)
  else
    (cd "$1" && pwd)
  fi
}

compose exec -T db sh -c 'pg_dump -U shop -d shop -Fc -f /tmp/shop.dump'
logical_name="shop-${stamp}.dump"
logical_host="$(host_dir "$out/logical")/${logical_name}"
compose cp "db:/tmp/shop.dump" "$logical_host"
compose exec -T db rm -f /tmp/shop.dump

raw_name="pgdata-${stamp}.tar.gz"
raw_host="$(host_dir "$out/raw")"
if [ "$consistent" -eq 1 ]; then
  compose stop db
fi
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "${volume}:/data:ro" \
  -v "${raw_host}:/backup" \
  alpine:3.20 \
  tar -C /data -czf "/backup/${raw_name}" .
if [ "$consistent" -eq 1 ]; then
  compose start db
fi

prune_keep() {
  local dir="$1"
  local pattern="$2"
  shopt -s nullglob
  local files=("$dir"/$pattern)
  shopt -u nullglob
  if [ "${#files[@]}" -eq 0 ]; then
    return
  fi
  local i=0
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    i=$((i + 1))
    if [ "$i" -gt "$keep" ]; then
      rm -f "$f"
    fi
  done < <(ls -1t "${files[@]}")
}

prune_keep "$out/logical" 'shop-*.dump'
prune_keep "$out/raw" 'pgdata-*.tar.gz'
printf 'logical %s\n' "$logical_host"
printf 'raw %s/%s\n' "$raw_host" "$raw_name"
