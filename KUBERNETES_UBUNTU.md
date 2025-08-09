
## AMZ Linux + Kubernetes


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
