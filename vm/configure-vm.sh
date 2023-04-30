#!/bin/bash
sudo apt update
sudo apt upgrade -y

echo "Building the certificates chain"
pushd ..
mkdir -p ca
openssl genrsa -out ca/ca.key 4096
openssl req -x509 -new -nodes -key ca/ca.key -sha256 -days 3650 -out ca/ca.crt -subj '/CN=k8s.lan root/C=US/ST=Utah/L=West Jodan/O=k8s.lan'
echo "[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
prompt = no
[req_distinguished_name]
C   = US
ST  = Utah
L   = West Jordan
O   = k8s.lan
CN  = *.k8s.lan
[req_ext]
subjectAltName = @alt_names
[alt_names]
IP.1 = 192.168.122.254
IP.2 = 192.168.122.200
IP.3 = 192.168.122.201
IP.4 = 192.168.122.202
IP.5 = 192.168.122.210
IP.6 = 192.168.122.211
IP.7 = 192.168.122.212
IP.8 = 192.168.122.213
IP.9 = 192.168.122.214
IP.10 = 192.168.122.215
IP.11 = 192.168.122.220
IP.12 = 192.168.122.221
IP.13 = 192.168.122.222
IP.14 = 192.168.122.223
IP.15 = 192.168.122.224
IP.16 = 192.168.122.225
DNS.1 = *.kube1.clusters.k8s.lan
DNS.2 = *.kube2.clusters.k8s.lan
DNS.3 = *.kube.clusters.k8s.lan
DNS.4 = *.k8s.lan" > ca/wildcard.openssl.conf
openssl genrsa -out ca/wildcard.key 4096
openssl req -new -key ca/wildcard.key -out ca/wildcard.csr -config ca/wildcard.openssl.conf
openssl x509 -req -days 365 -in ca/wildcard.csr -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial -out ca/wildcard.crt -extensions req_ext -extfile ca/wildcard.openssl.conf
sudo cp ca/ca.crt /usr/local/share/ca-certificates/k8slan.crt
sudo cp ca/wildcard.crt /etc/ssl/private
sudo cp ca/wildcard.key /etc/ssl/private
sudo update-ca-certificates
popd

echo "Installing cloud-init"
sudo apt install -y cloud-init

echo "Installing libvirt/kvm"
sudo apt install -y genisoimage qemu-kvm libvirt-dev bridge-utils libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin libguestfs-tools virt-top
(grep LIBVIRT ~/.bashrc > /dev/null) || (echo 'LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.profile)
echo vhost_net | sudo tee /etc/modules-load.d/vhost_net.conf
sudo modprobe vhost_net
virsh net-autostart default

echo "Installing docker"
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg
sudo install -m 0755 -d /etc/apt/keyrings
[ -f /etc/apt/keyrings/docker.gpg ] && sudo rm /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Usermodding myself to docker"
sudo usermod -a -G docker $(whoami)
echo "Adding group to current session"

echo "Setup the registry"
sudo docker compose up -d
sleep 10

echo "Pull the docker ubuntu repository"
sudo apt install -y debmirror
sudo mkdir /opt/debmirror
sudo chown $(whoami):$(whoami) /opt/debmirror

debmirror /opt/debmirror/docker \
    --nosource \
    --host=download.docker.com \
    --root=/linux/ubuntu \
    --dist=jammy \
    --section=stable \
    --i18n \
    --arch=amd64 \
    --passive \
    --cleanup \
    --method=https \
    --progress \
    --rsync-extra=none \
    --ignore-release-gpg

echo "Pull the kubernetes ubuntu repository"
debmirror /opt/debmirror/kubernetes \
    --nosource \
    --host=apt.kubernetes.io \
    --root=/ \
    --dist=kubernetes-xenial \
    --section=main \
    --i18n \
    --arch=amd64 \
    --passive \
    --cleanup \
    --method=https \
    --progress \
    --rsync-extra=none \
    --ignore-release-gpg

echo "127.0.1.1 kubernetes.k8s.lan" | sudo tee -a /etc/hosts

# load kubernetes images
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] http://kubernetes.k8s.lan/kubernetes kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubeadm
sudo systemctl disable kubelet
for x in `kubeadm config images list 2> /dev/null`
do
    docker image pull $x
    NEWTAG=`echo $x | sed 's/registry.k8s.io/kubernetes.k8s.lan/'`
    docker image tag $x $NEWTAG
    docker image push $NEWTAG
done

# Configure ssh key
mkdir ~/.ssh
chmod 750 ~/.ssh
ssh-keygen -f ~/.ssh/vm -N ""

echo "
Host *.k8s.lan
    User lab
    StrictHostKeyChecking no
    IdentityFile ~/.ssh/vm
" | sudo tee -a ~/.ssh/config

echo "Download the jammy iso"
sudo mkdir /opt/vms
sudo chmod 777 -R /opt/vms
curl https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img --output /opt/vms/jammy-server-cloudimg-amd64.img

sudo iptables -A FORWARD -j ACCEPT
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/10-kuberneteslab.conf > /dev/null
echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
