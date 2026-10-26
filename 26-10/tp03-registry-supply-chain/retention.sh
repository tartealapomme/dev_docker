#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

KEEP="${1:-5}"
REG="${REGISTRY:-https://registry.local:5000}"
AUTH="${REGISTRY_AUTH:-ci:ci-push-2024}"
CURL="${CURL:-curl}"
ACCEPT="application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.index.v1+json"
curl_reg() {
  "$CURL" -fsk --resolve registry.local:5000:127.0.0.1 -u "$AUTH" "$@"
}

semver() {
  [[ "$1" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

repos="$(curl_reg "${REG}/v2/_catalog" | tr -d '\n' | sed -n 's/.*"repositories":\[\(.*\)\].*/\1/p' | tr ',' '\n' | tr -d '"[] ')"
if [[ -z "$repos" ]]; then
  printf 'aucun depot\n'
  exit 0
fi

for repo in $repos; do
  tags="$(curl_reg "${REG}/v2/${repo}/tags/list" | tr -d '\n' | sed -n 's/.*"tags":\[\(.*\)\].*/\1/p' | tr ',' '\n' | tr -d '" ')"
  [[ -n "$tags" ]] || continue
  rows=""
  for tag in $tags; do
    if semver "$tag"; then
      printf 'garde semver %s:%s\n' "$repo" "$tag"
      continue
    fi
    manifest="$(curl_reg -H "Accept: ${ACCEPT}" "${REG}/v2/${repo}/manifests/${tag}")"
    config="$(printf '%s' "$manifest" | sed -n 's/.*"config":{"mediaType":"[^"]*","size":[0-9]*,"digest":"\([^"]*\)".*/\1/p')"
    created="1970-01-01T00:00:00Z"
    if [[ -n "$config" ]]; then
      created="$(curl_reg "${REG}/v2/${repo}/blobs/${config}" | sed -n 's/.*"created":"\([^"]*\)".*/\1/p')"
      [[ -n "$created" ]] || created="1970-01-01T00:00:00Z"
    fi
    digest="$(curl_reg -sI -H "Accept: ${ACCEPT}" "${REG}/v2/${repo}/manifests/${tag}" | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')"
    rows+="${created} ${digest} ${tag}"$'\n'
  done
  [[ -n "$rows" ]] || continue
  mapfile -t ordered < <(printf '%s' "$rows" | sed '/^$/d' | sort -r)
  kept=0
  declare -A keep_digest=()
  for row in "${ordered[@]}"; do
    digest="${row#* }"
    digest="${digest%% *}"
    tag="${row##* }"
    if (( kept < KEEP )); then
      keep_digest["$digest"]=1
      printf 'garde recent %s:%s\n' "$repo" "$tag"
      kept=$((kept + 1))
    fi
  done
  for row in "${ordered[@]}"; do
    digest="${row#* }"
    digest="${digest%% *}"
    tag="${row##* }"
    if [[ -n "${keep_digest[$digest]:-}" ]]; then
      continue
    fi
    printf 'supprime %s:%s %s\n' "$repo" "$tag" "$digest"
    curl_reg -X DELETE -H "Accept: ${ACCEPT}" "${REG}/v2/${repo}/manifests/${digest}" >/dev/null
    keep_digest["$digest"]=1
  done
  unset keep_digest
done
