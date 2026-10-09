$ErrorActionPreference = "Stop"

docker network create ex05-net 2>$null
docker volume create ex05-mysql-data 2>$null
docker rm -f ex05-mysql ex05-adminer 2>$null

docker run -d --name ex05-mysql `
  --network ex05-net `
  --restart unless-stopped `
  -e MYSQL_ROOT_PASSWORD=rootpass `
  -e MYSQL_DATABASE=exercice05 `
  -e MYSQL_USER=ynov `
  -e MYSQL_PASSWORD=ynovpass `
  -v ex05-mysql-data:/var/lib/mysql `
  mysql:8.0

docker run -d --name ex05-adminer `
  --network ex05-net `
  --restart unless-stopped `
  -p 8082:8080 `
  adminer:latest

Write-Output "Adminer: http://localhost:8082"
Write-Output "Serveur=ex05-mysql User=ynov Password=ynovpass Base=exercice05"
Write-Output "Bonus compose: docker compose -f `"$PSScriptRoot\compose.yaml`" up -d"
