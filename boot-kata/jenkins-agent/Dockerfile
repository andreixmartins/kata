FROM jenkins/inbound-agent:latest-jdk21

USER root

# Maven required for Jenkins agent pipeline
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y maven && mvn -v

# Git installation required for Jenkins agent pipeline
RUN apt-get install -y git

# Helm installation required to deploy new boot-chart app in kuebernetes namespace infra
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Podman installation required to build and push image to Docker hub
# We could use kaniko instead of Podman
RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg2 lsb-release software-properties-common
RUN apt-get update
RUN apt-get install -y podman
