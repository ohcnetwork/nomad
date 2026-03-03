#!/usr/bin/env bash
set -euo pipefail

echo "starting Consul agent..."
if pgrep -x consul >/dev/null 2>&1; then
  echo "Consul agent already running"
else
  consul agent -dev > consul.log 2>&1 &
  echo $! > consul.pid
  echo "Consul started"
fi

echo "Waiting for Consul..."
for i in {1..20}; do
  consul members >/dev/null 2>&1 && break
  sleep 1
done

echo "Starting Nomad dev agent..."

if pgrep -x nomad >/dev/null 2>&1; then
  echo "Nomad agent already running"
else
  nomad agent -dev > nomad.log 2>&1 &
  echo $! > nomad.pid
  echo "Nomad started"
fi

echo "Waiting for Nomad..."
for i in {1..20}; do
  nomad node status >/dev/null 2>&1 && break
  sleep 1
done

if ! nomad node status >/dev/null 2>&1; then
  echo "Nomad failed to start"
  exit 1
fi

echo "Deploying Postgres..."
nomad job run jobs/postgres.nomad.hcl

echo "Deploying Redis..."
nomad job run jobs/redis.nomad.hcl

echo "Deploying Care API..."
nomad job run jobs/backend.nomad.hcl

echo "Deployment complete"
