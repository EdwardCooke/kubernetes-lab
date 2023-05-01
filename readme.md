# Purpose and implementation
This repository configures a dedicated server with the following VM's with scripts to easily tear the down and rebuild the lab environment from scratch, giving you a fresh environment to work with

* DNS server
* 2 vanilla Kubernetes clusters
* 2 frontend proxies for the control planes of the clusters.

The kubernetes clusters are built with HA in mind, 3 control planes and 2 worker nodes each. Each Kubernetes node has 4 gigs of memory, the DNS and proxies each have 512. All systems have 2 vCPU's.

The OS used by the VM's are Ubuntu 22.04.

The DNS server has an authoritative zone, `k8s.lan`, which all VM's are under. It then forwards all other requests to the root DNS servers.
* If your environment blocks outbound DNS then you will need to update the DNS config to forward to your upstream DNS server

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

I recommend your base VM be a desktop install, that way you can browse the cluster sites easily. Ubuntu 20.04 Desktop has been tested extensively with these scripts.

Set up your sudo to run without a password required for all users `cat "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/nopass`

You will need `git` installed. `sudo apt install -y git`

## Hyper-V

I highly recommend using Ubuntu 20.04 and NOT 22.04. There is some significant performance penalties when using 22.04 with using nested virtualization The difference is in the order of about a minute and a half per vm boot, and about half-hour to hour to install each role on virtual machine.

To enable the virtualization extensions and change the screen resolution of the VM, execute the following in an admin PowerShell window. Replace `kube-lab` with the name of your virtual machine in Hyper-V Manager.

```powershell
Set-VMProcessor -VMName "kube-lab" -ExposeVirtualizationExtensions $true
Set-VMVideo -VMName "kube-lab" -HorizontalResolution 2000 -VerticalResolution 1500 -ResolutionType Single
```

## Quick start
The following commands will bootstrap a fresh host machine to run the lab

```bash
sudo apt install -y git
git clone git@github.com:EdwardCooke/kubernetes-lab.git
cd kubernetes-lab/vm
./configure-vm.sh
```

Once the initial setup is complete, set the DNS server for your host machine to `192.168.122.254`. Internet will only work while the dns server is up, but you will be able to resolve the clusters and cluster servers.

## Cluster creation
Execute `start.sh` from the root of the repsitory. This will create all necessary VM's.

## Cluster teardown
Execute `stop.sh` from the root of the repository. This will delete all VM's.

## Individual machine creation
Execute `build.sh <machine> <memory>` to build an individual machine, you can get the recommended memory amounts from `start.sh`.

Example: `build.sh dns 512`

# Timings
On a machine with a VM with 10 cores from a 12900HK, 50 gigs of ram and 128 gig disk with 1200Mb/s internet
* `configure-vm.sh` - `~10-15 minutes`
* `start.sh` - `~20-30 minutes`
* `stop.sh` - `~5 seconds`

# Recommended, but not required advanced use cases and configuration
These are not covered in this readme as it will vary a lot between different environments. They are also not required for the lab to work.

* Setup a route from your local network to `192.168.122.0/24` to the IP of your VM to route traffic to the lab Kubernetes clusters.
* Change the network type from `nat` to `open` in your host machine using `virsh net-edit default`
* Setup DNS zone forwarding from your local network DNS to send requests for anything under `k8s.lan` to `192.168.122.254`, or set your local machine to use 192.168.122.254 as the dns server

These additional tasks will allow you to browse your cluster resources from a system outside of the lab.
