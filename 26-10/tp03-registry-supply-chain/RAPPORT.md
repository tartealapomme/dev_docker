# Rapport TP03

Registre dans `starter/registry`. Comptes : `ci` / `ci-push-2024` (push) et `dev` / `dev-pull-2024` (prévu pour le pull). Sur cette machine Windows, le fichier hosts n'est pas modifiable : Docker parle à `host.docker.internal:5000`. Le certificat couvre aussi `registry.local`. `curl` utilise `--resolve registry.local:5000:127.0.0.1`.

## Registre

- Anonyme : `GET /v2/` répond 401.
- `dev` : catalogue 200.
- `shopapi:1.4.2` poussé. Digest `sha256:78d25851d50903da54680254550f2b6cb54d2a9cc1d0efd4c8d19af538128dc3`.
- UI : http://localhost:5080
- Mirror : `daemon.json` contient `http://127.0.0.1:5001`. Les deux `docker pull alpine:3.20` apparaissent dans les logs du mirror. Le premier contacte Docker Hub, le second est servi plus vite depuis le cache (HEAD 200, 324 ms).

`htpasswd` ne sépare pas push et pull : `dev` authentifié peut aussi pousser. Harbor, Nexus, Artifactory, ECR, ACR ou GAR ajoutent le RBAC, le scan, la réplication, les quotas et l'immutabilité des tags.

## API et rétention

`HEAD /v2/shopapi/manifests/1.4.2` avec les `Accept` OCI renvoie `Docker-Content-Digest`.

`retention.sh 1` garde le semver `shopapi:1.4.2`, garde le tag récent non semver, et supprime `scratch:new`. `scratch:old` et `scratch:same` partagent le même digest : le script ne supprime pas ce digest, sinon les deux tags disparaîtraient. Supprimer un manifeste par digest retire tous les tags qui le pointent. Le garbage-collect a ensuite effacé les blobs de `scratch:new` (3 blobs).

## Signature

SBOM SPDX : 134 paquets. Trivy sur `shopapi:legacy` retrouve la clé AWS dans `/app/.env`.

`release-gate.sh shopapi:legacy` refuse (label `revision` absent). `release-gate.sh shopapi:1.4.2 --push ...` accepte, pousse, signe et atteste. Le registre contient les tags `sha256-78d25851....sig` et `.att`.

La signature est liée au digest, pas au tag. Retaguer `1.4.2` vers `1.4.2-release` avec skopeo ne crée pas de nouvelle signature : les deux tags pointent le même manifeste signé. Republier des octets différents sous `1.4.2` change le digest : l'ancienne signature ne vérifie plus ce tag.

Cosign est lancé avec `--tlog-upload=false` et `verify --insecure-ignore-tlog`, parce que Rekor n'est pas joignable depuis cette machine. En entreprise, la publication dans le journal de transparence permet à un tiers de vérifier la signature sans la clé publique locale.
