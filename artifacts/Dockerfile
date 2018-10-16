
FROM httpd:2.4.35-alpine

RUN rm /usr/local/apache2/htdocs/index.html

RUN echo "Include conf/extra/artifacts.conf" >> \
    /usr/local/apache2/conf/httpd.conf

COPY artifacts.conf /usr/local/apache2/conf/extra/artifacts.conf
