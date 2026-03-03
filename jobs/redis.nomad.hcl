job "care-redis" {
  datacenters = ["dc1"]
  type        = "service"

  group "redis" {
    count = 1

    network {
      mode = "bridge"
      port "redis" {
        to = 6379
      }
    }

    service {
      name = "redis"
      port = "redis"
      provider = "consul"
      connect {
        sidecar_service {}
      }

      # Health check ensures the mesh only routes traffic when Redis is ready
      check {
        type     = "script"
        name     = "redis-ping"
        task     = "redis"  # Must match the task name below
        command  = "redis-cli"
        args     = ["ping"]
        interval = "10s"
        timeout  = "2s"
      }

    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7-alpine"
        # The port is mapped inside the bridge network
        ports = ["redis"]
      }

      resources {
              cpu    = 200
              memory = 128
            }
    }
  }
}
