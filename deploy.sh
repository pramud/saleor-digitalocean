#!/bin/bash
set -e

cd /opt/saleor

# Clone repositories if they don't exist
if [ ! -d "saleor-platform" ]; then
    git clone https://github.com/saleor/saleor-platform.git
fi

if [ ! -d "storefront" ]; then
    git clone https://github.com/saleor/storefront.git
fi

# Configure saleor-platform
cd saleor-platform

# Create production environment files
cat > common.env << EOL
DEBUG=False
DEFAULT_FROM_EMAIL=noreply@hashloop.org
ENABLE_SSL=True
JWT_TTL_ACCESS=5m
JWT_TTL_REFRESH=30d
JWT_TTL_REQUEST_EMAIL_CHANGE=1h
ALLOWED_HOSTS=api.hashloop.org,localhost
ALLOWED_CLIENT_HOSTS=dashboard.hashloop.org,storefront.hashloop.org,localhost
PUBLIC_URL=https://api.hashloop.org/
HTTP_IP_FILTER_ENABLED=True
CACHE_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/1
DATABASE_URL=postgres://saleor:saleor@db/saleor
SECRET_KEY=$(openssl rand -hex 32)
EMAIL_URL=smtp://mailpit:1025
EOL

# Generate RSA keys for JWT authentication
mkdir -p jwt
# Generate a simple RSA key pair in PEM format
openssl genpkey -algorithm RSA -out jwt/jwt_private.pem -pkeyopt rsa_keygen_bits:4096
openssl rsa -in jwt/jwt_private.pem -pubout -out jwt/jwt_public.pem

# Add RSA keys to environment variables directly from the files
echo "RSA_PRIVATE_KEY=$(cat jwt/jwt_private.pem)" >> common.env
echo "RSA_PUBLIC_KEY=$(cat jwt/jwt_public.pem)" >> common.env

# Build and start services
docker-compose build
docker-compose up -d

# Initialize database
docker-compose run --rm api python3 manage.py migrate
docker-compose run --rm api python3 manage.py createsuperuser
