job "care-backend" {
  datacenters = ["dc1"]
  type        = "service"

  group "backend" {
    count = 1

    network {
      mode = "bridge"
      port "http" { static = 9000 }
      dns { servers = ["8.8.8.8", "8.8.4.4"] }
    }

    service {
      name     = "care-backend"
      port     = "http"
      provider = "consul"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "postgres"
              local_bind_port  = 5432
            }
            upstreams {
              destination_name = "redis"
              local_bind_port  = 6379
            }
          }
        }
      }
      check {
        type     = "http"
        path     = "/"
        interval = "15s"
        timeout  = "5s"
      }
    }

    task "api" {
      driver = "docker"
      config {
        image   = "ghcr.io/ohcnetwork/care:latest"
        ports   = ["http"]
        command = "bash"
        args    = ["-c", <<EOF
echo "Waiting for Postgres tunnel on 127.0.0.1:5432..."

python3 - <<END
import socket
import time
while True:
    try:
        with socket.create_connection(("127.0.0.1", 5432), timeout=2):
            print("Postgres tunnel is UP")
            break
    except OSError:
        print("Waiting for tunnel...")
        time.sleep(1)
END

echo "Tunnel ready! Running migrations..."
python manage.py migrate --noinput
python manage.py collectstatic --noinput --clear

echo "Starting Gunicorn..."
gunicorn config.wsgi:application \
  --bind=0.0.0.0:9000 \
  --workers=4 \
  --threads=2 \
  --timeout=120
EOF
        ]
      }

      env {
        DJANGO_SETTINGS_MODULE = "config.settings.production"
        DATABASE_URL           = "postgresql://postgres:postgres@127.0.0.1:5432/care"
        REDIS_URL              = "redis://127.0.0.1:6379/0"
        CELERY_BROKER_URL      = "redis://127.0.0.1:6379/0"
        ALLOWED_HOSTS          = "*"
        DEBUG                  = "false"
        SECRET_KEY             = "care-dev-secret-key"
        SECURE_SSL_REDIRECT    = "false"
        CORS_ALLOW_ALL_ORIGINS = "true"
      }

      resources {
        cpu    = 800
        memory = 1536
      }
    }
  }
}
