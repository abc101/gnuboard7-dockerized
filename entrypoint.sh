#!/bin/bash

# Stop on error
set -e

mkdir -p "$HOME/.npm"

# Copy .env file if it doesn't exist
if [ ! -f /var/www/html/.env ]; then
    echo ".env 파일 생성 중..."
    if [ -f /var/www/html/.env.example ]; then
        cp /var/www/html/.env.example /var/www/html/.env
    else
        echo "❌ /var/www/html/.env.example not found."
        echo "❌ GnuBoard app environment template is missing."
        exit 1
    fi
fi

# Update .env with environment variables if they are set
[ ! -z "$REDIS_PASSWORD" ] && sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=\"$REDIS_PASSWORD\"/" /var/www/html/.env
[ ! -z "$REDIS_HOST" ] && sed -i "s/^REDIS_HOST=.*/REDIS_HOST=\"$REDIS_HOST\"/" /var/www/html/.env
[ ! -z "$SESSION_DRIVER" ] && sed -i "s/^SESSION_DRIVER=.*/SESSION_DRIVER=\"$SESSION_DRIVER\"/" /var/www/html/.env
[ ! -z "$CACHE_STORE" ] && sed -i "s/^CACHE_STORE=.*/CACHE_STORE=\"$CACHE_STORE\"/" /var/www/html/.env

# Install dependencies if vendor directory doesn't exist
if [ ! -f "/var/www/html/vendor/autoload.php" ]; then
    echo "📦 Dependencies not found. Running composer install..."
    composer install --no-interaction --optimize-autoloader --no-dev
fi

# Set permissions for storage and cache directories (use sudo if not running as root)
if [ -d "/var/www/html/vendor" ]; then
    # Set permissions for storage and cache directories
    grep -q "APP_KEY=base64" /var/www/html/.env || php artisan key:generate
    
    php artisan cache:clear
    php artisan config:clear
fi

exec "$@"
