#!/bin/bash

mkdir -p build

echo "#!/bin/bash

echo '$(cat ../ca/ca.crt)' > /usr/local/share/ca-certificates/k8slan.crt
echo '$(cat ../ca/wildcard.crt)' > /etc/ssl/private/wildcard.crt
echo '$(cat ../ca/wildcard.key)' > /etc/ssl/private/wildcard.key

update-ca-certificates
" > build/certs.sh

sed "s\\__authorizedkey__\\$(cat ~/.ssh/vm.pub)\\" user-data > build/user-data.source
cloud-init devel make-mime -a build/user-data.source:cloud-config -a build/certs.sh:x-shellscript-per-once --force > cidata/user-data
cp meta-data cidata
cp network-config cidata
