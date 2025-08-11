


## AMZ Linux 2023 + Kubernetes

### Run all commands in sudo e.g > sudo su

### MASTER

```shell
  sudo su
  sudo swapoff -a
  sudo setenforce 0
  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
  sudo yum update -y
  sudo yum install docker -y
  sudo systemctl enable docker
  sudo systemctl start docker
  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
  [kubernetes]
  name=Kubernetes
  baseurl=https://pkgs.k8s.io/core:/stable:/v1.26/rpm/
  enabled=1
  gpgcheck=1
  gpgkey=https://pkgs.k8s.io/core:/stable:/v1.26/rpm/repodata/repomd.xml.key
  EOF
  sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
  sudo systemctl enable --now kubelet
  sudo kubeadm init > /home/ec2-user/kubernetes-node-config.txt
  export KUBECONFIG=/etc/kubernetes/admin.conf
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```


### You can run it in Terraform scripts like this

```tf
  # User Data: This is the boot script that runs when the instance starts
  user_data = <<-EOT
                #!/bin/bash
                sudo su
                sudo swapoff -a
                sudo setenforce 0
                sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
                sudo yum update -y
                sudo yum install docker -y
                sudo systemctl enable docker
                sudo systemctl start docker
                cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
                [kubernetes]
                name=Kubernetes
                baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
                enabled=1
                gpgcheck=1
                gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
                EOF
                sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
                sudo systemctl enable --now kubelet
                sudo kubeadm init > /home/ec2-user/kubernetes-node-config.txt
                export KUBECONFIG=/etc/kubernetes/admin.conf
                kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
            EOT
```


### After all commands you should see this instruction

```txt
To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.31.2.84:6443 --token 0gnw60.v081dlfr4n9x9mg9 \
        --discovery-token-ca-cert-hash sha256:4a58cd84bac8165ab7b0c4c1b6a29cd062322d5bad9ad3060845bfa89f6cba37
```



### Calico 

- Install Calico , pod network to the cluster. 

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Checking pods from kube-system namespace

```bash
kubectl get pods -n kube-system
```


### Namespaces

- Creating namespaces
```bash
kubectl create namespace infra
kubectl create namespace app
```

- Get namespaces
```bash
kubectl get namespaces
```

- Delete namespaces
```bash
kubectl delete namespace <namespace-name>
```

### Set the Context to a Namespace

- If you want to work within a specific namespace by default for your kubectl commands, you can set the context:

```bash
Copy
kubectl config set-context --current --namespace=<namespace-name>
```

- For example, to switch to the dev namespace:
```bash
kubectl config set-context --current --namespace=dev
```


## Kubernetes WORKER config

### You can run it in Terraform scripts like this

```tf
  # User Data: This is the boot script that runs when the instance starts
  user_data = <<-EOT
                #!/bin/bash
                sudo su
                sudo swapoff -a
                sudo setenforce 0
                sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
                sudo yum update -y
                sudo yum install docker -y
                sudo systemctl enable docker
                sudo systemctl start docker
                cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
                [kubernetes]
                name=Kubernetes
                baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
                enabled=1
                gpgcheck=1
                gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
                EOF
                sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
                sudo systemctl enable --now kubelet
            EOT
```

### Join command

- Run this command in the Master node
```bash
sudo kubeadm token create --print-join-command
```
- After that get result from this command and run in the worker node
```bash
kubeadm join 172.31.2.84:6443 --token 0gnw60.v081dlfr4n9x9mg9 \
        --discovery-token-ca-cert-hash sha256:4a58cd84bac8165ab7b0c4c1b6a29cd062322d5bad9ad3060845bfa89f6cba37
```



## TROUBLESHOOTING 

- Command samples
- See which init container is failing + why

- if you used the "jenkins" namespace, keep -n jenkins; otherwise drop/change it
```bash
kubectl -n jenkins describe pod jenkins-0 | sed -n '/Init Containers:/,/Containers:/p'   # names, exit codes, reasons
kubectl -n jenkins get pod jenkins-0 -o jsonpath='{range .status.initContainerStatuses[*]}{.name}{"  =>  "}{.state.terminated.reason}{" (exit "}{.state.terminated.exitCode}{")\n"}{end}'
```

- Grab the logs for each init container (the chart usually has init and config-reload-init):
```bash
kubectl -n jenkins logs jenkins-0 -c init
kubectl -n jenkins logs jenkins-0 -c config-reload-init
```

- PVC actually bound and RW?
```bash
kubectl -n jenkins get pvc
kubectl -n jenkins describe pvc <jenkins-pvc-name>
```

- Pod events (image pulls, permission errors, etc.)
```bash
kubectl -n jenkins describe pod jenkins-0
```

## StorageClass

Here’s the quick, safe way to remove a StorageClass.

1. See what you have (and which is default)

```bash
kubectl get storageclass
kubectl describe storageclass <name>
```

2. If the class you want to delete is the **default**, unset it (or switch default first)

```bash
# remove the "default" annotation from the current default
kubectl annotate storageclass <old-default> \
  storageclass.kubernetes.io/is-default-class- \
  storageclass.beta.kubernetes.io/is-default-class- --overwrite

# (optional) make another class the default
kubectl annotate storageclass <new-default> \
  storageclass.kubernetes.io/is-default-class=true --overwrite
```

3. Delete the StorageClass

```bash
kubectl delete storageclass <name>
```

### Notes that matter

* StorageClasses are **cluster-scoped** (no namespace).
* Deleting a StorageClass **does not delete existing PVs/PVCs**. Already-bound PVCs keep working.
  PVCs that reference the deleted class and are **not yet bound** will stay **Pending** until you change them.
* You generally **can’t change** `storageClassName` on a **bound** PVC. To move data, create a new PVC (possibly from a snapshot), migrate/copy, then cut over.
* If a **Helm chart** created the StorageClass (e.g., a CSI driver chart), disable its creation in the chart values (look for keys like `storageClass.create` or `storageClasses`) and `helm upgrade` first — otherwise the class may be recreated on the next upgrade.



