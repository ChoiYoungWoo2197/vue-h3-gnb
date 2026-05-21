#!/bin/bash
set -e

# MariaDB 초기화 (최초 1회)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mysqld_safe --skip-networking &
    sleep 5

    mysql -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS gnuboard CHARACTER SET utf8 COLLATE utf8_unicode_ci;
        CREATE USER IF NOT EXISTS 'gnuboard'@'localhost' IDENTIFIED BY 'gnuboard123';
        GRANT ALL PRIVILEGES ON gnuboard.* TO 'gnuboard'@'localhost';
        FLUSH PRIVILEGES;
EOSQL

    mysqladmin -u root shutdown
    sleep 2
fi

mkdir -p /var/www/html/data
chmod 707 /var/www/html/data

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
