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

# Make all scripts executable
chmod +x setup.sh deploy.sh nginx_config.sh ssl_config.sh

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
🎉 Saleor Installation Complete! 🎉
===========================================

Your Saleor instances are available at:
- API: https://api.hashloop.org
- Dashboard: https://dashboard.hashloop.org
- Storefront: https://storefront.hashloop.org

Important next steps:
1. Access the dashboard and set up your first admin user
2. Configure your store settings
3. Set up your first products

For troubleshooting, check the logs at: $log_file
===========================================
"
