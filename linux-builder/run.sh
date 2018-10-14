#! /bin/bash

cd ~

java -jar "swarm-client-${SWARM_CLIENT_VERSION}.jar"  \
     -master "${JENKINS_URL}"                         \
     -username "${JENKINS_USER}"                      \
     -passwordEnvVariable JENKINS_PASSWORD            \
     -executors "${RHUB_EXECUTORS}"                   \
     -labels "${JENKINS_LABELS}"
