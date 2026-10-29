# Critique du compose de départ

Fichier : `starter/docker-compose.yml`.

1. `version: '3'` est obsolète. Compose l'ignore et le fichier n'utilise pas les champs utiles du spec actuel (`name`, secrets, `!reset`).
2. `links` est obsolète. La découverte se fait par le nom de service sur un réseau déclaré.
3. `postgres` et `redis` ne sont pas épinglés. Un pull ultérieur peut changer le majeur.
4. Les ports 5432 et 6379 sont publiés. La base et Redis sont joignables depuis la machine, et donc depuis n'importe quel processus local.
5. Le mot de passe `postgres` est en clair dans `POSTGRES_PASSWORD` et dans `DATABASE_URL`, donc dans Git.
6. L'API démarre avec `sleep 10`. Ce n'est ni un signal de santé ni un ordre fiable : trop court si la base est lente, inutilement long sinon.
7. Aucun `healthcheck`. `depends_on` ne pourrait attendre que le démarrage du processus, pas une base prête à accepter des connexions.
8. Pas de volume nommé. Recréer `db` ou `redis` efface les données.
9. Un seul réseau implicite. Le proxy, l'API, le worker, la base et Redis se voient tous.
10. `restart` est incohérent : `always` sur le worker seulement. Les autres services ne reviennent pas après un reboot du démon.
11. Aucune limite CPU ou mémoire, aucune rotation des logs.
12. Pas de reverse proxy. L'API est publiée directement, sans host virtuel ni contrôle d'exposition.
