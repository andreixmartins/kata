#!/usr/bin/env bash

echo "Remove jenkins container"
./cleanup.sh

echo "Building Jenkins image"
docker info >/dev/null 2>&1 && echo "Docker engine is RUNNING" || echo "Docker engine is NOT reachable"
docker build -t ax-jenkins:lts .
docker run -d --name jenkins -p 8888:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home ax-jenkins:lts

echo "Check if jenkins is healthy"
./health-check.sh

echo "Creating Jenkins kata-bootstrap job" 
JENKINS_URL=http://localhost:8888
USER=admin
PASS=admin

CRUMB=$(curl -s -u "$USER:$PASS" --cookie-jar cookies.txt "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumbRequestField+":"+.crumb')
TOKEN_DATA=$(curl -s -u "$USER:$PASS" --cookie cookies.txt -H "$CRUMB" -X POST "$JENKINS_URL/user/$USER/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" --data 'newTokenName=cli')
TOKEN=$(jq -r '.data.tokenValue' <<<"$TOKEN_DATA")
CRUMB=$(curl -s -u "$USER:$TOKEN" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# jenkins-bootstrap-k8s-job
curl -u "$USER:$TOKEN" -H "Content-Type: application/xml" --data-binary @jenkins-bootstrap-k8s-job.xml "$JENKINS_URL/createItem?name=kata-k8s-bootstrap"

# jenkins-deploy-app-job.xml
curl -u "$USER:$TOKEN" -H "Content-Type: application/xml" --data-binary @jenkins-deploy-app-job.xml "$JENKINS_URL/createItem?name=kata-deploy-app"

# jenkins-rollback-app-job.xml
curl -u "$USER:$TOKEN" -H "Content-Type: application/xml" --data-binary @jenkins-rollback-app-job.xml "$JENKINS_URL/createItem?name=kata-rollback-app"

echo "Trigger kata-bootstrap" 
# curl -u "$USER:$TOKEN" -X POST "$JENKINS_URL/job/kata-k8s-bootstrap/build"