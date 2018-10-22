
FROM nginx:1.15.5-alpine

RUN rm -rf /etc/nginx/conf.d/* /etc/nginx/nginx.conf

RUN mkdir /artifacts && chown nginx:nginx /artifacts

COPY wait-for /usr/local/bin/wait-for

RUN chown root:root /usr/local/bin/wait-for && \
    chmod 755 /usr/local/bin/wait-for

RUN apk add --no-cache gettext

COPY nginx.conf.in /etc/nginx/nginx.conf.in
COPY nginx.conf.https.in /etc/nginx/nginx.conf.https.in
COPY entrypoint.sh /entrypoint.sh
