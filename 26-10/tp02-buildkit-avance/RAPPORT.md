# Rapport TP02 — shop-worker

Dockerfile final : `starter/shop-worker/Dockerfile`. L'original est `Dockerfile.legacy`. `pip.conf` (index public) est ignoré par Git. L'exemple du sujet, avec un identifiant, reste `pip.conf.example`.

## 1. Fuite par `ARG`

Le Dockerfile d'origine déclare `ARG PIP_INDEX_URL` avec un identifiant dans la valeur par défaut, puis `COPY . .` et `RUN pip install`. BuildKit exporte cet `ARG` comme variable d'environnement des `RUN` suivants. Le secret est alors visible à trois endroits :

- `docker history --no-trunc` : la valeur résolue est dans les métadonnées de la couche qui a exécuté `pip` ;
- `docker inspect` : elle apparaît dans l'environnement de cette couche, et le `Dockerfile` copié par `COPY . .` la contient aussi sur le disque de l'image ;
- la couche intermédiaire : le cache pip et les fichiers écrits pendant le `RUN` gardent l'URL, même si une couche suivante supprime le fichier.

L'image `worker:1.0` construite avec `--secret` ne les a plus. `docker history` ne contient pas d'URL d'index. `docker run --rm worker:1.0 cat /etc/pip.conf` renvoie `No such file`. `Config.Env` ne contient pas `PIP_INDEX_URL`.

Alternatives : `--mount=type=ssh` pour un `pip install git+ssh://...` sans clé dans l'image ; `--secret id=TOKEN,env=TOKEN` quand l'outil lit un jeton dans l'environnement plutôt qu'un fichier. Le secret n'est monté que le temps du `RUN`.

## 2. Cache

| Build | Résultat |
|--|--|
| Premier build, couches vides | `pip install` 4,9 s, tout est `Downloading`. Build total 16,4 s, image de base comprise |
| `requirements.txt` modifié, cache de couches encore là | roues déjà vues en `Using cached`. Build 7,5 s |
| Même changement avec `--no-cache` | `Downloading` à nouveau. Build 8,2 s |

Le cache de couches saute entièrement un `RUN` si `requirements.txt` n'a pas changé. Le cache mount (`id=pip-${TARGETARCH}`) garde les roues téléchargées : un `requirements.txt` différent ne retélécharge pas les paquets déjà présents. `--no-cache`, sur ce BuildKit, ignore les deux : les roues sont re-téléchargées.

`docker builder prune -f` a supprimé 1,9 Go de cache. Le build suivant a aussi re-téléchargé les roues : sur Docker 29 ce prune retire aussi les cache mounts, pas seulement les couches.

## 3. Multi-architecture

Build mesuré avec le builder `shop` (`docker-container`) :

| Plateforme | `pip install` |
|--|--|
| `linux/amd64` | 5,0 s, roue `x86_64`, cache `pip-amd64` |
| `linux/arm64` | 47,5 s, roue `aarch64`, cache `pip-arm64` |

`--push` ou `-o` est obligatoire : le moteur Docker local ne stocke pas une manifest list, seulement une image d'une plateforme. L'export OCI est `starter/shop-worker/worker.tar` (94 Mo, ignoré par Git). La manifest list est `sha256:ad4db6e65a5b89e3af259668f7826850aef7f6c2a36919f4aaf7dbbdfb718206`, avec un manifest et une config par architecture.

`ARG TARGETARCH` entre dans l'id du cache mount (`pip-amd64`, `pip-arm64`) pour ne pas mélanger les roues. Le build arm64 est plus lent sur cette machine amd64 parce que les instructions passent par QEMU. L'alternative est un builder avec un nœud natif par architecture (`--platform` sur chaque nœud, machines Graviton ou Mac arm64).

## 4. Cache distant

`mode=min` n'exporte que les couches de l'image finale. `mode=max` exporte aussi les stages `builder` et `test`, donc la CI réutilise `pip install`. `type=gha` utilise le cache GitHub Actions, `type=s3` un bucket. Le registre `localhost:5000` est celui du TP03 : les lignes `cache-to` / `cache-from` sont dans `docker-bake.hcl`, le push n'a pas été fait ici.

## 5. Bake

`docker-bake.hcl` a le groupe `default` (`api` du TP01 + `worker`), la cible `_common` (labels, `linux/amd64` + `linux/arm64`, cache registre) et `worker-test` (stage `test` seulement).

`docker buildx bake --print` décrit le plan. `docker buildx bake --set worker-test.platform=linux/amd64 worker-test` exécute les tests : 2 passed.

Pour charger l'image locale sans registre :

```bash
VERSION=1.0 docker buildx bake --set *.platform=linux/amd64 --set *.cache-from= --set *.cache-to= --load
```
