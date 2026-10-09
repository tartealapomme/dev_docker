# Exercices Docker réalisés

Solutions et déploiements des 6 exercices du dossier `02_exercices_sujet`.

| Exercice | Contenu du dossier | Image / ressources Docker | Accès |
|----------|--------------------|---------------------------|-------|
| 01 | `run.ps1` + README | image `ubuntu-nginx` | image locale |
| 02 | `run.ps1` + README | `amigoscode/2048` | http://localhost:8080 |
| 03 | `Dockerfile`, `html/`, `run.ps1` | image `ex03-site` | http://localhost:8081 |
| 04 | `run.ps1` + README | image `ubuntu-ping`, réseau `ex04-net` | DNS interne |
| 05 | `compose.yaml`, `run.ps1` | MySQL + Adminer, volume `ex05-mysql-data` | http://localhost:8082 |
| 06 | `site/`, `run.ps1` | bind mount vers `site/` | http://localhost:8083 |

## Relancer un exercice

```powershell
cd 03_exercices_realises\exercice-0X
.\run.ps1
```

## Note sur les images

Les images Docker vivent dans le daemon Docker local (`docker images`), pas en fichiers dans le dossier.
Les dossiers contiennent tout le nécessaire pour les reconstruire / relancer via les scripts.
