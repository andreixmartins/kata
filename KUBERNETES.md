


## AMZ Linux 2023 + Kubernetes

### Run all commands in sudo e.g > sudo su


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


