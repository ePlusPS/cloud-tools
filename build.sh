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

source ${openrc:-~/keystonerc_admin}

if [ ${network} ]; then
  netid=`neutron net-list | awk "/ ${network} / {print \\\$2}"`
  name=trusty-${network}
else
  netid=`neutron net-list | grep -v '+' | grep -v 'id' | head -1 | awk '/ / {print $2}'`
  name=trusty-nonet
fi
name=${machine:-$name}
if [ -f './user-data' ]; then
  userdata='./user.data'
  userdata="--user-data $userdata"
fi
keyname=${keyname:-root}

echo "Nova boot:   ${name}"
nova boot --image trusty --flavor 2 --key-name ${keyname} --config-drive true ${userdata} --nic net-id=${netid} ${name}


