# Exercice 10 — Docker Compose : variables d'environnement et volumes

## Objectif

Conteneuriser l'application Spring Boot Notes avec :
- un fichier `.env` pour la configuration
- un `docker-compose.yml` (app + PostgreSQL)
- des volumes pour persister la BDD (`pg_data`) et les uploads (`uploads`)

## Lancement

```powershell
.\run.ps1
```

Ou manuellement :

```powershell
docker compose up -d --build
```

## Endpoints utiles

| URL | Description |
|-----|-------------|
| http://localhost:8080/api/info/env | Variables d'environnement injectées |
| http://localhost:8080/api/info/app | Infos application |
| http://localhost:8080/api/info/health | Santé app + BDD |
| http://localhost:8080/api/notes | CRUD notes |

## Tests de validation

### Persistance (volumes conservés)

```powershell
docker compose stop
docker compose start
```

### Perte des données (volumes supprimés)

```powershell
docker compose down -v
docker compose up -d
```

### Modifier une variable

1. Changer `APP_NAME` dans `.env`
2. `docker compose up -d --force-recreate app`
3. Vérifier `http://localhost:8080/api/info/env`
