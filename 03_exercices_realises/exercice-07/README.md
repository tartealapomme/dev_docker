# Exercice 07 — Image MySQL pré-initialisée (kennelDB)

## Objectif

Construire une image MySQL personnalisée qui initialise `kennelDB` (clients, adresses, associations, chiens, chats) au premier démarrage via un script SQL.

## Contenu

- `Dockerfile` — image basée sur `mysql:8.0`
- `init.sql` — schéma + données
- `run.ps1` — build + lancement

## Lancement

```powershell
.\run.ps1
```

Connexion : `localhost:3307` / user `root` / password `rootpass` / base `kennelDB`
