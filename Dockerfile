FROM php:8.3-fpm-alpine3.22

RUN apk add --no-cache \
    curl \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    npm \
 && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip \
 && curl -L https://github.com/git/git/archive/refs/tags/v2.50.1.tar.gz | tar -xz -C /tmp \
 && cd /tmp/git-2.50.1 \
 && make prefix=/usr/local all install \
 && git --version \
 && rm -rf /tmp/git-2.50.1

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV COMPOSER_PROCESS_TIMEOUT=2000
ENV COMPOSER_CURL_TIMEOUT=300
ENV COMPOSER_DISABLE_NETWORK_TIMEOUT=1

ARG GITHUB_TOKEN
RUN if [ -n "$COMPOSER_GITHUB_TOKEN" ]; then composer config --global github-oauth.github.com "$COMPOSER_GITHUB_TOKEN"; fi \
 && composer config --global secure-http false

WORKDIR /var/www

COPY . .

RUN ls -la /var/www \
 && cat /var/www/artisan

RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
 && npm install \
 && npm run build \
 && chown -R www-data:www-data /var/www \
 && chmod -R 755 /var/www/storage

EXPOSE 9000

CMD ["php-fpm"]