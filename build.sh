#!/bin/bash
#set -x

usage() {
cat <<EOF
usage: $0 options

OPTIONS:
-h                  Show this message
-n {network}        Full Network Name, e.g. vlan100
-o {openrc}         OpenRC file (keystone endpoint, auth credentials)
-m {machine}        Machine name, e.g. trusty-100
-k {keyname}        Ssh keyname

This script attempts to build a machine in an openstack system based
on the target endpoint described in the openrc file that is passed
in (or the default of the local macine).

You can pass:
A network name (which will be converted to the net-id)
An openrc file (to describe the target openstack environment)
A machine name (defaults to test-network)

EOF
}
export -f usage

# parse CLI options
while getopts "hn:o:m:k:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    n)
      export network=$OPTARG
      ;;
    o)
      export openrc=$OPTARG
      ;;
    m)
      export machine=$OPTARG
      ;;
    k)
      export keyname=$OPTARG
      ;;
  esac
done

if [ $# -eq 0 ] ;then
  usage
  exit 1
fi

source ${openrc:-~/openrc}

if [ ! "`glance image-list | grep trusty`" ]; then
  echo importing image, this may take a while
  glance image-create --location https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img --container-format bare --disk-format qcow2 --is-public True --name trusty --progress
fi

keyname=${keyname:-root}
if [ ! "`nova keypair-list | grep ${keyname}`" ]; then
  if [ "${keyname}" -eq "root" ]; then
    nova keypair-add --pub-key /root/.ssh/id_rsa.pub root
  else
    ssh-keygen -f id_rsa -t rsa -N ''
    nova keypair-add --pub-key ./id_rsa.pub ${keyname}
  fi
fi

if [ ${network} ]; then
  netid=`neutron net-list | awk "/ ${network} / {print \\\$2}"`
  name=${machine:-trusty-${network}}
else
  netid=`neutron net-list | grep -v '+' | grep -v 'id' | head -1 | awk '/ / {print $2}'`
  name=${machine:-trusty-`neutron net-list | grep -v '+' | grep -v 'id' | head -1 | awk '/ / {print $4}'`}
fi
if [ -f './user-data' ]; then
  userdata='./user.data'
  userdata="--config-drive true --user-data $userdata"
fi

echo "Nova boot:   ${name}"
nova boot --image trusty --flavor 2 --key-name ${keyname} ${userdata} --nic net-id=${netid} ${name}


