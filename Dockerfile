FROM nginx
MAINTAINER Aaron Brown <aaron+docker@9minutesnooze.com>

COPY _site /usr/share/nginx/html
EXPOSE 80
