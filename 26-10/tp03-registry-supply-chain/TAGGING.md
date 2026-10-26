# Politique de tags Shop SAS

## Tags

| Tag | Rôle | Mutabilité |
|--|--|--|
| `1.2.3` | version publiée, semver | immuable |
| `1.2.3-sha-<git>` | build exact de cette version | immuable |
| `sha-<git>` | build de CI, hors semver | écrasable, rétention des 5 plus récents |
| `latest` | interdit en production | — |

Une release semver n'est jamais réécrite. Un tag de CI peut être repris par `retention.sh`, qui conserve les tags semver et les N tags non semver les plus récents.

## Pourquoi `latest` est interdit

`latest` ne désigne pas un contenu. Il a été réécrit un vendredi et a cassé la production : le manifeste derrière le tag a changé sans que le manifeste de déploiement change. On ne peut ni auditer ni rejouer ce qui tournait.

## Référencer un digest

Le digest désigne les octets du manifeste. Un retag ne le change pas. Une signature Cosign est attachée au digest, pas au nom du tag.

```yaml
services:
  api:
    image: registry.local:5000/shopapi@sha256:78d25851d50903da54680254550f2b6cb54d2a9cc1d0efd4c8d19af538128dc3
```

Retag sans pull, depuis un conteneur :

```bash
docker run --rm quay.io/skopeo/stable:v1.16.1 copy \
  --src-tls-verify=false --dest-tls-verify=false \
  --src-creds ci:ci-push-2024 --dest-creds ci:ci-push-2024 \
  docker://host.docker.internal:5000/shopapi:1.4.2 \
  docker://host.docker.internal:5000/shopapi:1.4.2-release
```

## htpasswd

Les comptes `ci` et `dev` authentifient le registre. `htpasswd` ne distingue pas le push du pull : les deux comptes peuvent pousser. En entreprise on passe à Harbor, Nexus, Artifactory ou un registre cloud (ECR, ACR, GAR) pour le RBAC, le scan intégré, la réplication, les quotas et l'immutabilité des tags.
