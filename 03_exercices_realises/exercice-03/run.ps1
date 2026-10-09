$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
docker build -t ex03-site $root
docker rm -f ex03-nginx 2>$null
docker run -d --name ex03-nginx -p 8081:80 ex03-site

Write-Output "Site disponible sur http://localhost:8081"
