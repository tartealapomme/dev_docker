#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${1:?usage: release-gate.sh IMAGE [--push REGISTRY_IMAGE]}"
TARGET=""
if [[ "${2:-}" == "--push" ]]; then
  TARGET="${3:?usage: release-gate.sh IMAGE --push REGISTRY_IMAGE}"
fi

fail() {
  printf 'REFUSE: %s\n' "$*" >&2
  exit 1
}

labels="$(docker image inspect --format '{{json .Config.Labels}}' "$IMAGE")"
for key in org.opencontainers.image.version org.opencontainers.image.revision org.opencontainers.image.source; do
  printf '%s' "$labels" | grep -q "\"${key}\"" || fail "label absent: ${key}"
done

user="$(docker image inspect --format '{{.Config.User}}' "$IMAGE")"
case "$user" in
  ""|root|0|0:0) fail "utilisateur root" ;;
esac

health="$(docker image inspect --format '{{if .Config.Healthcheck}}{{len .Config.Healthcheck.Test}}{{else}}0{{end}}' "$IMAGE")"
[[ "$health" != "0" ]] || fail "HEALTHCHECK absent"

if ! docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.58.1 image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --quiet "$IMAGE"; then
  fail "CVE HIGH ou CRITICAL corrigible"
fi

if ! docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.58.1 image --scanners secret --exit-code 1 --quiet "$IMAGE"; then
  fail "secret detecte"
fi

if [[ -z "$TARGET" ]]; then
  printf 'OK: %s\n' "$IMAGE"
  exit 0
fi

docker tag "$IMAGE" "$TARGET"
docker push "$TARGET"
digest="$(docker image inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$TARGET" | awk -F@ '/host.docker.internal:5000\/shopapi@/ {print; exit}')"
[[ -n "$digest" ]] || digest="$TARGET"

sbom="${ROOT}/sbom.json"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft:v1.18.1 "$IMAGE" -o spdx-json > "$sbom"

export COSIGN_PASSWORD="${COSIGN_PASSWORD-}"
key="${ROOT}/cosign.key"
pub="${ROOT}/cosign.pub"
if [[ ! -f "$key" ]]; then
  docker run --rm -e COSIGN_PASSWORD -v "${ROOT}:/work" -w /work ghcr.io/sigstore/cosign/cosign:v2.4.3 generate-key-pair
fi

creds="${REGISTRY_AUTH:-ci:ci-push-2024}"
reg_user="${creds%%:*}"
reg_pass="${creds#*:}"
sign_flags=(
  --registry-username "$reg_user"
  --registry-password "$reg_pass"
  --registry-cacert /certs/ca.crt
  --tlog-upload=false
  --yes
)

docker run --rm \
  -e COSIGN_PASSWORD \
  -v "${ROOT}:/work" \
  -v "${ROOT}/starter/registry/certs:/certs:ro" \
  -w /work \
  ghcr.io/sigstore/cosign/cosign:v2.4.3 \
  sign --key /work/cosign.key "${sign_flags[@]}" "$digest"

docker run --rm \
  -e COSIGN_PASSWORD \
  -v "${ROOT}:/work" \
  -v "${ROOT}/starter/registry/certs:/certs:ro" \
  -w /work \
  ghcr.io/sigstore/cosign/cosign:v2.4.3 \
  attest --key /work/cosign.key --type spdxjson --predicate /work/sbom.json "${sign_flags[@]}" "$digest"

docker run --rm \
  -v "${ROOT}:/work" \
  -v "${ROOT}/starter/registry/certs:/certs:ro" \
  -w /work \
  ghcr.io/sigstore/cosign/cosign:v2.4.3 \
  verify --key /work/cosign.pub --insecure-ignore-tlog --registry-username "$reg_user" --registry-password "$reg_pass" --registry-cacert /certs/ca.crt "$digest"

printf 'PUBLIE: %s\n' "$TARGET"
