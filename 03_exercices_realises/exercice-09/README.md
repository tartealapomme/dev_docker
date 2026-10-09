# Exercice 09 — API CRUD + API Logs (Spring Boot)

## Objectif

Deux APIs Java conteneurisées :
- **CRUD API** : gestion des chiens + envoi de logs via `RestTemplate`
- **Logs API** : stockage / consultation des logs (H2 fichier)
- **MySQL** : base de données du CRUD

## Endpoints

### Logs
- `GET /api/v1/logs`
- `POST /api/v1/logs`

### CRUD
- `GET /api/v1/dogs`
- `GET /api/v1/dogs/{dogId}`
- `POST /api/v1/dogs`
- `PUT /api/v1/dogs/{dogId}`
- `DELETE /api/v1/dogs/{dogId}`

## Lancement

```powershell
.\run.ps1
```

| Service | URL / port |
|---------|------------|
| CRUD API | http://localhost:8091 |
| Logs API | http://localhost:8092 |
| MySQL | localhost:3309 |
