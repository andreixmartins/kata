
## AMZ Linux + Kubernetes

> run all commands in sudo e.g > sudo su


  user_data = <<-EOT
                #!/bin/bash
                sudo su
                sudo swapoff -a
                sudo setenforce 0
                sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
                sudo yum update -y
                sudo yum install docker -y
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
            EOT




mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


export KUBECONFIG=$HOME/.kube/config



Run the following command to view the logs of the kubelet:

bash
Copy
sudo journalctl -u kubelet -f







Step 2: Apply changes
After editing your kubeconfig, reload the configuration to ensure the changes take effect:

bash
Copy
export KUBEV2_CONFIG=$HOME/.kube/config


restarting the kubelet service, which should start the API server:

bash
Copy
sudo systemctl restart kubelet




Check the status of the pods in the kube-system namespace:

bash
Copy
kubectl get pods -n kube-system



kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml



