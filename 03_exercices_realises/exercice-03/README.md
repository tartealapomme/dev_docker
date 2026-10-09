# Exercice 03 — Site web customisé avec NGINX

## Objectif

Servir une page d'accueil personnalisée via NGINX dans Docker.

## Structure

```
exercice-03/
├── Dockerfile
├── html/
│   └── index.html
└── README.md
```

## Commandes réalisées

```bash
docker build -t ex03-site ./03_exercices_realises/exercice-03
docker run -d --name ex03-nginx -p 8081:80 ex03-site
```

## Vérification

Ouvrir [http://localhost:8081](http://localhost:8081) — page « Exercice 03 / Hello World ».
