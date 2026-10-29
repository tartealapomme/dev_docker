#!/bin/sh
set -eu
pw=$(cat /run/secrets/db_password)
export DATABASE_URL="postgres://shop:${pw}@db:5432/shop"
exec "$@"
