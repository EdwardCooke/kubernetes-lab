#!/bin/bash
echo "Waiting for the host to come up"

cancelled=false
until echo -n "."; ping -c1 kube1w2.k8s.lan >/dev/null 2>&1; do :; done &
trap "kill $!; cancelled=true" SIGINT
wait $!          # Wait for the loop to exit, one way or another
trap - SIGINT    # Remove the trap, now we're done with it

echo "Waiting for kubernetes to finish installing, this will take a couple of minutes"
until [ "`kubectl get nodes kube1w2 2> /dev/null | grep Ready > /dev/null && echo -n 1 2> /dev/null`" == "1" ]
do
    sleep 5;
    echo -n ".";
done
trap "kill $!; cancelled=true" SIGINT
wait $!
trap - SIGINT
