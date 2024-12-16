#!/bin/bash
set -e  # Exit on error

# Add logging
log_file="/var/log/saleor_setup.log"
exec 1> >(tee -a "$log_file") 2>&1
echo "Starting setup at $(date)"

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    nginx \
    certbot \
    python3-certbot-nginx \
    postgresql \
    postgresql-contrib \
    redis-server

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# After Docker installation, set up rootless mode
echo "Setting up Docker rootless mode..."
apt-get install -y uidmap
systemctl disable --now docker.service
systemctl disable --now docker.socket

# Setup rootless mode for the current user
dockerd-rootless-setuptool.sh install

# Add environment variables to .bashrc
echo 'export PATH=/usr/bin:$PATH' >> ~/.bashrc
echo 'export DOCKER_HOST=unix:///run/user/1000/docker.sock' >> ~/.bashrc

# Start rootless Docker daemon
systemctl --user enable docker
systemctl --user start docker

# Allow current user to run Docker commands without sudo
loginctl enable-linger $(whoami)

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js and pnpm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g pnpm@8

# Create deployment directory
mkdir -p /opt/saleor
cd /opt/saleor

# Set up firewall
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
ufw --force enable

echo "Setup completed at $(date)"
