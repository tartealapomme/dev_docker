$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

docker compose down 2>$null | Out-Null
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw "docker compose up a echoue" }

Write-Output "Attente API..."
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:8090/api/v1/dogs" -UseBasicParsing
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
if (-not $ready) { throw "API non prete" }

$body = '{"name":"Rex","birthDate":"2020-03-15","breed":"Berger Allemand","sterilized":true}'
Invoke-RestMethod -Method Post -Uri "http://localhost:8090/api/v1/dogs" -ContentType "application/json" -Body $body | Out-Null
Invoke-RestMethod -Uri "http://localhost:8090/api/v1/dogs" | ConvertTo-Json

Write-Output "API disponible sur http://localhost:8090/api/v1/dogs"
Write-Output "MySQL expose sur localhost:3308"
