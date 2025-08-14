#!/usr/bin/env bash

echo "Creating Jenkins pipeline" 
JENKINS_URL=http://localhost:8080
USER=admin
PASS=admin

CRUMB=$(curl -s -u "$USER:$PASS" --cookie-jar cookies.txt "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumbRequestField+":"+.crumb')
TOKEN_DATA=$(curl -s -u "$USER:$PASS" --cookie cookies.txt -H "$CRUMB" -X POST "$JENKINS_URL/user/$USER/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" --data 'newTokenName=cli')
TOKEN=$(jq -r '.data.tokenValue' <<<"$TOKEN_DATA")
CRUMB=$(curl -s -u "$USER:$TOKEN" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
curl -u "$USER:$TOKEN" -H "Content-Type: application/xml" --data-binary @boot-chart-job.xml "$JENKINS_URL/createItem?name=boot-chart-job"

echo "Creating Jenkins credentials"
curl -u "$USER:$TOKEN" -H 'Content-Type: application/xml' ${CRUMB:+-H "$CRUMB"} --data-binary @dockerhub-creds.xml "$JENKINS_URL/credentials/store/system/domain/_/createCredentials"

echo "Trigger job" 
# curl -u "$USER:$TOKEN" -X POST "$JENKINS_URL/job/boot-chart-job/build"
