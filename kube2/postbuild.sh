#!/bin/bash
echo "Waiting for the host to come up"

cancelled=false
until echo -n "."; ping -c1 kube2.k8s.lan >/dev/null 2>&1; do :; done &
trap "kill $!; cancelled=true" SIGINT
wait $!          # Wait for the loop to exit, one way or another
trap - SIGINT    # Remove the trap, now we're done with it

echo "Waiting for haproxy to be installed, this will take a couple of minutes"
until [ "`ssh -i ~/.ssh/vm_id kube2.k8s.lan '( apt search haproxy 2> /dev/null | grep installed > /dev/null ) && echo -n 1' 2> /dev/null`" == "1" ]
do
    sleep 5;
    echo -n ".";
done
trap "kill $!; cancelled=true" SIGINT
wait $!
trap - SIGINT
