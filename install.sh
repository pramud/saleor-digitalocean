#!/bin/bash
set -e

# Add logging
log_file="/var/log/saleor_installation.log"
exec 1> >(tee -a "$log_file") 2>&1

echo "Starting Saleor installation at $(date)"

# Function to check if script execution was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 completed successfully"
    else
        echo "❌ $1 failed"
        exit 1
    fi
}

# Create scripts directory
mkdir -p /opt/saleor/scripts
cd /opt/saleor/scripts

# Download all required scripts
echo "Downloading installation scripts..."
curl -O https://raw.githubusercontent.com/yourgithub/saleor-deployment/main/setup.sh
curl -O https://raw.githubusercontent.com/yourgithub/saleor-deployment/main/deploy.sh
curl -O https://raw.githubusercontent.com/yourgithub/saleor-deployment/main/nginx_config.sh
curl -O https://raw.githubusercontent.com/yourgithub/saleor-deployment/main/ssl_config.sh

# Make scripts executable
chmod +x *.sh

# Run setup script
echo "Running system setup..."
./setup.sh
check_status "System setup"

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Run deployment script
echo "Running deployment..."
./deploy.sh
check_status "Deployment"

# Configure Nginx
echo "Configuring Nginx..."
./nginx_config.sh
check_status "Nginx configuration"

# Configure SSL
echo "Configuring SSL..."
./ssl_config.sh
check_status "SSL configuration"

# Install Saleor CLI for management
echo "Installing Saleor CLI..."
npm install -g @saleor/cli
check_status "Saleor CLI installation"

# Create a local app for API access
echo "Creating Saleor local app..."
cd /opt/saleor/saleor-platform
docker-compose run --rm api python3 manage.py create_app "Saleor Management" \
    --permission MANAGE_ORDERS \
    --permission MANAGE_USERS \
    --permission MANAGE_PRODUCTS \
    --activate
check_status "Local app creation"

echo "Installation completed at $(date)"

# Print important information
echo "
===========================================
��������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������
