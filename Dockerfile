FROM php:7.4-fpm

# System packages
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-fcgid \
    mariadb-server \
    supervisor \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql mbstring zip exif opcache xml

# PHP config (UTF-8)
RUN echo "default_charset = UTF-8" >> /usr/local/etc/php/php.ini \
    && echo "mbstring.internal_encoding = UTF-8" >> /usr/local/etc/php/php.ini

# Apache - event MPM + HTTP/2
RUN a2dismod mpm_prefork \
    && a2enmod mpm_event proxy_fcgi http2 rewrite headers ssl

RUN echo 'AddDefaultCharset UTF-8' >> /etc/apache2/apache2.conf \
    && echo 'ServerName localhost' >> /etc/apache2/apache2.conf \
    && echo 'Protocols h2 h2c http/1.1' >> /etc/apache2/apache2.conf

RUN cat > /etc/apache2/sites-available/000-default.conf <<'EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    Protocols h2c http/1.1

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        Options -Indexes +FollowSymLinks
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

RUN sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/apache2/mods-enabled/dir.conf

# MariaDB config (UTF-8)
RUN echo "[mysqld]" >> /etc/mysql/my.cnf \
    && echo "character-set-server=utf8" >> /etc/mysql/my.cnf \
    && echo "collation-server=utf8_unicode_ci" >> /etc/mysql/my.cnf \
    && echo "default-storage-engine=InnoDB" >> /etc/mysql/my.cnf

# Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /var/www/html
RUN rm -f /var/www/html/index.html

COPY . .

RUN chown -R www-data:www-data /var/www/html

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

CMD ["/docker-entrypoint.sh"]
