$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
docker compose up -d
$httpPort = "8095"
Get-Content .env | ForEach-Object {
  if ($_ -match "^HTTP_PORT=(.+)$") { $httpPort = $Matches[1] }
}
Write-Output "WordPress: http://localhost:$httpPort"
