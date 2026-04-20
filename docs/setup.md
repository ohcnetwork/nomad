# Setup Guide

## Overview

Five Nomad jobs make up the CARE stack:

| Job                   | File                            | Purpose                        |
| --------------------- | ------------------------------- | ------------------------------ |
| `care-postgres`       | `jobs/postgres.nomad.hcl`       | PostgreSQL 17 database         |
| `care-redis`          | `jobs/redis.nomad.hcl`          | Redis 8 cache / message broker |
| `care-celery-beat`    | `jobs/celery-beat.nomad.hcl`    | Celery periodic task scheduler |
| `care-celery-worker`  | `jobs/celery-worker.nomad.hcl`  | Celery async task worker       |
| `care-backend`        | `jobs/backend.nomad.hcl`        | Django REST API (Gunicorn)     |

All containers run on a shared `care-net` Docker bridge network. Services connect to `postgres:5432` and `redis:6379` by hostname.

## Prerequisites

- Nomad installed and running
- Docker available on Nomad client nodes

## Job Details

### `care-postgres`

- Image: `postgres:17-alpine`
- Port: `5432` (static), hostname `postgres`
- Data persisted to `local/postgres` in the allocation directory
- Resources: 300 MHz CPU, 256 MB RAM
- Credentials: `POSTGRES_USER=postgres`, `POSTGRES_PASSWORD=postgres`, `POSTGRES_DB=care`

### `care-redis`

- Image: `redis:8-alpine`
- Port: `6379` (static), hostname `redis`
- Resources: 100 MHz CPU, 128 MB RAM

### `care-celery-beat`

- Image: `ghcr.io/ohcnetwork/care:latest`
- No exposed ports
- Resources: 200 MHz CPU, 256 MB RAM
- Startup: waits for PostgreSQL and Redis, runs migrations, syncs permissions/roles and valuesets, then starts the Celery beat scheduler

### `care-celery-worker`

- Image: `ghcr.io/ohcnetwork/care:latest`
- No exposed ports
- Resources: 500 MHz CPU, 512 MB RAM
- Startup: waits for PostgreSQL and Redis, collects static files, then starts the Celery worker
- Concurrency controlled via `CELERY_WORKER_CONCURRENCY` (default: `1`)

### `care-backend`

- Image: `ghcr.io/ohcnetwork/care:latest`
- Port: `9000` (static, host-exposed)
- Resources: 500 MHz CPU, 512 MB RAM
- Startup: waits for PostgreSQL, runs migrations, then starts Gunicorn

## Deployment

```bash
make nomad-up      # start Nomad and deploy all jobs
make nomad-down    # stop all jobs and Nomad
make nomad-restart # restart everything
make nomad-status  # show job status
```

Manual teardown:

```bash
nomad job stop -purge care-backend
nomad job stop -purge care-celery-worker
nomad job stop -purge care-celery-beat
nomad job stop -purge care-redis
nomad job stop -purge care-postgres
pkill -TERM nomad
docker network rm care-net
```

## Verification

```bash
curl http://localhost:9000/health/
```

Expected response:

```json
{
  "health": [
    { "name": "Database", "code": 200, "message": "All OK" },
    { "name": "Cache", "code": 200, "message": "All OK" },
    { "name": "Celery Queue Length", "code": 200, "message": "All OK" }
  ]
}
```

## Troubleshooting

**Backend stuck waiting for DB** - check that `care-postgres` is running and `care-net` exists:

```bash
nomad job status care-postgres
docker network inspect care-net
```

**Migration failures** - check allocation logs:

```bash
nomad alloc logs <alloc-id>
```

**Port already in use** - static ports 5432, 6379, and 9000 must be free before running `make nomad-up`.

**Stale allocation after restart** - purge jobs manually before restarting:

```bash
nomad job stop -purge care-backend
nomad job stop -purge care-celery-worker
nomad job stop -purge care-celery-beat
nomad job stop -purge care-redis
nomad job stop -purge care-postgres
```
