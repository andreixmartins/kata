

# HOW to install Kubernetes cluster local


# Minikube 
brew install minikube

brew install kubernetes-cli

minikube config set driver docker

minikube addons enable ingress

minikube stop

minikube delete && minikube start --driver=docker --cpus=4 --memory=8192

minikube ssh -- nproc

minikube ssh -- grep MemTotal /proc/meminfo


# Create namespaces
kubectl create namespace infra

kubectl create namespace app


# Helm
brew install helm

helm version

#Jenkins
helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install jenkins jenkins/jenkins -n infra

kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

kubectl port-forward svc/jenkins --namespace infra 8080:8080

#Jenkins pipeline

JENKINS_URL=http://localhost:8080
USER=admin
PASS=admin

CRUMB=$(curl -s -u "$USER:$PASS" --cookie-jar cookies.txt "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumbRequestField+":"+.crumb')

TOKEN_DATA=$(curl -s -u "$USER:$PASS" --cookie cookies.txt -H "$CRUMB" -X POST "$JENKINS_URL/user/$USER/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" --data 'newTokenName=cli')

TOKEN=$(jq -r '.data.tokenValue' <<<"$TOKEN_DATA")

CRUMB=$(curl -s -u "$USER:$TOKEN" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

curl -u "$USER:$TOKEN" -H "Content-Type: application/xml" --data-binary @boot-chart-job.xml "$JENKINS_URL/createItem?name=boot-chart-job"

curl -u "$USER:$TOKEN" -X POST "$JENKINS_URL/job/boot-chart-job/build"






