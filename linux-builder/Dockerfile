
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

# en_US locale
RUN apt-get update && \
    apt-get install -y locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# R

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" \
    > /etc/apt/sources.list.d/cran.list

RUN apt-get install -yy default-jre-headless gnupg curl wget

RUN apt-key adv --keyserver keyserver.ubuntu.com \
    --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

RUN apt-get update && apt-get install -yy \
    r-base-core r-base-dev

RUN useradd jenkins && \
    mkdir /home/jenkins && \
    chown jenkins:jenkins /home/jenkins && \
    addgroup jenkins staff

RUN apt-get install -yy docker.io
RUN addgroup jenkins docker

RUN apt-get clean

ENV SWARM_CLIENT_VERSION 3.9

RUN curl -s https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}.jar -o /home/jenkins/swarm-client-${SWARM_CLIENT_VERSION}.jar

# Somewhat surprisingly, this persist after mounting the socket, so
# the jenkins user will have access to Docker
RUN touch /var/run/docker.sock && \
    chown root:docker /var/run/docker.sock

RUN mkdir /artifacts && \
    chown jenkins:jenkins /artifacts

COPY run.sh /home/jenkins/run.sh
RUN chmod +x /home/jenkins/run.sh

RUN rm -rf /var/lib/apt/lists/*

USER jenkins

# Get R packages we need

RUN R -q -e 'source("https://install-github.me/r-hub/sysreqs")'

# Need to switch back to root, because we need to change the group of
# the docker socket, to be able to start sibling containers
# run.sh will do su to start the jenkins swarm client as non-root

USER root

CMD [ "/home/jenkins/run.sh" ]
