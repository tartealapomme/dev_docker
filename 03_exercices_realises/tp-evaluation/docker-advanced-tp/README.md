# Infrastructure WordPress

Projet unique. Les exercices s'ajoutent dans ce dossier.

## État

- Exercice 1 : Nginx, WordPress, MariaDB. Images épinglées, `restart: unless-stopped`, paramètres dans `.env`, projet Compose `gestion-interne`.
- Exercice 2 : trois réseaux.
- Exercice 3 : volumes nommés. Les données survivent à `docker compose down` puis `docker compose up -d`.

| Volume | Point de montage | Contenu |
|--------|------------------|---------|
| `gestion-interne-wordpress-data` | `/var/www/html` | Fichiers WordPress, thèmes, plugins, médias |
| `gestion-interne-mariadb-data` | `/var/lib/mysql` | Données MariaDB |

| Réseau | Conteneurs | Rôle |
|--------|------------|------|
| `gestion-interne-proxy` | Nginx | Point d'entrée isolé. |
| `gestion-interne-app` | Nginx, WordPress | Nginx joint WordPress. |
| `gestion-interne-data` | WordPress, MariaDB | WordPress joint la base. Nginx n'y a pas accès. |

MariaDB ne publie aucun port. Le port 3306 est fermé sur l'hôte.

## Lancement

```powershell
cd 03_exercices_realises\tp-evaluation\docker-advanced-tp
.\run.ps1
```

WordPress : http://localhost:8095

## Vérifications réseau

```powershell
docker port gestion-interne-mariadb
docker exec gestion-interne-wordpress php -r "exit((@new mysqli(getenv('WORDPRESS_DB_HOST'), getenv('WORDPRESS_DB_USER'), getenv('WORDPRESS_DB_PASSWORD'), getenv('WORDPRESS_DB_NAME')))->connect_errno ? 1 : 0);"
docker exec gestion-interne-nginx wget -q -O - --timeout=3 http://wordpress/
docker exec gestion-interne-nginx wget -q -O - --timeout=3 http://mariadb:3306/
```

Le dernier `wget` doit échouer : Nginx ne résout pas `mariadb`.

## Vérifications persistance

```powershell
docker volume ls --filter name=gestion-interne
docker inspect gestion-interne-wordpress --format "{{range .Mounts}}{{.Name}} -> {{.Destination}}{{println}}{{end}}"
docker inspect gestion-interne-mariadb --format "{{range .Mounts}}{{.Name}} -> {{.Destination}}{{println}}{{end}}"
```

Après création d'un article : `docker compose down`, puis `docker compose up -d`. L'article et les fichiers de `wp-content` sont toujours là. Ne pas utiliser `down -v`.
