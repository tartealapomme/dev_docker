# Exercices Docker réalisés

Solutions des exercices du dossier `02_exercices_sujet`.

| Exercice | Contenu du dossier | Image / ressources Docker | Accès |
|----------|--------------------|---------------------------|-------|
| 01 | `run.ps1` + README | image `ubuntu-nginx` | image locale |
| 02 | `run.ps1` + README | `amigoscode/2048` | http://localhost:8080 |
| 03 | `Dockerfile`, `html/`, `run.ps1` | image `ex03-site` | http://localhost:8081 |
| 04 | `run.ps1` + README | image `ubuntu-ping`, réseau `ex04-net` | DNS interne |
| 05 | `compose.yaml`, `run.ps1` | MySQL + Adminer, volume `ex05-mysql-data` | http://localhost:8082 |
| 06 | `site/`, `run.ps1` | bind mount vers `site/` | http://localhost:8083 |
| 07 | `Dockerfile`, `init.sql`, `run.ps1` | image `kennel-mysql` | localhost:3307 |
| 08 | Spring Boot API + `compose.yaml` | `ex08-dogs-api` + MySQL | http://localhost:8090 |
| 09 | CRUD API + Logs API + compose | `ex09-crud-api`, `ex09-logs-api` + MySQL | http://localhost:8091 / 8092 |
| 10 | Notes app + `.env` + `docker-compose.yml` | `ex10-notes-app` + PostgreSQL + volumes | http://localhost:8080 |

## Relancer un exercice

```powershell
cd 03_exercices_realises\exercice-0X
.\run.ps1
```

## Note sur les images

Les images Docker vivent dans le daemon Docker local (`docker images`), pas en fichiers dans le dossier.
Les dossiers contiennent tout le nécessaire pour les reconstruire / relancer via les scripts.
