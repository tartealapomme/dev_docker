#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

root="$(cd "$(dirname "$0")/.." && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"
dest="$root/backups/$stamp"
mkdir -p "$dest"

docker exec gestion-interne-mariadb sh -c 'mariadb-dump -uwordpress --password="$(cat /run/secrets/mariadb_password)" --single-transaction --skip-lock-tables --default-character-set=utf8mb4 gestion' > "$dest/mariadb.sql"

docker exec gestion-interne-wordpress tar -C /var/www/html -cf - wp-content wp-config.php > "$dest/wordpress-files.tar"

printf '%s\n' "$dest"
