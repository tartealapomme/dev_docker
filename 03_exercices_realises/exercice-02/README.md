# Exercice 02 — Déploiement du jeu 2048

## Objectif

Déployer le jeu 2048 depuis Docker Hub, accessible sur `http://localhost:8080`.

## Image utilisée

`amigoscode/2048` (compatible avec Docker moderne).

> Note : certaines images historiques (`alexwhen/docker-2048`) utilisent un ancien format de manifeste non supporté par containerd v2+.

## Commandes réalisées

```bash
docker pull amigoscode/2048
docker run -d --name ex02-2048 -p 8080:80 amigoscode/2048
```

## Vérification

Ouvrir [http://localhost:8080](http://localhost:8080) dans le navigateur.
