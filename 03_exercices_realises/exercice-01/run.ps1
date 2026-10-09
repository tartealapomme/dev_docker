$ErrorActionPreference = "Stop"

docker pull ubuntu:24.04
docker rm -f ex01-ubuntu 2>$null

docker run -d --name ex01-ubuntu ubuntu:24.04 sleep infinity
docker exec ex01-ubuntu bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx && nginx -v"
docker commit ex01-ubuntu ubuntu-nginx
docker stop ex01-ubuntu
docker rm ex01-ubuntu

docker images ubuntu-nginx
Write-Output "Image ubuntu-nginx creee."
