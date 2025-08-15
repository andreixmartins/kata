FROM jenkins/jenkins:lts

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
# Preinstall plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Configuration as code
COPY casc/ /usr/share/jenkins/ref/casc/
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc/jenkins.yaml
