FROM php:8.0.24-fpm-buster as laravel_app

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    build-essential \
    mariadb-client \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    nano \
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql zip exif pcntl #mbstring
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ARG PROJECT_NAME

RUN composer create-project laravel/laravel ${PROJECT_NAME}
RUN mv ./${PROJECT_NAME}/* . 

FROM scratch AS export-stage
COPY --from=laravel_app . .

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

RUN chown www:www /var/www/vendor/composer/*

# Change current user to www
USER www

RUN composer update
RUN composer install
RUN composer dump-autoload


# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]