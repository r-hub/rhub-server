
FROM sstarcher/sensu:1.4.3

## Redis -----------------------------------------------------------------

RUN apt-get update && apt-get install -y redis-server

## Compilers -------------------------------------------------------------

RUN apt-get install -y g++ make

## Docker to monitor Docker ----------------------------------------------

RUN apt-get install -y apt-transport-https \
    ca-certificates wget software-properties-common gnupg

RUN curl https://download.docker.com/linux/debian/gpg | \
    apt-key add -

RUN echo "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | \
    tee -a /etc/apt/sources.list.d/docker.list

RUN apt-get update && \
    apt-get -y install docker-ce

## Plugins ---------------------------------------------------------------

RUN sensu-install -p sensu-plugins-http
RUN sensu-install -p sensu-plugins-disk-checks
RUN sensu-install -p sensu-plugins-cpu-checks
RUN sensu-install -p sensu-plugins-docker

## Config

ENV REDIS_HOST=sensuredis \
    CLIENT_NAME=central \
    CLIENT_ADDRESS=127.0.0.1 \
    CLIENT_SUBSCRIPTIONS="centralized,default"
