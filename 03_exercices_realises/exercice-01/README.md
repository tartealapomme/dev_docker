# Exercice 01 — Image Ubuntu + NGINX

## Objectif

Créer une image `ubuntu-nginx` en installant NGINX dans un conteneur Ubuntu, puis en sauvegardant l'état avec `docker commit`.

## Commandes réalisées

```bash
docker pull ubuntu:24.04
docker run -d --name ex01-ubuntu ubuntu:24.04 sleep infinity
docker exec -it ex01-ubuntu bash
```

Dans le conteneur :

```bash
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
nginx -v
exit
```

Sauvegarde de l'image :

```bash
docker commit ex01-ubuntu ubuntu-nginx
docker images ubuntu-nginx
docker stop ex01-ubuntu
docker rm ex01-ubuntu
```

## Résultat

Image créée : `ubuntu-nginx:latest`
