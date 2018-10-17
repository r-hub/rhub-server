
FROM nginx:1.15.5-alpine

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir /artifacts && chown nginx:nginx /artifacts

COPY wait-for /usr/local/bin/wait-for

RUN chown root:root /usr/local/bin/wait-for && \
    chmod 755 /usr/local/bin/wait-for
