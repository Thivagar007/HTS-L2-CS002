#!/usr/bin/env bash
# Usage: startup.sh <storageAccount> <container> <blobPrefix> <sasToken>
set -euo pipefail

ACCOUNT="${1:-}"
CONTAINER="${2:-}"
PREFIX="${3:-}"
SAS="${4:-}"

if [[ -z "$ACCOUNT" || -z "$CONTAINER" || -z "$PREFIX" || -z "$SAS" ]]; then
  echo "Usage: $0 <storageAccount> <container> <blobPrefix> <sasToken>"
  exit 1
fi

ZIP_URL="https://${ACCOUNT}.blob.core.windows.net/${CONTAINER}/${PREFIX}/flask-app.zip?${SAS}"
REQ_URL="https://${ACCOUNT}.blob.core.windows.net/${CONTAINER}/${PREFIX}/requirements.txt?${SAS}"

echo "==> Installing system packages"
sudo apt-get update -y
sudo apt-get install -y python3-venv python3-pip nginx curl unzip

APP_DIR="/opt/flaskapp"
sudo mkdir -p "$APP_DIR"
sudo chown -R "$USER":"$USER" "$APP_DIR"
cd "$APP_DIR"

echo "==> Downloading artifact"
curl -fSL "$ZIP_URL" -o app.zip
curl -fSL "$REQ_URL" -o requirements.txt || echo "flask" > requirements.txt

echo "==> Unzipping artifact"
rm -rf app || true
mkdir -p app && unzip -qo app.zip -d app

echo "==> Creating virtualenv & installing deps"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "==> Creating systemd service (gunicorn)"
sudo tee /etc/systemd/system/flaskapp.service >/dev/null <<'UNIT'
[Unit]
Description=Flask TicTacToe (Gunicorn)
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/flaskapp/app
Environment="PATH=/opt/flaskapp/venv/bin"
ExecStart=/opt/flaskapp/venv/bin/gunicorn -w 2 -b 127.0.0.1:8000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

echo "==> Adjusting ownership"
sudo chown -R www-data:www-data "$APP_DIR"

echo "==> Enabling service"
sudo systemctl daemon-reload
sudo systemctl enable --now flaskapp
sudo systemctl status flaskapp --no-pager || true

echo "==> Configuring Nginx reverse proxy at /tictactoe"
sudo tee /etc/nginx/sites-available/flaskapp >/dev/null <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    location /tictactoe/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # static files (optional):
    location /static/ {
        alias /opt/flaskapp/app/static/;
    }
}
NGINX

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/flaskapp
sudo nginx -t
sudo systemctl restart nginx

echo "==> Deployed. Try: http://$(curl -s ifconfig.me)/tictactoe/"
