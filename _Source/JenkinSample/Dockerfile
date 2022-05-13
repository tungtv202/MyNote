FROM jenkins/jenkins:2.319.3-lts-jdk11

USER jenkins

ARG JAVA_OPTS
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false ${JAVA_OPTS:-}"

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

COPY jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml

COPY jobs /usr/share/jenkins/ref/jobs/

# Configuration AS Code env variable
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/
