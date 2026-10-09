# Exercice 05 — MySQL et Adminer

## Objectif

Déployer MySQL + Adminer sur un réseau Docker, avec persistance des données et redémarrage automatique.

## Accès Adminer

- URL : [http://localhost:8082](http://localhost:8082)
- Système : MySQL
- Serveur : `ex05-mysql` (nom du conteneur, pas d'IP)
- Utilisateur : `ynov`
- Mot de passe : `ynovpass`
- Base : `exercice05`

## Déploiement manuel

```bash
docker network create ex05-net
docker volume create ex05-mysql-data

docker run -d --name ex05-mysql \
  --network ex05-net \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=exercice05 \
  -e MYSQL_USER=ynov \
  -e MYSQL_PASSWORD=ynovpass \
  -v ex05-mysql-data:/var/lib/mysql \
  mysql:8.0

docker run -d --name ex05-adminer \
  --network ex05-net \
  --restart unless-stopped \
  -p 8082:8080 \
  adminer:latest
```

## Données de test

```sql
CREATE TABLE etudiants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL
);

INSERT INTO etudiants (nom, prenom) VALUES
  ('Dupont', 'Alice'),
  ('Martin', 'Bob'),
  ('Bernard', 'Claire');
```

## Vérifications effectuées

1. Insertion de 3 enregistrements
2. Suppression puis recréation du conteneur MySQL → données conservées via le volume
3. Politique `--restart unless-stopped` pour redémarrage automatique

## Bonus — Docker Compose

```bash
cd 03_exercices_realises/exercice-05
docker compose up -d
```

Le fichier `compose.yaml` démarre MySQL + Adminer avec volume, réseau, healthcheck et restart.
