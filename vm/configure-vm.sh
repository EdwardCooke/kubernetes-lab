#!/bin/bash
sudo apt update
sudo apt upgrade -y

echo "Building the certificates chain"
scripts/make-certs.sh

echo "Installing cloud-init"
sudo apt install -y cloud-init

echo "Installing libvirt/kvm"
sudo apt install -y genisoimage qemu-kvm libvirt-dev bridge-utils libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin libguestfs-tools virt-top virt-manager
(grep LIBVIRT ~/.bashrc > /dev/null) || (echo 'LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.profile)
echo vhost_net | sudo tee /etc/modules-load.d/vhost_net.conf
sudo modprobe vhost_net
sudo virsh -c qemu:///system net-autostart default

echo "Installing bind"
sudo apt install -y bind

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

KUBEVER=`curl \
        https://apt.kubernetes.io//dists/kubernetes-xenial/main/binary-amd64/Packages.gz -L --output - \
        | zcat \
        | grep -A 1 -B 0 "Package: kubelet" \
        | grep Version \
        | sed 's/Version: //' \
        | tail -1 \
        | sed 's/\./\\\./g'`


echo "Pull the kubernetes ubuntu repository, version $KUBEVER"
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
    --include-field 'Package=(kubernetes-cni)|(cri-tools)' \
    --exclude-field=Version=.* \
    --include-field=Version=.*$KUBEVER.* \
    --ignore-release-gpg

echo "127.0.1.1 kubernetes.k8s.lan" | sudo tee -a /etc/hosts

# load kubernetes images
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] http://kubernetes.k8s.lan/kubernetes kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubeadm
sudo systemctl disable kubelet
for x in `kubeadm config images list 2> /dev/null`
do
    sudo docker image pull $x
    NEWTAG=`echo $x | sed 's/registry.k8s.io/kubernetes.k8s.lan/'`
    sudo docker image tag $x $NEWTAG
    sudo docker image push $NEWTAG
done

# Configure ssh key
mkdir ~/.ssh
chmod 750 ~/.ssh
ssh-keygen -f ~/.ssh/vm -N ""

echo "
Host 192.168.122.254
    User lab
    StrictHostKeyChecking no
    IdentityFile ~/.ssh/vm
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

echo "Installing helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Installing kustomize"
curl https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | sudo bash /dev/stdin /usr/bin

echo "Adding bash completions"
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
kubectl completion bash | sudo tee $COMPDIR/kubectl > /dev/null
helm completion bash | sudo tee $COMPDIR/helm > /dev/null

echo "Installing kubectx and kubens"
git clone https://github.com/ahmetb/kubectx kubectx
sudo cp kubectx/kubectx /usr/local/bin
sudo cp kubectx/kubens /usr/local/bin
sudo cp kubectx/completion/kubens.bash $COMPDIR/kubens
sudo cp kubectx/completion/kubectx.bash $COMPDIR/kubectx
rm -rf kubectx

