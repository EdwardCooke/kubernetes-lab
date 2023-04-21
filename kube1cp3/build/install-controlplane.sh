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
    token: uc3v2f.igqmqafg15ghyl45
    apiServerEndpoint: kube1.k8s.lan:6443
    caCertHashes:
    - sha256:3c3cfd0688f30516f5271e1fbad19ffdbd8c8214fbf89fb81562c847119f4ed9
controlPlane:
  certificateKey: 3c22a8f294046bd72a3fb9f0234094983862125e28128811decdddd53eac02e8
' > /root/kubeadm-config.yaml

echo "Joining to the Kubernetes cluster"
kubeadm join --config /root/kubeadm-config.yaml kube1.k8s.lan:6443
touch /home/built