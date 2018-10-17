#! /bin/bash

chgrp docker /var/run/docker.sock

cd ~jenkins

cat >jenkins.sh  <<EOF
java -jar "swarm-client-${SWARM_CLIENT_VERSION}.jar"  \
     -master "${JENKINS_URL}"                         \
     -username "${JENKINS_USER}"                      \
     -passwordEnvVariable JENKINS_PASSWORD            \
     -executors "${RHUB_EXECUTORS}"                   \
     -labels "${JENKINS_LABELS}"
EOF

chown jenkins:jenkins jenkins.sh
chmod +x jenkins.sh

su -c ./jenkins.sh jenkins
