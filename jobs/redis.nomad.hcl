job "care-redis" {
  datacenters = ["dc1"]
  type        = "service"

  group "redis" {
    count = 1

    network {
      port "redis" {
        static = 6379
        to     = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image        = "redis:8-alpine"
        ports        = ["redis"]
        hostname     = "redis"
        network_mode = "care-net"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
