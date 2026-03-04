# Nomad Setup Guide

Nomad orchestrates the CARE application and its dependencies in a development environment.

## Quick Start

### Starting the Nomad Cluster

```bash
./scripts/nomad-up.sh
```

### Stopping the Nomad Cluster

```bash
./scripts/nomad-down.sh
```

### Check Status

```bash
make nomad-status
```

## consul connect version

```bash
make nomad-prod-up
```

```bash
make nomad-prod-down
```

## Config
This setup helped me get it running

### Nomad

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

  host_volume "postgres_storage" {
    path      = "/opt/care/postgres"
    read_only = false
  }
}

plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
  }
}

consul {
  address = "127.0.0.1:8500"
}

log_level = "INFO"
```
## consul

path: `/etc/consul.d/consul.hcl`

```hcl
# Datacenter name
datacenter = "dc1"

# Data directory
data_dir = "/opt/consul"

# Bind to the private IP
bind_addr = "192.168.1.42"
advertise_addr = "192.168.1.42"

# Client address (UI and API accessible on all interfaces)
client_addr = "0.0.0.0"

# Server mode
server = true
bootstrap_expect = 1

# Enable UI
ui_config {
  enabled = true
}

# Enable Service Mesh (Consul Connect)
connect {
  enabled = true
}

# Port configuration
ports {
  dns      = 8600
  http     = 8500
  https    = -1
  grpc     = 8502
  serf_lan = 8301
  serf_wan = 8302
  server   = 8300
}

# Performance tuning
performance {
  raft_multiplier = 1
}

# Enable local script checks
enable_local_script_checks = true

# Log level
log_level = "INFO"
```


### Accessing the Application

- **Nomad UI**: <http://localhost:4646>
- **Backend API**: <http://localhost:9000>
