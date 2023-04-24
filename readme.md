# Purpose and implementation
This repository configures a dedicated server with the following VM's with scripts to easily tear the down and rebuild the lab environment from scratch, giving you a fresh environment to work with

* DNS server
* 2 vanilla Kubernetes clusters
* 2 frontend proxies for the control planes of the clusters.

The kubernetes clusters are built with HA in mind, 3 control planes and 2 worker nodes each. Each Kubernetes node has 4 gigs of memory, the DNS and proxies each have 512. All systems have 2 vCPU's.

The base image is the 22.04 version of Ubuntu.

It configures the machine as a router, with a subnet of 192.168.122.0/24 dedicated for the VM's.

The DNS server has an authoritative zone, `k8s.lan`, which all VM's are under.

The hostnames are as follows
* `dns.k8s.lan`
* `kube1.k8s.lan`
* `kube2.k8s.lan`
* `kube1cp1.k8s.lan`
* `kube1cp2.k8s.lan`
* `kube1cp3.k8s.lan`
* `kube1w1.k8s.lan`
* `kube1w2.k8s.lan`
* `kube2cp1.k8s.lan`
* `kube2cp2.k8s.lan`
* `kube2cp3.k8s.lan`
* `kube2w1.k8s.lan`
* `kube2w2.k8s.lan`

`kube1.k8s.lan` and `kube2.k8s.lan` are the control plane proxies.

It configures the clusters with the Calico CNI and adds a demo workload.

To speed up the creation of the clusters it will do the additional following tasks
* Configures a local docker registry to cache the Kubernetes images
* Configures a local apt repository to cache the Docker and Kubernetes repositories

# Usage
The minimum requirements for this lab is about 50 gigs of memory, 100gigs of disk space and at least 4 cores, more is better, tested with 12 with Virtualization Extensions enabled.

I recommend your base VM be a desktop Ubuntu image, that way you can browse the cluster sites.

Set up your sudo to run without a password required for all users `cat "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/nopass`

You will need `git` installed.

## Initial VM setup, only needed once.
Clone this repository, change directory to the `vm` directory and execute `./configure-vm.sh`. Expect this process to take a while, theres a lot of data downloaded from the internet for the cache'd apt repositories and base Ubuntu cloud server image.

Once the initial setup is complete, set the DNS server for the VM to `192.168.122.254`. Internet will only work while the clusters are up, but you will be able to resolve the clusters and cluster servers.

## Cluster creation
Execute `start.sh` from the root of the repsitory. This will create all necessary VM's.

## Cluster teardown
Execute `stop.sh` from the root of the repository. This will delete all VM's.

# Timings
On a machine with a VM with 12 cores from a 12900K, 50 gigs of ram and 128 gig disk with 1200Mb/s internet
* `configure-vm.sh` - `~40 minutes`
* `start.sh` - `~5 minutes`
* `stop.sh` - `~5 seconds`

# Recommended, but not required advanced use cases and configuration
These are not covered in this readme as it will vary a lot between different environments. They are also not required for the lab to work.

* Setup a route from your local network to `192.168.122.0/24` to the IP of your VM to route traffic to the lab Kubernetes clusters.
* Setup DNS zone forwarding from your local network DNS to send requests for anything under `k8s.lan` to `192.168.122.254`.

These 2 additional tasks will allow you to browse your cluster resources from a system outside of the lab.
