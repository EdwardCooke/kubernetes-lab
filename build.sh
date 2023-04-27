#!/bin/bash

[ -z $1 ] && USAGE=1
[ -z $2 ] && USAGE=1

[ "$USAGE" == "1" ] && echo "build.sh <name> <memory megabytes>" && exit 1

[ ! -d $1 ] && echo "Configuration for $1 does not exist" && exit 1

cd $1
echo Creating vm directory
sudo mkdir -p /opt/vms/$1
[ -f /opt/vms/$1/cidata.iso ] && sudo rm /opt/vms/$1/cidata.iso
[ -f compile.sh ] && ./compile.sh
sudo chmod 777 -R /opt/vms/$1
qemu-img create -b ../jammy-server-cloudimg-amd64.img -f qcow2 -F qcow2 /opt/vms/$1/$1.img 50G
genisoimage -output /opt/vms/$1/cidata.iso -V cidata -r -J cidata/*
virt-install --name=$1 \
             --ram=$2 \
             --vcpus=2 \
             --import \
             --disk path=/opt/vms/$1/$1.img,format=qcow2 \
             --disk path=/opt/vms/$1/cidata.iso,device=cdrom \
             --os-variant=ubuntu20.10 \
             --network network=default,model=virtio \
             --graphics vnc,listen=0.0.0.0 \
             --noautoconsole

[ -f postbuild.sh ] && ./postbuild.sh
