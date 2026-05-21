#!/bin/bash
set -e

# Start PHP-FPM in background
php-fpm -D

# Start Apache in foreground
apache2ctl -D FOREGROUND
