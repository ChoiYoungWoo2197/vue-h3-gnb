#!/bin/bash
set -e

DB_NAME=${DB_NAME:-gnuboard}
DB_USER=${DB_USER:-gnuboard}
DB_PASS=${DB_PASS:-gnuboard123}

# MariaDB 초기화 (최초 1회)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mysqld_safe --skip-networking &

    # MariaDB 준비 완료까지 대기 (최대 30초)
    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    mysql -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_unicode_ci;
        CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
        GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
        FLUSH PRIVILEGES;
EOSQL

    mysqladmin -u root shutdown
    sleep 2
fi

mkdir -p /var/www/html/data
chmod 707 /var/www/html/data

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
