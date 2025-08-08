#!/bin/bash

sas_token=$1

# Update & install required packages
sudo apt-get update
sudo apt-get install -y python3-pip unzip nginx

# Setup Flask app
mkdir -p /var/www/flaskapp
cd /var/www/flaskapp

# Download and extract app
wget "https://htsl2cs002sa.blob.core.windows.net/scripts/flask-app.zip${sas_token}" -O app.zip
unzip -o app.zip

# Install Python dependencies
pip3 install flask

# Run the Flask app (hosted on 127.0.0.1:5000)
nohup python3 app.py > app.log 2>&1 &

# Wait and check if Flask started
sleep 5
if pgrep -f "python3 app.py" > /dev/null; then
    echo "Flask app started successfully."
else
    echo "Failed to start Flask app."
    exit 1
fi

# Configure NGINX as reverse proxy
cat <<EOF | sudo tee /etc/nginx/sites-available/flaskapp
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the config and restart NGINX
sudo ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Cleanup
rm app.zip
rm -rf __MACOSX

echo "Startup script completed."
exit 0
