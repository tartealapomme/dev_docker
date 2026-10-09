# Exercice 04 — Communication entre deux conteneurs

## Objectif

Faire communiquer deux conteneurs via un réseau Docker et la résolution DNS (ping par nom).

## Commandes réalisées

```bash
docker network create ex04-net

docker run -d --name ex04-a --network ex04-net ubuntu:24.04 sleep infinity
docker exec ex04-a bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iputils-ping"
docker commit ex04-a ubuntu-ping

docker run -d --name ex04-b --network ex04-net ubuntu-ping sleep infinity

docker exec ex04-a ping -c 3 ex04-b
docker exec ex04-b ping -c 3 ex04-a
```

## Résultat

Les deux conteneurs se joignent mutuellement via leur nom (`ex04-a` / `ex04-b`) grâce au DNS interne Docker.
