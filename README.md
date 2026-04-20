# Nomad Setup Guide

Nomad orchestrates the CARE application stack. PostgreSQL, Redis, Celery beat, Celery worker, and the CARE backend run as Docker containers on a shared `care-net` bridge network, using container hostnames for service discovery.

For full documentation, see the [Setup Guide](docs/setup.md).

## Prerequisites

- Nomad agent configured at `/etc/nomad.d/nomad.hcl`
- Docker runtime available and accessible to Nomad

## Quick Start

```bash
make nomad-up
```

```bash
make nomad-down
```

```bash
make nomad-status
```

## Architecture

```
        [CARE Backend API]
               |
        [Celery Worker]
               |
        [Celery Beat]
         /              \
   [PostgreSQL]       [Redis]
```

All containers share the `care-net` Docker bridge network and resolve `postgres` and `redis` by hostname.

## Nomad Config

path: `/etc/nomad.d/nomad.hcl`

```hcl
datacenter = "dc1"
data_dir   = "/opt/nomad/data"
bind_addr  = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
  }
}

log_level = "INFO"
```

## Accessing the Application

- **Nomad UI**: <http://localhost:4646>
- **Backend API**: <http://localhost:9000>
- **Health check**: <http://localhost:9000/health/>
