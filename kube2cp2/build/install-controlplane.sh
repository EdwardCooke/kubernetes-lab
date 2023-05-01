#!/bin/bash

echo "Configuring nftables"
echo "
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
" > /etc/sysctl.d/k8s.conf
sysctl --system

echo "Bringing in required kernel modules overlay, br_netfilter"
echo "
overlay
br_netfilter
" > /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

echo "Configuring apt repositories"
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] http://kubernetes.k8s.lan/docker jammy stable" > /etc/apt/sources.list.d/docker.list

curl -fsSLo /etc/apt/keyrings/kubernetes.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] http://kubernetes.k8s.lan/kubernetes kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

echo "Installing containerd, kubelet, kubeadm and kubectl"
apt-get update
apt-get install -y containerd.io
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "iptables alternatives"
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

echo "Configuring containerd"
echo 'version = 2
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true' > /etc/containerd/config.toml
systemctl restart containerd

#========
echo "Configuring kubeadm"
echo '
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: abhu4i.4h6lg4pppy9x7t12
    apiServerEndpoint: kube2.k8s.lan:6443
    caCertHashes:
    - sha256:5368fbe4f1cfe4f8029f10a1a84e46c23d701b91851ed4f2dfe11b41dd332c33
controlPlane:
  certificateKey: c37193628b9c9b615bd430fbe7504f4a8878f4dec83e51dddcd0eac1fdea9143
' > /root/kubeadm-config.yaml

echo "Joining to the Kubernetes cluster"
kubeadm join --config /root/kubeadm-config.yaml kube2.k8s.lan:6443
touch /home/built
