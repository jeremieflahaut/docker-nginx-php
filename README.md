# nginx-php

![example workflow](https://github.com/jeremieflahaut/docker-nginx-php/actions/workflows/master.yml/badge.svg)

Docker image with nginx & php-fpm ready for Laravel project

### Github
[Code source](https://github.com/jeremieflahaut/docker-nginx-php)

### docker-compose

```
version: '3.8'

services:
  web:
    container_name: ${COMPOSE_PROJECT_NAME}_web
    image: jflahaut/nginx-php
    environment: 
      - USER_ID=${USER_ID:-0}
      - GROUP_ID=${GROUP_ID:-0}
    volumes:
      - ./app/html:/var/www/html
    networks:
      - network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.web.rule=Host(`localhost`)"
 
networks:
  network:
    external: true
    name: network
```
