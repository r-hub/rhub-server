
FROM jenkins/jenkins:2.161

## Azure CLI, this is not always needed, but it does not hurt now...

USER root

RUN apt-get update
RUN apt-get install -y apt-transport-https lsb-release \
    software-properties-common dirmngr
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
    --keyserver packages.microsoft.com \
    --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
RUN apt-get update && apt-get install -y azure-cli

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Jenkins is fully configured, no configure wizard, please
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
RUN echo 2.146 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
RUN echo 2.146 > /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion

COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY config.groovy /usr/share/jenkins/ref/init.groovy.d/

