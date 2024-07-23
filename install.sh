#!/bin/bash

# Install necessary dependencies
echo "Installing necessary dependencies..."
sudo apt-get update
sudo apt-get install -y net-tools docker.io nginx

# Copy the devopsfetch script to /usr/local/bin
echo "Copying devopsfetch script to /usr/local/bin..."
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

# Create a systemd service
echo "Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOps Fetch Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch
Restart=always
User=root
Group=root
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch
sudo systemctl start devopsfetch

# Set up log rotation
echo "Setting up log rotation..."
cat <<EOF | sudo tee /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        systemctl restart devopsfetch > /dev/null
    endscript
}
EOF

echo "Installation complete."
