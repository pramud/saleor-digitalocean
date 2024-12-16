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
    uidmap \
    systemd

# Create saleor user
useradd -m -s /bin/bash saleor
usermod -aG sudo saleor
echo "saleor ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Switch to saleor user and setup rootless Docker
su - saleor << 'EOF'
# Setup rootless mode
export XDG_RUNTIME_DIR=/home/saleor/.docker/run
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Setup Docker rootless
dockerd-rootless-setuptool.sh install

# Add environment variables to .bashrc
cat >> ~/.bashrc << 'INNEREOF'
export XDG_RUNTIME_DIR=/home/saleor/.docker/run
export DOCKER_HOST=unix:///home/saleor/.docker/run/docker.sock
export PATH=/usr/bin:$PATH
INNEREOF

# Start Docker daemon
systemctl --user enable docker
systemctl --user start docker

# Enable lingering for the saleor user
loginctl enable-linger $(whoami)
EOF

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js and pnpm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g pnpm@8

# Create deployment directory and set permissions
mkdir -p /opt/saleor
chown -R saleor:saleor /opt/saleor

# Set up firewall
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
ufw --force enable

echo "Setup completed at $(date)"
