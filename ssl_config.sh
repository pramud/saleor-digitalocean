#!/bin/bash
set -e

# Create SSL directory
mkdir -p /etc/letsencrypt

# Stop Nginx temporarily
systemctl stop nginx

# Obtain SSL certificates with staging first to verify setup
certbot certonly --staging \
    --standalone \
    -d api.hashloop.org \
    -d dashboard.hashloop.org \
    -d storefront.hashloop.org \
    --non-interactive \
    --agree-tos \
    --email pramud@hashloop.org

# If staging successful, get real certificates
certbot --nginx \
    -d api.hashloop.org \
    -d dashboard.hashloop.org \
    -d storefront.hashloop.org \
    --non-interactive \
    --agree-tos \
    --email pramud@hashloop.org \
    --redirect \
    --hsts \
    --staple-ocsp \
    --must-staple

# Start Nginx
systemctl start nginx

# Add automatic renewal
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -
