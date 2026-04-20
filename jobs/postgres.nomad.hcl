job "care-postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "postgres" {
    count = 1

    network {
      port "db" {
        static = 5432
        to     = 5432
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image        = "postgres:17-alpine"
        ports        = ["db"]
        hostname     = "postgres"
        network_mode = "care-net"
        volumes      = ["local/postgres:/var/lib/postgresql/data"]
      }

      env {
        POSTGRES_DB       = "care"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
      }

      resources {
        cpu    = 300
        memory = 256
      }
    }
  }
}
