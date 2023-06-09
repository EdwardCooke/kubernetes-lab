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
    token: waf4gq.d9cwzrokwe42q34j
    apiServerEndpoint: kube2.k8s.lan:6443
    caCertHashes:
    - sha256:6f408cdddd44b1014b4671564d630b6d7d4911a8fe991c9cde061628396d7bb3
controlPlane:
  certificateKey: 876cb98c087adaa5175e3b98a4c96069b4ad674e7b32a8a6d931bd7426d9dc2b
' > /root/kubeadm-config.yaml

echo "Joining to the Kubernetes cluster"
kubeadm join --config /root/kubeadm-config.yaml kube2.k8s.lan:6443
touch /home/built
