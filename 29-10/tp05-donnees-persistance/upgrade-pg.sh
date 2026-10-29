#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
legacy="$root/starter/compose.yml"
inplace="$root/compose.pg16-inplace.yml"
next="$root/compose.pg16.yml"
out="$root/backups/upgrade"
mkdir -p "$out" "$root/transcripts"

winpath() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s\n' "$1"
  fi
}

dc() {
  MSYS_NO_PATHCONV=1 docker compose "$@"
}

checksum() {
  dc -f "$(winpath "$1")" exec -T db psql -U shop -d shop -tAc "SELECT count(*) || ' ' || md5(string_agg(id::text || status, ',' ORDER BY id)) FROM orders;"
}

dc -f "$(winpath "$next")" down -v --remove-orphans
dc -f "$(winpath "$legacy")" down -v --remove-orphans

dc -f "$(winpath "$legacy")" up -d --wait
dc -f "$(winpath "$legacy")" exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 -f - < "$root/seed.sql"
before="$(checksum "$legacy")"
printf 'CHECKSUM_BEFORE %s\n' "$before"

dc -f "$(winpath "$legacy")" exec -T db sh -c 'pg_dumpall -U shop -f /tmp/all.sql && pg_dump -U shop -d shop -Fc -f /tmp/shop.dump'
dest="$(winpath "$out")"
dc -f "$(winpath "$legacy")" cp "db:/tmp/all.sql" "$dest/pg14-all.sql"
dc -f "$(winpath "$legacy")" cp "db:/tmp/shop.dump" "$dest/pg14.dump"

dc -f "$(winpath "$legacy")" -f "$(winpath "$inplace")" up -d
cid="$(dc -f "$(winpath "$legacy")" -f "$(winpath "$inplace")" ps -aq db)"
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  state="$(docker inspect -f '{{.State.Status}}' "$cid")"
  if [ "$state" = "exited" ]; then
    break
  fi
  sleep 2
done
dc -f "$(winpath "$legacy")" -f "$(winpath "$inplace")" logs db > "$root/transcripts/pg16-inplace.log"
if ! grep -Ei 'compatible' "$root/transcripts/pg16-inplace.log" >/dev/null; then
  printf 'erreur de catalogue absente\n' >&2
  exit 1
fi
dc -f "$(winpath "$legacy")" -f "$(winpath "$inplace")" down

dc -f "$(winpath "$next")" up -d --wait
dc -f "$(winpath "$next")" cp "$dest/pg14.dump" "db:/tmp/restore.dump"
set +e
dc -f "$(winpath "$next")" exec -T db pg_restore -U shop -d shop --no-owner --no-privileges /tmp/restore.dump
status=$?
set -e
if [ "$status" -gt 1 ]; then
  exit "$status"
fi
after="$(checksum "$next")"
printf 'CHECKSUM_AFTER %s\n' "$after"
if [ "$before" != "$after" ]; then
  printf 'VERDICT echec\n' >&2
  exit 1
fi
printf 'VERDICT ok\n'

dc -f "$(winpath "$next")" down
dc -f "$(winpath "$legacy")" up -d --wait
back="$(checksum "$legacy")"
printf 'CHECKSUM_ROLLBACK %s\n' "$back"
if [ "$before" != "$back" ]; then
  printf 'ROLLBACK echec\n' >&2
  exit 1
fi
printf 'ROLLBACK ok\n'
