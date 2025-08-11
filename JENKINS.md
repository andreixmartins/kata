

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


## Jenkins Persistence


### Create Storage Class

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: manual  # This is the name you're referring to in the PV and PVC
provisioner: kubernetes.io/no-provisioner  # Use "no-provisioner" for static provisioning (manual PV)
volumeBindingMode: WaitForFirstConsumer
```



### Jenkins Persistence Volumes

- Make sure this path /data/jenkins-ax exists

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-ax
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: manual  # Must match the PVC's storageClassName
  local:
    path: /data/jenkins-ax # Adjust to your setup
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - ip-172-31-2-84.sa-east-1.compute.internal  # Replace with your node name
```


### Jenkins Persistence Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-ax
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: manual  # Must match the PV's storageClassName
```
