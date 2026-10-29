#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"
docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 -f - < "$root/seed.sql"
