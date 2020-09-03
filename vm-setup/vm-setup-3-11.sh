#!/bin/bash

hosts=(ocpmgmt ocpma01 ocpin01 ocpno01  ocpno02 quay)

disks=(200	200	200	200	  200	200)

vcpus=(2	4	4	 4	   4	4   )

memory=( 4096	12288	12288	12288	 12288	12288)

ips=(192.168.122.7 192.168.122.8 192.168.122.9 192.168.122.10 192.168.122.11 192.168.122.12)

dns=(192.168.122.1)
 
gw=(192.168.122.1)

netm=(255.255.255.0)

domain=("ocp.bofh.uno")

nums=${#hosts[@]}

# Deploy VMs
while [ $nums -gt 0 ]  
do
let nums-=1
echo "host: ${hosts[$nums]}"
echo "img: /var/lib/libvirt/images/${hosts[$nums]}.img"
echo "vcpus: ${vcpus[$nums]}"
echo "memory: ${memory[$nums]}"
echo "hostname: ${hosts[$nums]}.$domain"
echo "ipv4: ${ips[$nums]} dns:$dns gw:$gw netmask:$netm"

virt-install --name=${hosts[$nums]} --file=/var/lib/libvirt/images/${hosts[$nums]}.img --file-size=${disks[$nums]} --graphics none --vcpus=${vcpus[$nums]} --ram=${memory[$nums]} --location=/iso/rhel-server-7.6-x86-64-dvd.iso --network bridge=virbr0 --os-type=linux --os-variant=rhel7.6 --initrd-inject=anaconda-ks-2.cfg --noautoconsole --extra-args="ks=file:/anaconda-ks-2.cfg hostname=${hosts[$nums]}.$domain console=ttyS0 ip=${ips[$nums]} dns=$dns gateway=$gw netmask=$netm console=ttyS0,115200n8 serial ksdevice="

echo "------------          --------------"

done
