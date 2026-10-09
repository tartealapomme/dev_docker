# Exercice 06 — Conteneur de développement NGINX (volume)

## Objectif

Servir un site web local via NGINX dans Docker, sans installer NGINX sur l'hôte, grâce à un bind mount (`-v`).

## Structure

```
exercice-06/
├── site/
│   └── index.html
└── README.md
```

## Commande réalisée

```bash
docker run -d --name ex06-nginx \
  -p 8083:80 \
  -v "$(pwd)/03_exercices_realises/exercice-06/site:/usr/share/nginx/html:ro" \
  nginx:alpine
```

Sous Windows (PowerShell) :

```powershell
$sitePath = (Resolve-Path "03_exercices_realises\exercice-06\site").Path
docker run -d --name ex06-nginx -p 8083:80 -v "${sitePath}:/usr/share/nginx/html:ro" nginx:alpine
```

## Vérification

1. Ouvrir [http://localhost:8083](http://localhost:8083)
2. Modifier `site/index.html` localement
3. Recharger le navigateur → les changements apparaissent immédiatement
