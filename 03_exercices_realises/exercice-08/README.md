# Exercice 08 — API Spring Boot CRUD (chiens) + MySQL

## Objectif

API Java Spring Boot conteneurisée avec CRUD sur l'entité `Dog`, connectée à MySQL (également conteneurisé).

## Endpoints

- `GET /api/v1/dogs`
- `GET /api/v1/dogs/{dogId}`
- `POST /api/v1/dogs`
- `PUT /api/v1/dogs/{dogId}`
- `DELETE /api/v1/dogs/{dogId}`

## Lancement

```powershell
.\run.ps1
```

API : http://localhost:8090  
MySQL : localhost:3308 (`dogs` / `dogspass` / `dogsdb`)

## Exemple

```json
{
  "name": "Rex",
  "birthDate": "2020-03-15",
  "breed": "Berger Allemand",
  "sterilized": true
}
```
