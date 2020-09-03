# OpenShift 3.11 deployment scripts

Scripts used for provisioning and preparing VMs, then deploying OCP on them.

## Features

With the scripts you currently can:
* Provision VMs with predefined attributes found in **vm-setup/vm-setup-3-11.sh**
* Create NFS shares on a VM for PVs using Ansible script **vm-setup/nfs_pv.yaml**
* Deploy OCP using the Ansible inventories **inventory_[features].yaml**
* Create PVs in OpenShift using **pv-script.sh**

## Before you start
* Before you provision the VMs, make sure that they are not already present. If they are, feel free to use them.

```shell
[root@CentOS-74-64-minimal]# virsh list --all
```

* If you want a fresh install of VMs, before provisioning them, make sure if there are no spashots already with a freshly-prepared state.

```shell
[root@CentOS-74-64-minimal]# virsh snapshot-revert --domain [HOST] --snapshotname [HOST]-[STATE]
```

* Before downloading the ISO, make sure that it's not already downloaded.

## Prerequisites

Install required packages:

```shell
[root@CentOS-74-64-minimal]# yum install qemu-kvm qemu-img libvirt libvirt-python libvirt-client virt-install bridge-utils ansible
```
Get a RHEL 7.6 Server image and put it into **/iso/**:
```shell
[root@CentOS-74-64-minimal]# wget -P /iso/ https://access.cdn.redhat.com//content/origin/files/sha256/d0/d0dd6ae5e001fb050dafefdfd871e7e648b147fb2d35f0e106e0b34a0163e8f5/rhel-server-7.6-x86_64-dvd.iso?_auth_=[AUTHKEY]
```
Clone the git repo and cd into the directory:
```shell
[root@CentOS-74-64-minimal]# git clone https://gitlab.consulting.redhat.com/aerdei/openshift-deployment-practice.git
[root@CentOS-74-64-minimal]# cd openshift-deployment-practice
```

## Getting started

The deployment process consists of 3 stages:
1. VM provision
2. VM preparation
3. OCP deployment

#### 1. Provisioning the VMs
Edit **vm-setup/vm-setup-3-11.sh** to suit your needs. It is possible to modify the arrays and set the following variables:
* Hosts
* Disk sizes
* vCPUs
* Memory sizes
* IPs
* DNS
* Gateway
* Domain

After setting your parameters, run the script:
```shell
[root@CentOS-74-64-minimal]# cd vm-setup
[root@CentOS-74-64-minimal]# sh vm-setup-3-11.sh
```
The provisioning process will take some time. It is recommended to follow the setup process by watching the console of the VM provisioned last:
```shell
[root@CentOS-74-64-minimal]# virsh console ocpmgmt
```
When the last VM is provisioned, the VMs will be shut down. 

#### 2. Preparing the VMs
Update the hostsfile to better represent your VMs IP setup:
```shell
[root@CentOS-74-64-minimal]# vi /etc/hosts
[root@CentOS-74-64-minimal]# killall -SIGHUP dnsmasq
```
Start the machines for the preparation process:
```shell
[root@CentOS-74-64-minimal]# for i in `virsh list --all|awk '{print $2}'|grep -v Name`; do virsh start $i; done
```
Copy the ssh-key to the management (ocpmgmt) VM:
```
[root@CentOS-74-64-minimal]# ssh-copy-id ocpmgmt
```
SSH into ocpmgmt:
```
[root@CentOS-74-64-minimal]# ssh ocpmgmt
```
Copy ocpmgmt's ssh-key to the rest of the VMs:
```
[root@ocpgmt]# ssh-copy-id ocpma01
...
[root@ocpgmt]# ssh-copy-id ocplb01
```
Prepare NFS shares on ocpmgmt. From the host machine, run the Ansible script targeting ocpmgmt. NFS shares will be hosted on the management VM:
```
[root@CentOS-74-64-minimal]# cd vm-setup
[root@CentOS-74-64-minimal]# ansible-playbook nfs_pv.yaml -i "192.168.122.2,"
```
#### 3. Deploying OpenShift 3.11

The VM provisioning process should have taken care of the OCP deployment prerequisites. To start the deployment, choose an inventory from **inventory_[features].yml**
Make sure the VMs mentioned in the inventory are actually provisioned.
Copy the inventory file to the management host:
```shell
[root@CentOS-74-64-minimal]# scp inventory_[features].yml ocpmgmt:/usr/share/ansible/openshift-ansible/inventory_[features].yml
```
SSH into ocpmgmt and go to the deployment dir:
```shell
[root@CentOS-74-64-minimal]# ssh ocpgmt
[root@ocpmgmt]# cd /usr/share/ansible/openshift-ansible/
```

Run the installation playbook:
```shell
[root@ocpgmt]# ansible-playbook -i inventory_[features].yml  playbooks/deploy_cluster.yml 
```
## Remarks

* It is recommended to create snapshots of the VMs after preparation to allow easy roll-back if anything goes South.

```shell
virsh snapshot-create-as --domain [HOST] --name "[HOST]-setup"
```
* The server should have iptables rules to route traffic into the corresponding VMs.
* Currently in the server there are the following NAT rules:
  * Port 8443 is NAT-ed into 192.168.122.8:8443 (ocplb01).
  * Ports 80 and 443 are NAT-ed into 192.168.122.9 (ocpin01).
```
iptables -I FORWARD 1 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A PREROUTING -i eno1 -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.122.9:443
iptables -t nat -A PREROUTING -i eno1 -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.122.9:80
iptables -t nat -A PREROUTING -i eno1 -p tcp -m tcp --dport 8443 -j DNAT --to-destination 192.168.122.8:8443
```

* The default root password for the VMs is **r3dh4t**
* The following repos are locally hosted on the server for better performance, the VM provisioning script requires them locally:
  * rhel-7-server-extras-rpms
  * rhel-7-server-ose-3.11-rpms
  * rhel-7-server-rpms
  * rhel-7-server-ansible-2.6-rpms

## Licensing

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
