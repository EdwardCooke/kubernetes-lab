#!/bin/bash

echo "#!/bin/bash

echo '$(cat ../ca/ca.crt)' > /usr/local/share/ca-certificates/k8slan.crt
echo '$(cat ../ca/wildcard.crt)' > /etc/ssl/private/wildcard.crt
echo '$(cat ../ca/wildcard.key)' > /etc/ssl/private/wildcard.key

update-ca-certificates
" > certs.sh

sed "s\\__authorizedkey__\\$(cat ~/.ssh/vm.pub)\\" user-data > cidata/user-data.source
cloud-init devel make-mime -a cidata/user-data.source:cloud-config -a certs.sh:x-shellscript-per-once --force > cidata/user-data
