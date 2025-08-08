#!/bin/bash

sas_token=$1

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y python3-pip unzip nginx

# Start and enable NGINX
sudo systemctl start nginx
sudo systemctl enable nginx

# Create app directory
sudo mkdir -p /var/www/html
cd /var/www/html

# Download and extract Flask app
wget "https://htsl2cs002sa.blob.core.windows.net/scripts/flask-app.zip${sas_token}" -O app.zip
unzip -o app.zip

# Install Flask
pip3 install flask

# Run the Flask app in the background
nohup python3 app.py > app.log 2>&1 &

# Wait and check if it started
sleep 5
if pgrep -f "python3 app.py" > /dev/null; then
    echo "Flask app started successfully."
else
    echo "Failed to start Flask app."
    exit 1
fi

echo "Flask app is running."

# Clean up
rm app.zip
rm -rf __MACOSX

echo "Startup script completed."
exit 0
