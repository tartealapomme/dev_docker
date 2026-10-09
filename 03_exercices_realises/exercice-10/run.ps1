$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

$busy = docker ps --filter "publish=8080" --format "{{.Names}}"
if ($busy) {
  Write-Output "Liberation du port 8080 (conteneur: $busy)"
  docker stop $busy | Out-Null
}

docker compose down 2>$null | Out-Null
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw "docker compose up a echoue" }

Write-Output "Attente application..."
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/api/info/health" -UseBasicParsing
    if ($r.StatusCode -eq 200 -and $r.Content -match '"database":"UP"') { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
if (-not $ready) { throw "Application non prete" }

Write-Output "=== Test env ==="
Invoke-RestMethod -Uri "http://localhost:8080/api/info/env" | ConvertTo-Json

Write-Output "=== Creation note ==="
$body = '{"title":"Test persistance","content":"Note pour valider les volumes","category":"WORK","priority":"HIGH"}'
$note = Invoke-RestMethod -Method Post -Uri "http://localhost:8080/api/notes" -ContentType "application/json" -Body $body
$note | ConvertTo-Json

Write-Output "=== Test persistance (stop/start sans -v) ==="
docker compose stop | Out-Null
docker compose start | Out-Null
$ready = $false
for ($i = 0; $i -lt 40; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/api/info/health" -UseBasicParsing
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
$notes = Invoke-RestMethod -Uri "http://localhost:8080/api/notes"
$found = $notes | Where-Object { $_.title -eq "Test persistance" }
if (-not $found) { throw "Persistance echouee: note absente apres restart" }
Write-Output "Persistance OK"

Write-Output "=== Test perte donnees (down -v) ==="
docker compose down -v | Out-Null
docker compose up -d | Out-Null
$ready = $false
for ($i = 0; $i -lt 40; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/api/info/health" -UseBasicParsing
    if ($r.StatusCode -eq 200 -and $r.Content -match '"database":"UP"') { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
$notes = Invoke-RestMethod -Uri "http://localhost:8080/api/notes"
$found = $notes | Where-Object { $_.title -eq "Test persistance" }
if ($found) { throw "La note aurait du disparaitre apres down -v" }
Write-Output "Perte des donnees OK (reste init SQL)"
$notes | Select-Object id, title | Format-Table

Write-Output "=== Test modification APP_NAME ==="
$envFile = Join-Path $PSScriptRoot ".env"
(Get-Content $envFile) -replace '^APP_NAME=.*', 'APP_NAME=Mon Application Modifiee' | Set-Content $envFile
docker compose up -d --force-recreate app | Out-Null
$ready = $false
$envInfo = $null
for ($i = 0; $i -lt 40; $i++) {
  try {
    $envInfo = Invoke-RestMethod -Uri "http://localhost:8080/api/info/env"
    if ($envInfo.APP_NAME -eq "Mon Application Modifiee") { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
if (-not $ready) { throw "APP_NAME non mis a jour" }
Write-Output "APP_NAME = $($envInfo.APP_NAME)"

(Get-Content $envFile) -replace '^APP_NAME=.*', 'APP_NAME=Notes Manager' | Set-Content $envFile
docker compose up -d --force-recreate app | Out-Null

Write-Output "Exercice 10 OK - http://localhost:8080"
