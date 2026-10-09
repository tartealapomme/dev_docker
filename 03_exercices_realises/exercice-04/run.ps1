$ErrorActionPreference = "Stop"

docker network create ex04-net 2>$null
docker rm -f ex04-a ex04-b 2>$null

docker run -d --name ex04-a --network ex04-net ubuntu:24.04 sleep infinity
docker exec ex04-a bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iputils-ping"
docker commit ex04-a ubuntu-ping

docker run -d --name ex04-b --network ex04-net ubuntu-ping sleep infinity

Write-Output "Ping ex04-a -> ex04-b"
docker exec ex04-a ping -c 3 ex04-b
Write-Output "Ping ex04-b -> ex04-a"
docker exec ex04-b ping -c 3 ex04-a
