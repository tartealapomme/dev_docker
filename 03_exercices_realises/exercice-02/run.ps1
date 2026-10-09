$ErrorActionPreference = "Stop"

docker pull amigoscode/2048
docker rm -f ex02-2048 2>$null
docker run -d --name ex02-2048 -p 8080:80 amigoscode/2048

Write-Output "2048 disponible sur http://localhost:8080"
