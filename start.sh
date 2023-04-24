#!/bin/bash


./build.sh dns 512
./build.sh kube1 512
./build.sh kube2 512
sleep 45

./build.sh kube1cp1 4096
sleep 45
./build.sh kube1cp2 4096
./build.sh kube1cp3 4096
./build.sh kube1w1 4096
./build.sh kube1w2 4096

./build.sh kube2cp1 4096
sleep 45
./build.sh kube2cp2 4096
./build.sh kube2cp3 4096
./build.sh kube2w1 4096
./build.sh kube2w2 4096
