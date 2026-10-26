# Diagnostic shopapi:legacy

Image construite avec `Dockerfile.legacy` (`docker build -t shopapi:legacy .`).

## Taille et performance

1. **Image de 1,09 Go.** `docker image ls shopapi:legacy` affiche `1.09GB`. Le registre se remplit pour une API Node.
2. **`apt-get update` dans sa propre couche (81,4 Mo), listes non supprimées.** `docker history` : `81.4MB RUN apt-get update`. Hadolint DL3009.
3. **Outils de compilation inutiles en production (393 Mo).** `docker history` : `393MB RUN apt-get install -y curl wget vim git build-essential python3`.
4. **Node.js installé par-dessus Ubuntu (173 Mo) au lieu d'une image officielle.** `docker history` : `173MB RUN apt-get install -y nodejs`.
5. **`nodemon` global (7,54 Mo) alors que le process de prod est `node`.** `docker history` : `7.54MB RUN npm install -g nodemon`.
6. **`npm install` réinstallé après un changement de source.** `COPY . /app` est avant `RUN npm install`. Après `echo` dans `src/server.js`, le rebuild rejoue `RUN npm install` (12,4 s, non `CACHED`). Les couches apt restent en cache.

Ordre de couches qui évite ça : image de base, `package.json`, `npm install`, puis seulement le code source.

## Sécurité

7. **Processus root.** `docker run --rm shopapi:legacy id` → `uid=0(root)`.
8. **Secret dans la configuration d'image.** `docker history` contient `ENV DATABASE_URL=postgres://shop:S3cret!@db.internal:5432/shop`. `docker run --rm shopapi:legacy env` le réaffiche.
9. **`.env` et dump SQL copiés dans l'image.** `docker run --rm shopapi:legacy ls -la /app` montre `.env` et `dump-prod-2024.sql`. Le `.env` contient un mot de passe de base et une clé AWS.
10. **Dépendances de dev dans l'image finale.** `npm install` sans `--omit=dev` installe 222 paquets, dont `eslint` et `nodemon`. `NODE_ENV=development`.

## Exploitabilité

11. **Pas d'arrêt propre.** `CMD npm start` est en forme shell (hadolint DL3025, avertissement BuildKit `JSONArgsRecommended`). `docker stop` a pris **3908 ms** : le signal n'atteint pas Node directement.
12. **Pas de `HEALTHCHECK`.** Un conteneur démarré n'est pas distingué d'une API qui répond.
13. **`git` et un compilateur dans l'image de prod.** Un processus compromis peut modifier le système et cloner du code. Hadolint sur le Dockerfile d'origine remonte aussi DL3008, DL3016 et DL4006.

## Hadolint (Dockerfile d'origine)

```
DL3008 warning: Pin versions in apt get install
DL3009 info: Delete the apt lists
DL3015 info: --no-install-recommends
DL3016 warning: Pin versions in npm
DL3025 warning: Use arguments JSON notation for CMD
DL3059 info: Multiple consecutive RUN
DL4006 warning: Set the SHELL option -o pipefail
```
