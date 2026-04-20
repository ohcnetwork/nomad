#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting Nomad..."
nomad agent -config=/etc/nomad.d > nomad.log 2>&1 &

timeout=30
until nomad node status >/dev/null 2>&1; do
  timeout=$((timeout - 1))
  [ "$timeout" -le 0 ] && echo "ERROR: Nomad failed to start" >&2 && exit 1
  sleep 1
done
echo "    Nomad ready."

echo "==> Creating Docker network..."
docker network create care-net 2>/dev/null || true

echo "==> Deploying jobs..."
nomad job run jobs/postgres.nomad.hcl
nomad job run jobs/redis.nomad.hcl
nomad job run jobs/celery-beat.nomad.hcl
nomad job run jobs/celery-worker.nomad.hcl
nomad job run jobs/backend.nomad.hcl
