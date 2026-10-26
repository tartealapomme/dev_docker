# Exercice 1 — Orchestration avec Docker Compose

## Objectif

Déployer Nginx, WordPress et MariaDB avec un seul `compose.yaml`.

## Lancement

```powershell
cd 03_exercices_realises\tp-evaluation\exercice-01
.\run.ps1
```

WordPress : http://localhost:8095

## Points couverts

- Trois services : `nginx`, `wordpress`, `mariadb`
- Images épinglées : `nginx:1.27.5-alpine`, `wordpress:6.8.3-apache`, `mariadb:11.8.3`
- Redémarrage `unless-stopped` sur chaque service
- Paramètres configurables dans `.env`
- Nom de projet Compose : `gestion-interne`
- Démarrage en une commande : `docker compose up -d`

Nginx démarre avec le stack. L'accès navigateur passe par WordPress. Le reverse proxy est l'exercice 4.

L'énoncé complet est dans `TP-evaluation-niveau.md`.
