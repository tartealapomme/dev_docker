#!/usr/bin/env bash
set -euo pipefail
base="${BASE_URL:-http://api.localhost}"
headers=$(mktemp)
body=$(mktemp)
trap 'rm -f "$headers" "$body"' EXIT

curl -fsS "$base/ready"
printf '\n'

curl -fsS -D "$headers" -o "$body" "$base/products"
curl -fsS -D "$headers" -o "$body" "$base/products"
cache=$(tr -d '\r' < "$headers" | awk 'tolower($1)=="x-cache:" {print $2}')
test "$cache" = "HIT"

curl -fsS -X POST "$base/orders" -H "content-type: application/json" -d "{\"productId\":1,\"quantity\":2}"
printf '\n'

for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  status=$(docker compose exec -T db sh -c 'psql "postgresql://shop:$(cat /run/secrets/db_password)@127.0.0.1:5432/shop" -tAc "SELECT status FROM orders WHERE product_id=1 AND quantity=2 ORDER BY id DESC LIMIT 1"')
  status=$(printf '%s' "$status" | tr -d '[:space:]')
  if [ "$status" = "confirmed" ]; then
    printf 'confirmed\n'
    exit 0
  fi
  sleep 1
done

printf 'commande non confirmee\n' >&2
exit 1
