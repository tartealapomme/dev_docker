# TP05 — Réponses

Les essais destructifs sont sur une copie (`compose.yml`, projet `shoplab`), pas sur `shop_pgdata`. La stack du TP04 est restée démarrée pour l'inspection. Transcripts : `transcripts/`.

## 1. Anatomie

`shop-db-1` monte le volume nommé `shop_pgdata` sur `/var/lib/postgresql/data`. Point de montage dans la VM : `/var/lib/docker/volumes/shop_pgdata/_data`. Le secret et `db/init.sql` sont des bind mounts.

La couche inscriptible du conteneur est le snapshot overlayfs (`docker info` : `Driver=overlayfs`). Avec le snapshotter containerd, `GraphDriver.Data.UpperDir` n'est pas exposé. `docker diff` la montre quand même.

Sur la copie, `touch /tmp/x` apparaît dans `docker diff` (`A /tmp/x`). `touch /var/lib/postgresql/data/volume-proof` n'y apparaît pas : ce fichier est dans le volume, pas dans la couche du conteneur. En prod, `/tmp` est un `tmpfs` : le `touch` n'est pas une écriture de couche.

| Commande | `shoplab_pgdata` | Données |
|---|---|---|
| `down` | conservé | la ligne `marker` est toujours là au `up` suivant |
| `stop` puis `rm -f` | conservé | la ligne est toujours là |
| `down -v` | supprimé | base vide au `up` suivant |
| `volume prune` | conservé | Docker 29 ne supprime pas les volumes nommés |
| `volume prune --all` filtré sur le projet | supprimé | 47,79 Mo récupérés sur `shopinit_pgdata` |

Volume anonyme : `docker run` sans `-v` crée un volume dont le nom est un hash (`101b543e2602…`) monté sur `/var/lib/postgresql/data`. `docker rm -f` laisse ce volume. `docker rm -fv` le supprime. Piège : rien ne porte le nom du projet, un `volume prune` (sans `--all`, car il est anonyme) efface la seule copie.

| Type | Usage | Docker Desktop |
|---|---|---|
| Bind mount | code, config, init SQL | les fichiers sont sur le disque Windows, partagés avec la VM. Beaucoup de petites écritures (Postgres, `node_modules`) sont lentes |
| Volume nommé | données Postgres et Redis | fichiers sur le disque de la VM, performances natives |
| `tmpfs` | `/tmp`, socket Postgres | en RAM, perdu à l'arrêt du conteneur |

`db/init.sql` n'est rejoué que si le répertoire de données est vide. L'entrypoint voit déjà `PG_VERSION` et saute `docker-entrypoint-initdb.d`. Preuve sur `shopinit` : après un insert manuel, le restart garde les deux lignes (`init` et `manuel`). Après `down -v` puis `up`, seule la ligne `init` revient. Forcer la réinitialisation : `down -v`, ou vider le volume.

## 2. Sauvegarde

`backup.sh` écrit un `pg_dump -Fc` horodaté et une archive `tar` du volume, et ne garde que les 7 derniers de chaque.

Le `tar` pris pendant que Postgres écrit peut couper une page en deux : la sauvegarde brute est alors incohérente. `./backup.sh --consistent` arrête `db` le temps du `tar`. L'autre méthode en ligne est `pg_backup_start` / `pg_backup_stop`, en conservant les WAL produits pendant la copie. Le dump logique est déjà cohérent : il lit un snapshot.

Preuve, copie `shoplab`, 100 000 commandes :

- avant : `100000 62f14890436e56a6a0ce4157a1f05a3c`
- `down -v`, volume absent
- `restore.sh` sur `shop-20261029T133136Z.dump`
- après : `100000 62f14890436e56a6a0ce4157a1f05a3c`

Le seed du sujet crée `orders.created_at`. La table `orders` du TP04 n'a pas cette colonne, donc la preuve est sur la copie, pas sur la base du TP04.

Sidecar : `compose.backup.yml` (`prodrigestivill/postgres-backup-local:16-alpine`, `SCHEDULE=@every 1m`). Au démarrage, `/backups/last/shop-20261029-133232.sql.gz` est apparu, ainsi que les copies daily, weekly et monthly. Pour le brancher sur le TP04 :

```bash
docker compose -f ../tp04-compose-entreprise/compose.yml -f compose.backup.yml up -d dbbackup
```

## 3. Montée de version

Changer le tag `14.13` pour `16.4` sur le même volume échoue. Le serveur 16 refuse le catalogue 14 :

```text
FATAL: database files are incompatible with server
DETAIL: The data directory was initialized by PostgreSQL version 14, which is not compatible with this version 16.4.
```

`pg_dump` exporte une base, sans les rôles. `pg_dumpall` exporte toutes les bases et les objets globaux (rôles). Le script garde les deux. La restauration utilise `pg_restore` du dump `-Fc` : rejouer `pg_dumpall` tenterait de recréer le rôle `shop`, déjà créé par l'image.

Le nouveau volume évite d'écraser la seule copie avant d'avoir prouvé le serveur 16. Retour arrière : arrêter le 16, relancer `starter/compose.yml`. Le volume `shopdata_pgdata` n'a pas été modifié.

Checksums : avant, après `pg_restore`, et après retour sur PostgreSQL 14 : `100000 f8dac2c781bd112e561b2c28439942e2`.

Le dump/restore copie toutes les lignes : l'indisponibilité dure toute la copie. Pour la réduire : réplication logique vers un PostgreSQL 16, puis bascule courte ; ou `pg_upgrade --link`, qui réécrit le catalogue et lie les fichiers, en quelques minutes, avec les deux binaires dans le même conteneur (`tianon/postgres-upgrade`). `--link` rend l'ancien catalogue inutilisable : on garde le volume 14 tant que le 16 n'est pas accepté, ce que fait déjà `upgrade-pg.sh`.

## 4. Redis

`--save 60 1` écrit un RDB si au moins une clé a changé en 60 secondes. Perte maximale : 60 secondes d'écritures. `--appendonly yes` active l'AOF. Le défaut `appendfsync everysec` perd environ une seconde.

Dans cette stack, Redis tient le cache `products` (expiration 30 secondes, reconstruit depuis Postgres) et la file `orders:queue`. La file est la seule copie d'une commande tant que le worker ne l'a pas écrite dans Postgres. L'AOF est justifié par la file. Le cache, seul, n'a pas besoin de persistance. Le compose du TP04 lance déjà `redis-server --appendonly yes`.
