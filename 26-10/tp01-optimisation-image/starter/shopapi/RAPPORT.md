# Rapport shopapi 1.4.2

Le Dockerfile d'origine est conservé dans `Dockerfile.legacy`. Le code applicatif n'est pas modifié.

| | Avant (`shopapi:legacy`) | Après (`shopapi:1.4.2`) |
|--|--|--|
| Taille | 1,09 Go | 188 Mo (`docker image inspect` : 187666801 octets) |
| Couches RootFS | 9 | 10 |
| Rebuild après changement de `src/server.js` | `npm install` rejoué, 12,4 s | `npm install` en `CACHED`. Seuls les tests et la copie de `src` sont rejoués |
| Utilisateur | `uid=0(root)` | `uid=1000(node)` |
| Arrêt `docker stop` | 3908 ms | 515 ms |

`/app` ne contient plus que `node_modules`, `package.json` et `src`. Pas de `.env`, pas de `*.sql`.

Les labels OCI portent `org.opencontainers.image.version=1.4.2` et `org.opencontainers.image.revision` égal au `GIT_SHA` passé en `ARG`.

`docker build --target test` exécute `npm test` et `npm run lint` (1 test OK, `lint ok`). L'image finale ne contient pas les devDependencies (114 paquets au lieu de 222).

L'image `node:20-alpine` plus l'application pesait 211 Mo : elle embarque npm, yarn et les en-têtes. Le stage final part d'`alpine:3.23.4` (même musl que `node:20-alpine`) et n'y copie que le binaire Node 20, `libstdc++` et `libgcc`. Les stages `deps` et `test` restent sur `node:20-alpine`. Le stage final met à jour `libssl3` et `libcrypto3` en `3.5.9-r0` pour ne plus avoir de CVE HIGH corrigible.

`CMD ["node", "src/server.js"]` est en forme exec : Node est PID 1 et reçoit `SIGTERM`. Le `server.js` ferme le serveur HTTP dans `shutdown`. D'où un arrêt sous la seconde, contre plusieurs secondes quand PID 1 était le shell de `npm start`.

Santé : après 6 s, `docker inspect` donne `healthy`. `GET /products` renvoie les trois produits.

## Hadolint

Sortie vide, code de sortie 0.
