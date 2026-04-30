# Dockerfile
FROM php:8.3-fpm

# 필수 패키지 및 누락된 확장 모듈용 시스템 의존성 설치
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    zip unzip git curl mariadb-client \
    libmagickwand-dev \
    libicu-dev \
    libldap2-dev \
    libmemcached-dev zlib1g-dev

# PHP 내장 확장 모듈 설치 (gd, intl, ldap 등)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql zip exif pcntl bcmath intl ldap

# PECL을 통한 확장 모듈 설치 (redis, imagick, memcached)
RUN pecl install redis imagick memcached \
    && docker-php-ext-enable redis imagick memcached

# Composer 설치
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Node.js 20 설치
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

ARG UID=1000
ARG GID=1000
ARG USERNAME=g7user

RUN groupadd -g ${GID} ${USERNAME} \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

ENV HOME=/home/${USERNAME}
ENV npm_config_cache=/home/${USERNAME}/.npm

RUN mkdir -p /home/${USERNAME}/.npm /var/www/html \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} /var/www/html

ENV COMPOSER_HOME=/home/${USERNAME}/.composer
ENV npm_config_cache=/home/${USERNAME}/.npm

RUN mkdir -p /home/${USERNAME}/.composer /home/${USERNAME}/.npm \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

RUN sed -i "s/^user = .*/user = ${USERNAME}/" /usr/local/etc/php-fpm.d/www.conf \
 && sed -i "s/^group = .*/group = ${USERNAME}/" /usr/local/etc/php-fpm.d/www.conf \
 && sed -i "s/^listen.owner = .*/listen.owner = ${USERNAME}/" /usr/local/etc/php-fpm.d/www.conf \
 && sed -i "s/^listen.group = .*/listen.group = ${USERNAME}/" /usr/local/etc/php-fpm.d/www.conf
 
WORKDIR /var/www/html