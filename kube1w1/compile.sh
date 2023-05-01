#!/bin/bash

mkdir -p build
mkdir -p cidata

echo "#!/bin/bash

echo '$(cat ../ca/ca.crt)' > /usr/local/share/ca-certificates/k8slan.crt
echo '$(cat ../ca/wildcard.crt)' > /etc/ssl/private/wildcard.crt
echo '$(cat ../ca/wildcard.key)' > /etc/ssl/private/wildcard.key

update-ca-certificates
" > build/certs.sh

hash=`ssh kube1cp1.k8s.lan 'openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed "s/^.* //"' 2> /dev/null`
token=$(ssh kube1cp1.k8s.lan 'sudo kubeadm token create' 2> /dev/null)

sed "s\\__authorizedkey__\\$(cat ~/.ssh/vm.pub)\\" user-data > build/user-data
sed "s\\__hash__\\$hash\\" install-worker.sh | \
    sed "s\\__token__\\$token\\"  > build/install-worker.sh

cp meta-data cidata
cp network-config cidata

cloud-init devel make-mime -a build/user-data:cloud-config -a build/certs.sh:x-shellscript-per-once -a build/install-worker.sh:x-shellscript-per-once --force > cidata/user-data
