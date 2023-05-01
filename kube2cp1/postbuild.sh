#!/bin/bash
echo "Waiting for the host to come up"

cancelled=false
until echo -n "."; ping -c1 kube2cp1.k8s.lan >/dev/null 2>&1; do :; done &
trap "kill $!; cancelled=true" SIGINT
wait $!          # Wait for the loop to exit, one way or another
trap - SIGINT    # Remove the trap, now we're done with it

echo "Waiting for kubernetes to finish installing, this will take a couple of minutes"
until [ "`ssh kube2cp1.k8s.lan '[ -f /home/kube.config ] && echo -n 1' 2> /dev/null`" == "1" ]
do
    sleep 5;
    echo -n ".";
done
trap "kill $!; cancelled=true" SIGINT
wait $!
trap - SIGINT

echo Grabbing the kubernetes config file
mkdir -p ~/.kube
ssh kube2cp1.k8s.lan "cat /home/kube.config" > ~/.kube/kube2.config 2> /dev/null
cp ~/.kube/kube2.config ~/.kube/config

echo "Installing calico"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml
sleep 10
