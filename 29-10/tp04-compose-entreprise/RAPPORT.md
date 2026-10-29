# Rapport TP04

La critique du compose de départ est dans `CRITIQUE.md`. Le fichier de base est `compose.yml`, la surcharge dev est `compose.override.yml`, la prod est `compose.prod.yml`.

## Dev

`docker compose up -d --wait` : api, worker, db, redis et Traefik passent healthy. `smoke-test.sh` : `/ready` ok, second `GET /products` en `X-Cache: HIT`, commande `productId=1` `quantity=2` passée `confirmed`.

`MIGRATION=002-add-sku.sql docker compose --profile ops run --rm migrate` applique `ALTER TABLE` et `UPDATE 3`.

Le mot de passe n'est pas dans les fichiers versionnés. `scripts/with-database-url.sh` lit le secret et exporte `DATABASE_URL` avant `exec`, sans changer le code des apps.

PostgreSQL ne publie pas `5432` tant qu'il n'est que sur `shop_back` (`internal: true`). La surcharge dev ajoute le réseau `shop_debug`, non interne, pour que le port de debug soit réellement branché.

`node --watch` est le processus de l'API et le bind mount de `src` est visible dans le conteneur. Docker Desktop sur Windows ne remonte pas l'événement de modification : le process ne redémarre pas tout seul.

## Prod

Images tirées du registre du TP03 : `host.docker.internal:5000/shopapi:1.4.2` et `shop-worker:1.4.2`. Sans `REGISTRY`, Compose s'arrête sur `REGISTRY doit être défini`.

`build: !reset null` retire le build. `volumes: !reset` effaçait aussi le script qui construit `DATABASE_URL` : la prod utilise `volumes: !override` pour ne garder que ce script.

Traefik est en `v3.6`. `v3.1` ne parle pas à Docker Engine 29 (`Failed to retrieve information of the docker client and server host`).

Deux réplicas API healthy. Douze `GET /products` via `api.localhost` : 6 sur `api-1`, 6 sur `api-2` (logs applicatifs, pas d'id dans la réponse). Worker healthy. `LOG_LEVEL` du worker vaut `INFO` : le module `logging` de Python refuse `info`.

`docker compose -f compose.yml -f compose.prod.yml up -d --scale api=3` ajoute `shop-api-3`. Le `up -d` suivant, sans `--scale`, supprime ce conteneur et revient à `deploy.replicas: 2`.

En dev, le même `--scale api=3` échoue : `compose.override.yml` publie `3000:3000`, et un seul processus peut lier ce port de l'hôte.

## Réseau Adminer

Adminer (`--profile tools`) est sur `shop_front` et `shop_back`. Traefik le joint par `shop_front` (`traefik.docker.network=shop_front`). Adminer joint PostgreSQL par `shop_back`. `internal: true` ferme ce réseau vers l'extérieur, pas l'autre interface du conteneur.
