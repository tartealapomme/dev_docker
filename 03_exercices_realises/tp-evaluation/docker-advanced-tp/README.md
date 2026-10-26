# Infrastructure WordPress

Projet unique. Les exercices s'ajoutent dans ce dossier.

## État

- Exercice 1 : Nginx, WordPress, MariaDB. Images épinglées, `restart: unless-stopped`, paramètres dans `.env`, projet Compose `gestion-interne`.
- Exercice 2 : trois réseaux.
- Exercice 3 : volumes nommés. Les données survivent à `docker compose down` puis `docker compose up -d`.
- Exercice 4 : Nginx est le seul point d'entrée. Configuration dans `nginx/default.conf`. WordPress n'a aucun port publié.
- Exercice 5 : healthchecks. WordPress attend MariaDB `healthy`, Nginx attend WordPress `healthy`.
- Exercice 6 : mots de passe dans des secrets Compose (`secrets/*.txt`, ignorés par Git). Le Compose ne contient que les chemins `*_FILE`. Modèle : `.env.example`.
- Exercice 7 : durcissement. Nginx tourne avec l'uid `101`, système de fichiers en lecture seule, toutes les capacités retirées. WordPress et MariaDB ont un filesystem en lecture seule hors volumes, des capacités réduites, et des limites mémoire / CPU. Aucun conteneur n'est `privileged`.
- Exercice 8 : `scripts/backup.sh` écrit un dump logique MariaDB et une archive `wp-content` + `wp-config.php` dans `backups/<horodatage>/`. Ce dossier est ignoré par Git.

## Sauvegarde et restauration

```bash
bash scripts/backup.sh
bash scripts/restore.sh backups/20261026-122600
```

La restauration réinjecte le dump dans la base `gestion`, puis réécrit les fichiers applicatifs dans `/var/www/html`. Une donnée supprimée après la sauvegarde réapparaît. Les sauvegardes restent sur la machine hôte, hors du dépôt.

| Service | Utilisateur | Lecture seule | Capacités | Limites | Exception |
|---------|-------------|---------------|-----------|---------|-----------|
| Nginx | `101` (nginx) | Oui, tmpfs sur `/tmp` et le cache | `cap_drop: ALL` | 128 Mo, 0,5 CPU | Écoute `8080` dans le conteneur : un processus non root ne peut pas lier le port 80. |
| WordPress | root au démarrage, workers `www-data` | Oui, sauf le volume `/var/www/html` | `ALL` retirées, puis `NET_BIND_SERVICE`, `SETUID`, `SETGID`, `CHOWN`, `DAC_OVERRIDE` | 512 Mo, 1 CPU | L'image officielle lance Apache en root pour le port 80 puis abandonne les privilèges. Le volume reste inscriptible pour les médias. |
| MariaDB | root au démarrage, serveur `mysql` | Oui, sauf le volume `/var/lib/mysql` | `ALL` retirées, puis `SETUID`, `SETGID`, `CHOWN`, `DAC_OVERRIDE`, `FOWNER` | 512 Mo, 1 CPU | L'entrypoint utilise ces capacités pour passer à l'utilisateur `mysql` et préparer le datadir. |

Ces mesures réduisent la surface en cas de compromission : pas de mode privilégié sur l'hôte, peu de capacités noyau, pas d'écriture sur le système de fichiers de l'image, et pas de saturation CPU ou mémoire. `no-new-privileges` empêche un binaire de regagner des droits.

Un conteneur `Up` a seulement son processus principal lancé. Il est opérationnel quand le healthcheck passe : MariaDB accepte une connexion et InnoDB est prêt, WordPress répond HTTP 200, Nginx sert le site. `depends_on: condition: service_healthy` n'agit qu'au démarrage.

Après `docker stop` sur MariaDB, WordPress reste `running` et http://localhost:8080 répond déjà 500, alors que le healthcheck affiche encore `healthy` pendant quelques intervalles. Il passe ensuite `unhealthy`. Après `docker start`, la page revient avant que les healthchecks ne repassent tous `healthy`. Le statut Docker suit donc l'état réel avec un délai.

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

Application : http://localhost:8080

WordPress n'est pas joignable directement depuis l'hôte. Nginx transmet `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto` et `X-Forwarded-Host`, et joint le service `wordpress`.

```powershell
docker port gestion-interne-wordpress
docker port gestion-interne-nginx
```

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
