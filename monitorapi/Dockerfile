
FROM sstarcher/sensu:1.4.3

## en_US locale ----------------------------------------------------------

RUN apt-get update && apt-get install -y redis-server

ENV REDIS_HOST=sensuredis \
    API_HOST=monitorapi
