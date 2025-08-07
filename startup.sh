#!/bin/bash

sas_token=$1

sudo apt-get update
sudo apt-get install -y python3-pip unzip
sudo apt-get install -y nginx

mkdir -p /var/www/flaskapp
cd /var/www/flaskapp

wget "https://htsl2cs002sa.blob.core.windows.net/scripts/flask-app.zip${sas_token}" -O app.zip
unzip -o app.zip

pip3 install flask

nohup python3 app.py > app.log 2>&1 &
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
rm -rf __MACOSX # Remove any Mac-specific files
echo "Startup script completed."
exit 0
# End of script