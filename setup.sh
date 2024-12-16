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

# Start and enable Docker
systemctl start docker
systemctl enable docker

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
