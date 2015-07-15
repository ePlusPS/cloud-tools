#!/bin/bash

yum update -y
yum install -y epel-release
yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
yum install -y openstack-packstack
#yum install -y openstack-tools

eth0_ip=`ip addr show eth0 | awk '/ inet / {print $2}' | cut -d/ -f1`
eth0_net=`ip addr show eth0 | awk '/ inet / {print $2}' | cut -d/ -f1 | cut -d. -f1-3`
eth0_addr=`ip addr show eth0 | awk '/ inet / {print $2}' | cut -d/ -f1 | cut -d. -f4`
eth0_compute_ip=`echo ${eth0_net}.$(($eth0_addr+10))`
echo 'Perhaps run the packstack all-in-one installer now?: packstack --allinone'
echo ''
echo 'Or, to also configure the network appropriately, you should run:'
echo ''
echo "packstack --default-password=onecloud --os-neutron-ml2-tenant-network-types=vlan --os-compute-hosts=${eth0_ip},${eth0_compute_ip} --provision-all-in-one-ovs-bridge=y --os-neutron-ml2-type-drivers=flat,vlan --os-neutron-ml2-tunnel-id-ranges=1:1000 --os-neutron-ml2-vlan-ranges=physnet:${eth0_addr}:$(($eth0_addr+10)) --os-neutron-ovs-bridge-mappings=physnet:br-eth1 --os-neutron-ovs-bridge-interfaces=br-eth1:eth1 --os-neutron-lbaas-install=y --os-heat-install=y --os-cinder-install=n --os-swift-install=n --allinone"

