$ErrorActionPreference = "Stop"

$sitePath = Join-Path $PSScriptRoot "site"
docker rm -f ex06-nginx 2>$null
docker run -d --name ex06-nginx -p 8083:80 -v "${sitePath}:/usr/share/nginx/html:ro" nginx:alpine

Write-Output "Site de developpement: http://localhost:8083"
Write-Output "Editez les fichiers dans: $sitePath"
