#!/bin/bash

yum update -y
yum install -y epel-release
yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
yum install -y openstack-packstack
yum install -y openstack-tools

echo 'Perhaps run the packstack all-in-one installer now?: packstack --allinone'
echo 'or if you want to have something a little more advanced:'
echo 'packstack --allinone --default-password='onecloud' --os-compute-hosts=controller_plus_compute_ip,compute_ip'
