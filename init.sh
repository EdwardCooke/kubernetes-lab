#!/bin.sh


./build.sh dns 512
sleep 45
./build.sh kube1 512
sleep 45
./build.sh kube2 512
sleep 45
./build.sh kube1cp1
sleep 45
#./build.sh kube1cp2
#./build.sh kube1cp3
#./build.sh kube1w1
#./build.sh kube1w2
#./build.sh kube2cp1
#./build.sh kube2cp2
#./build.sh kube2cp3
#./build.sh kube2w1
#./build.sh kube2w2
