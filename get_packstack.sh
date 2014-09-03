#!/bin/bash

yum update -y
yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
yum install -y openstack-packstack

echo 'Perhaps run the packstack all-in-one installer now?: packstack --allinone'
