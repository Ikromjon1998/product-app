FROM php:8.3.3-alpine

ARG COMPOSER_VERSION=2.7.1
ARG XDEBUG_VERSION=3.3.1
ARG TARGET=production

RUN apk add --no-cache \
    postgresql-dev \
    postgresql-client \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    mysql-client \
    shadow \
    git \
    gmp-dev \
    gdal-tools \
    gdal-driver-PG \
    xz \
    $PHPIZE_DEPS && \
    pear update-channels && \
    pecl update-channels && \
    NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
    pecl install openswoole redis && \
    docker-php-ext-enable openswoole redis && \
    curl https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar -o /usr/bin/composer && \
    chmod +x /usr/bin/composer && \
    mkdir -p /var/www/backup /.config/ && \
    docker-php-ext-configure gd --with-jpeg --with-webp && \
    docker-php-ext-install -j${NPROC} pdo_pgsql pdo_mysql zip gd pcntl bcmath gmp calendar && \
    sed -i 's|www-data:/sbin/nologin|www-data:/bin/sh|g' /etc/passwd && \
    chown -R www-data:www-data /var/www /.config/

CMD ["php","artisan","octane:start", "--host", "0.0.0.0"]

WORKDIR /var/www/html

RUN if [ "${TARGET}" != "production" ]; then \
        apk add --no-cache \
            linux-headers \
            nodejs && \
        pecl install xdebug-${XDEBUG_VERSION} && \
        docker-php-ext-enable xdebug; \
    else \
        echo "Building production"; \
    fi

RUN mkdir -p /.config/psysh
RUN chmod -R 755 /.config
RUN chown -R 1000:1001 /.config

USER www-data
COPY --chown=www-data:www-data . /var/www/html
