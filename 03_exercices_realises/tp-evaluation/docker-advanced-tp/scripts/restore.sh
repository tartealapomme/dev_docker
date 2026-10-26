#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

if [ "$#" -ne 1 ]; then
  printf 'usage: %s backups/<horodatage>\n' "$0" >&2
  exit 1
fi

src="$(cd "$1" && pwd)"

docker exec -i gestion-interne-mariadb sh -c 'mariadb -uwordpress --password="$(cat /run/secrets/mariadb_password)" gestion' < "$src/mariadb.sql"

docker exec -i gestion-interne-wordpress tar -C /var/www/html --touch --no-same-owner --no-same-permissions --overwrite -xf - < "$src/wordpress-files.tar"

printf 'restaure: %s\n' "$src"
