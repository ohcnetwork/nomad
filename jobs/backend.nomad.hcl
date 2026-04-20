job "care-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "backend" {
    count = 1

    network {
      port "http" {
        static = 9000
        to     = 9000
      }
    }

    update {
      healthy_deadline  = "15m"
      progress_deadline = "20m"
    }

    task "api" {
      driver = "docker"

      config {
        image        = "ghcr.io/ohcnetwork/care:latest"
        ports        = ["http"]
        network_mode = "care-net"

        command = "bash"
        args    = ["start.sh"]
      }

      env {
        DJANGO_SETTINGS_MODULE = "config.settings.production"

        DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/care"
        REDIS_URL    = "redis://redis:6379/0"

        POSTGRES_HOST     = "postgres"
        POSTGRES_PORT     = "5432"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "care"

        DJANGO_SECRET_KEY                     = "insecure-dev-key"
        DJANGO_SECURE_SSL_REDIRECT            = "false"
        DJANGO_SECURE_HSTS_PRELOAD            = "false"
        DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS = "false"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
