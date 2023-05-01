#!/bin/bash

# Go where I know I am
cd `dirname "${BASH_SOURCE[0]}"`
mkdir -p ../../ca
cd ../../ca
if [ ! -f ca.key ]
then
    echo "Generating CA certificates"
    openssl genrsa -out ca.key 4096
    openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj '/CN=k8s.lan root/C=US/ST=Utah/L=West Jodan/O=k8s.lan'
fi

echo "Generating wildcard certificates"
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
DNS.4 = *.k8s.lan" > wildcard.openssl.conf

openssl genrsa -out wildcard.key 4096
openssl req -new -key wildcard.key -out wildcard.csr -config wildcard.openssl.conf
openssl x509 -req -days 365 -in wildcard.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out wildcard.crt -extensions req_ext -extfile wildcard.openssl.conf
if [ ! -f /usr/local/share/ca-certificates/k8slan.crt ]
then
    echo "Installing CA cert to local keystore"
    sudo cp ca/ca.crt /usr/local/share/ca-certificates/k8slan.crt
    sudo update-ca-certificates
fi
echo "Copying certificates to /etc/ssl"
sudo cp wildcard.crt /etc/ssl/private
sudo cp wildcard.key /etc/ssl/private
