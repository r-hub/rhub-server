
FROM jenkins/jenkins:2.146

USER root

RUN echo "deb http://cloud.r-project.org/bin/linux/debian stretch-cran35/" \
    > /etc/apt/sources.list.d/cran.list

RUN apt-key adv --keyserver keys.gnupg.net \
    --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'

RUN apt-get update && apt-get install -y \
    r-base-core r-base-dev

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Jenkins is fully configured, no configure wizard, please
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
RUN echo 2.146 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
RUN echo 2.146 > /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion

COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY config.groovy /usr/share/jenkins/ref/init.groovy.d/
