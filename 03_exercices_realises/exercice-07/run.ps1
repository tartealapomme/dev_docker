$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

docker build -t kennel-mysql $root
docker rm -f ex07-kennel-mysql 2>$null | Out-Null
docker run -d --name ex07-kennel-mysql -p 3307:3306 kennel-mysql

Write-Output "Attente initialisation MySQL..."
$ready = $false
for ($i = 0; $i -lt 40; $i++) {
  $out = cmd /c "docker exec ex07-kennel-mysql mysqladmin ping -h localhost -uroot -prootpass 2>&1"
  if ("$out" -match "mysqld is alive") { $ready = $true; break }
  Start-Sleep -Seconds 2
}
if (-not $ready) { throw "MySQL non pret" }

cmd /c "docker exec ex07-kennel-mysql mysql -uroot -prootpass kennelDB -e `"SHOW TABLES; SELECT COUNT(*) AS clients FROM clients; SELECT COUNT(*) AS chiens FROM chiens; SELECT COUNT(*) AS chats FROM chats;`" 2>&1"
Write-Output "kennelDB pret sur localhost:3307 (root / rootpass)"
