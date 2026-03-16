# Nomad Jobs Setup Documentation

This document describes the Nomad job configurations for deploying the CARE application stack in a production environment using HashiCorp Nomad and Consul service mesh.

## Overview

The CARE application consists of three main services deployed as Nomad jobs:

1. **PostgreSQL Database** (`postgres.nomad.hcl`) - Primary database service
2. **Redis Cache** (`redis.nomad.hcl`) - Caching and message broker service
3. **CARE Backend API** (`backend.nomad.hcl`) - Django-based REST API service

All services are configured to use Consul service mesh for secure service-to-service communication and automatic service discovery.

## Architecture

```
[CARE Backend API]
    ↑
    ↓ (Service Mesh)
[PostgreSQL] ←→ [Redis]
```

The backend service connects to PostgreSQL and Redis through Consul service mesh upstreams, ensuring encrypted communication and automatic failover.

## Job Configurations

### PostgreSQL Job (`postgres.nomad.hcl`)

**Purpose**: Provides the primary database service for the CARE application.

**Key Features**:

- Uses PostgreSQL 16 Alpine image
- Exposes port 5432 for database connections
- Includes health checks using `pg_isready`
- Persistent data storage via Docker volume
- Service mesh integration with Consul Connect

**Configuration**:

- Database: `care`
- User: `postgres`
- Password: `postgres`
- Host authentication: trust-based (for development)

**Resources**:

- CPU: 500 MHz
- Memory: 512 MB

### Redis Job (`redis.nomad.hcl`)

**Purpose**: Provides caching and message queuing services for the CARE application.

**Key Features**:

- Uses Redis 7 Alpine image
- Exposes port 6379 for Redis connections
- Health checks using `redis-cli ping`
- Service mesh integration with Consul Connect

**Resources**:

- CPU: 200 MHz
- Memory: 128 MB

### CARE Backend Job (`backend.nomad.hcl`)

**Purpose**: Runs the Django-based CARE REST API service.

**Key Features**:

- Uses CARE Docker image from GitHub Container Registry
- Exposes port 9000 for HTTP traffic
- Automatic database migration on startup
- Static file collection
- Gunicorn WSGI server with 2 workers and 2 threads
- Service mesh upstreams to PostgreSQL (port 5432) and Redis (port 6379)
- Health checks via `/health/` endpoint

**Environment Configuration**:

- Production Django settings
- Database connection via service mesh
- Redis connection via service mesh
- Development-friendly security settings (SSL disabled, CORS enabled)

**Startup Process**:

1. Waits for PostgreSQL readiness
2. Runs Django migrations
3. Collects static files
4. Starts Gunicorn server

**Resources**:

- CPU: 600 MHz
- Memory: 1024 MB

## Service Mesh Configuration

All services use Consul Connect for secure communication:

- **Sidecar proxies** handle encryption and service discovery
- **Upstreams** allow the backend to connect to database services without knowing their network locations
- **Health checks** ensure traffic is only routed to healthy instances

## Deployment

### Prerequisites

- Nomad server running
- Consul server running
- Docker runtime available on Nomad clients

### Deployment Commands

Deploy services in order (dependencies first):

```bash
# Deploy database
nomad job run jobs/postgres.nomad.hcl

# Deploy cache
nomad job run jobs/redis.nomad.hcl

# Deploy application
nomad job run jobs/backend.nomad.hcl
```

### Verification

Check deployment status:

```bash
nomad job status
nomad alloc status <allocation-id>
```

Check service health in Consul:

```bash
consul catalog services
```

### Production Scripts

Use the provided scripts for automated deployment:

- `scripts/nomad-prod-up.sh` - Start Consul/Nomad and deploy all services
- `scripts/nomad-prod-down.sh` - Stop all services and agents

## Monitoring and Troubleshooting

### Health Checks

- PostgreSQL: `pg_isready` script check every 10 seconds
- Redis: `redis-cli ping` script check every 10 seconds
- Backend: HTTP check to `/health/` endpoint every 15 seconds

### Logs

View job logs:

```bash
nomad alloc logs <allocation-id>
```

### Common Issues

1. **Backend startup failures**: Check PostgreSQL connectivity and migration status
2. **Service mesh issues**: Verify Consul agent connectivity and service registration
3. **Resource constraints**: Monitor CPU/memory usage and adjust allocations as needed

## Security Considerations

- Service mesh encryption is enabled for all inter-service communication
- Database credentials are configured for development (should be externalized in production)
- Django security settings are relaxed for development (SSL redirects disabled)

## Scaling

Currently configured for single instances. For production scaling:

- Increase `count` in job groups
- Add load balancers for backend services
- Configure persistent volumes for database high availability
- Implement Redis clustering for cache scaling
