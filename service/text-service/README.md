# Text Service — Quick onboarding

Follow these steps to get the local database and web UI running. This is a short, numbered onboarding for local development.

Prerequisites

- Docker Desktop must be installed and running.
- Clone or navigate to this repo and open a terminal in this folder.

## 1. Open terminal and go to the service folder

```pwsh
cd d:\Repos\TypeRushService\Services\text-service
```

## 2. Start the stack

- For foreground logs (handy while developing):

```pwsh
docker compose up
```

- For background (daemon) mode:

```pwsh
docker compose up -d
```

## 3. Verify services are running

```pwsh
docker ps
docker compose ps
```

You should see two services: `mongo` (27017) and `mongo-express` (8081).

## 4. Open mongo-express UI and login

- Open your browser to: http://localhost:8081/
- When prompted for HTTP Basic Auth, use:
  - Username: admin
  - Password: 12345

## 5. Quick checks if something’s wrong

- If the page doesn't load, check Docker and container status:

```pwsh
docker compose logs -f
```

- Check mongo logs specifically:

```pwsh
docker compose logs -f mongo
```

- If ports are already in use, change the port mappings in `docker-compose.yaml` or stop the conflicting process.

## 6. Stop and clean up

```pwsh
docker compose down
```

## 7. Connection strings

- From the host (apps running on host):

```
MONGO_DB=mongodb://root:12345@localhost:27017/
```

- From other containers inside this compose network use:

```
mongodb://root:12345@mongo:27017/
```
