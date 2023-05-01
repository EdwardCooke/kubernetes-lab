#!/bin/bash

echo "Building dns"
./build.sh dns 512

echo "Building kube1"
./build.sh kube1 512

echo "Building kube2"
./build.sh kube2 512

echo "Building kube1cp1"
./build.sh kube1cp1 4096
echo "Building kube1cp2"
./build.sh kube1cp2 4096
echo "Building kube1cp3"
./build.sh kube1cp3 4096
echo "Building kube1w1"
./build.sh kube1w1 4096
echo "Building kube1w2"
./build.sh kube1w2 4096

echo "Building kube2cp1"
./build.sh kube2cp1 4096
echo "Building kube2cp2"
./build.sh kube2cp2 4096
echo "Building kube2cp3"
./build.sh kube2cp3 4096
echo "Building kube2w1"
./build.sh kube2w1 4096
echo "Building kube2w2"
./build.sh kube2w2 4096
