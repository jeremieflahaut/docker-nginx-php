FROM debian:buster-slim

COPY .deploy /.deploy

COPY startup.sh /var/bin/startup.sh

RUN /.deploy/create-container.sh

EXPOSE 80

USER debian

WORKDIR /var/www/html

CMD ["/var/bin/startup.sh"]