FROM php:8.3-apache

ENV EXT="mysqli pdo_mysql zip gd mbstring opcache intl"

RUN apt-get update && apt-get install -y \
    nano \
    rsync \
    unzip \
    openssh-client \
    libzip-dev \
    libonig-dev \
    libfreetype-dev \
    libjpeg-dev \
    libpng-dev \
    libwebp-dev \
    libicu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install -j$(nproc) ${EXT} \
  && a2enmod rewrite \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y openssl \
  && a2enmod ssl \
  && mkdir -p /etc/apache2/ssl \
  && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/apache2/ssl/selfsigned.key \
    -out /etc/apache2/ssl/selfsigned.crt \
    -subj "/CN=localhost" \
  && echo "<VirtualHost *:443>\n\
    ServerName localhost\n\
    DocumentRoot /var/www/public_html\n\
    SSLEngine on\n\
    SSLCertificateFile /etc/apache2/ssl/selfsigned.crt\n\
    SSLCertificateKeyFile /etc/apache2/ssl/selfsigned.key\n\
    <Directory /var/www/public_html>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
  </VirtualHost>" > /etc/apache2/sites-available/default-ssl.conf \
  && a2ensite default-ssl.conf

RUN sed -ri -e 's!/var/www/html!/var/www/public_html!g' /etc/apache2/sites-available/*.conf \
  /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
  && rm -rf /var/www/html \
  && mkdir -p /var/www/public_html

ADD https://github.com/composer/composer/releases/latest/download/composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

WORKDIR /var/www/public_html

CMD ["apache2-foreground"]
