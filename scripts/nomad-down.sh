#!/usr/bin/env bash
set -euo pipefail

echo "==> Stopping jobs..."
nomad job stop -purge care-backend 2>/dev/null || true
nomad job stop -purge care-celery-worker 2>/dev/null || true
nomad job stop -purge care-celery-beat 2>/dev/null || true
nomad job stop -purge care-redis 2>/dev/null || true
nomad job stop -purge care-postgres 2>/dev/null || true

echo "==> Stopping Nomad..."
pkill -TERM nomad 2>/dev/null || true

docker network rm care-net 2>/dev/null || true
echo "    Done."
