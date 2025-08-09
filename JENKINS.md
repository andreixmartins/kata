

## Install Jenkins using HELM

To install Jenkins using Helm, follow these steps:


### Step 1: Add the Jenkins Helm Chart Repository

Add the Jenkins official Helm chart repository:

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

### Step 3: Install Jenkins

To install Jenkins in the default namespace, run the following command:

```bash
helm install jenkins jenkins/jenkins
```

If you want to install Jenkins in a specific namespace, create the namespace first (if it doesn't exist) and then install Jenkins:

```bash
kubectl create namespace jenkins
helm install jenkins jenkins/jenkins --namespace infra
```

### Step 4: Access Jenkins

To get the Jenkins password, run:

```bash
kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```

To access the Jenkins UI, you can port-forward the service:

```bash
kubectl port-forward svc/jenkins --namespace infra 8080:8080
```
Now you can access Jenkins at [http://localhost:8080](http://localhost:8080).

