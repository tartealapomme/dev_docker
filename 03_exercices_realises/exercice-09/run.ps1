$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

docker compose down 2>$null | Out-Null
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw "docker compose up a echoue" }

Write-Output "Attente CRUD API..."
$ready = $false
for ($i = 0; $i -lt 70; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:8091/api/v1/dogs" -UseBasicParsing
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
if (-not $ready) { throw "CRUD API non prete" }

$body = '{"name":"Bella","birthDate":"2021-07-22","breed":"Labrador","sterilized":false}'
Invoke-RestMethod -Method Post -Uri "http://localhost:8091/api/v1/dogs" -ContentType "application/json" -Body $body | Out-Null
try { Invoke-WebRequest -Uri "http://localhost:8091/api/v1/dogs/999" -UseBasicParsing | Out-Null } catch {}

Write-Output "Dogs:"
Invoke-RestMethod -Uri "http://localhost:8091/api/v1/dogs" | ConvertTo-Json
Write-Output "Logs:"
Invoke-RestMethod -Uri "http://localhost:8092/api/v1/logs" | ConvertTo-Json

Write-Output "CRUD API: http://localhost:8091/api/v1/dogs"
Write-Output "Logs API: http://localhost:8092/api/v1/logs"
Write-Output "MySQL: localhost:3309"
