#!/bin/bash
source ~/openrc
tenant=`keystone tenant-list | awk '/ openstack / {print $2}'`
neutron net-create vlan${1} --tenant_id ${tenant} --provider:network_type vlan --provider:physical_network physnet1 --provider:segmentation_id ${1}
network=`neutron net-list | grep vlan${1} | awk -F' ' '{print $2}'`
neutron subnet-create ${network}  10.1.${1}.0/24 --allocation-pool start=10.1.${1}.80,end=10.1.${1}.99 --dns-nameserver 8.8.8.8
# --host-route destination=10.0.0.0/8,nexthop=10.1.10.254
