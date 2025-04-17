#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
export COMPOSER_ALLOW_SUPERUSER=1

# Mettre a jour les paquets
echo "update distribution..."
apt-get update && apt-get install -y apt-utils && apt-get upgrade -y

# install git et autres logiciels
echo "install packages..."
apt-get install -y wget git ntp ntpdate sudo nano curl cron rsyslog logrotate unzip

# Synchro horloge
echo "synchro horloge..."
/etc/init.d/ntp restart
cp /etc/localtime /etc/localtime.bak
cp /usr/share/zoneinfo/Europe/Paris /etc/localtime
date

#Install nginx
echo "Install nginx..."
apt-get install nginx -y
cp "/.deploy/nginx/default.conf" /etc/nginx/sites-available/default
cp "/.deploy/nginx/nginx.conf" /etc/nginx/nginx.conf

#Install php-fpm
echo "Install php..."
apt-get install -y build-essential lsb-release ca-certificates apt-transport-https software-properties-common memcached libmemcached-tools zlib1g-dev
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
apt-get update && apt-get install -y openssl php8.2 php8.2-common php8.2-fpm php-pear php8.2-dev php8.2-memcached php8.2-curl php8.2-bcmath php8.2-ctype php8.2-fileinfo php8.2-mbstring php8.2-mysql php8.2-sqlite3 php8.2-xml php8.2-zip php8.2-tokenizer php8.2-gd php8.2-imagick \
&& pecl channel-update pecl.php.net \
&& pecl install memcached redis mongodb xdebug \
&& touch /etc/php/8.2/mods-available/memcached.ini && echo extension=memcached.so > /etc/php/8.2/mods-available/memcached.ini \
&& ln -s /etc/php/8.2/mods-available/memcached.ini /etc/php/8.2/fpm/conf.d/memcached.ini \
&& ln -s /etc/php/8.2/mods-available/memcached.ini /etc/php/8.2/cli/conf.d/memcached.ini \
&& touch /etc/php/8.2/mods-available/redis.ini && echo extension=redis.so > /etc/php/8.2/mods-available/redis.ini \
&& ln -s /etc/php/8.2/mods-available/redis.ini /etc/php/8.2/fpm/conf.d/redis.ini \
&& ln -s /etc/php/8.2/mods-available/redis.ini /etc/php/8.2/cli/conf.d/redis.ini \
&& touch /etc/php/8.2/mods-available/mongodb.ini && echo extension=mongodb.so > /etc/php/8.2/mods-available/mongodb.ini \
&& ln -s /etc/php/8.2/mods-available/mongodb.ini /etc/php/8.2/fpm/conf.d/mongodb.ini \
&& ln -s /etc/php/8.2/mods-available/mongodb.ini /etc/php/8.2/cli/conf.d/mongodb.ini \
&& touch /etc/php/8.2/mods-available/xdebug.ini && echo zend_extension=xdebug.so > /etc/php/8.2/mods-available/xdebug.ini \
&& ln -s /etc/php/8.2/mods-available/xdebug.ini /etc/php/8.2/fpm/conf.d/xdebug.ini \
&& ln -s /etc/php/8.2/mods-available/xdebug.ini /etc/php/8.2/cli/conf.d/xdebug.ini

#Install composer
echo "Install composer..."
curl -sS https://getcomposer.org/installer -o composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
composer -V
rm composer-setup.php

#Clean
rm -r /var/lib/apt/lists/* && apt-get autoremove -y && apt-get clean all

#Default user
groupadd --gid 1001 debian && useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash debian
echo debian:debian | chpasswd
echo "%debian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
chown -R debian:debian /root
chown -R debian:debian /var/www/html
echo "alias ls='ls -alh'" >> /home/debian/.bashrc
echo "alias lh='ls'" >> /home/debian/.bashrc

#Cron & Logrotate
cp "/.deploy/logrotate/logrotate_nginx.conf" /etc/logrotate.d/nginx
cp "/.deploy/logrotate/logrotate_laravel.conf" /etc/logrotate.d/laravel
chown -R root:debian /var/log/nginx
chmod -R 775 /var/log/nginx

mkdir -p /var/log/laravel
chown -R root:debian /var/log/laravel
chmod -R 775 /var/log/laravel

crontab -u root -l > /tmp/mycron
echo "0 0 * * * /usr/sbin/logrotate -f /etc/logrotate.conf" >> /tmp/mycron
echo "* * * * * /usr/bin/php /var/www/html/artisan schedule:run >> /var/log/cron.log 2>&1" >> /tmp/mycron
crontab -u root /tmp/mycron
rm /tmp/mycron
echo "Cron install done."

