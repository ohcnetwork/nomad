job "care-postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "postgres" {
    count = 1

    network {
      mode = "bridge"
      port "db" {
        to = 5432
      }
    }

    service {
      name = "postgres"
      port = "db"
      provider = "consul"

      connect {
        sidecar_service {}
      }

      check {
        type     = "script"
        name     = "postgres-ready"
        task     = "postgres"  # Specifies which task runs the script
        command  = "pg_isready"
        args     = ["-U", "postgres", "-d", "care"]
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "postgres" {
      driver = "docker"
      config {
        image = "postgres:16-alpine"
        # Persistence: ensure /opt/postgres/data exists on the host
        volumes = [
          "local/postgres:/var/lib/postgresql/data"
        ]
      }
      env {
        POSTGRES_DB       = "care"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"

        POSTGRES_HOST_AUTH_METHOD = "trust"
      }
      resources {
              cpu    = 500
              memory = 512
            }
    }
  }
}
