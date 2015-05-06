#!/bin/bash
#set -x 

if [ ! "${OS_PASSWORD}" ]; then
  source ~/keystonerc_admin
fi

aio_id=${1:-'231'}
compute_id=${2:-'241'}
an=${3:-'1'}
cn=${4:-'2'}
echo aio = ${aio_id}:${an}  compute = ${compute_id}:${cn}

nova delete aio${aio_id} compute${compute_id}
sleep 5

cat > /tmp/aio-init.sh <<EOD
#!/bin/bash
passwd centos <<EOF
centos
centos
EOF
passwd root <<EOF
root
root
EOF

sed -e 's/^.*ssh-rsa/ssh-rsa/' -i /root/.ssh/authorized_keys

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
DNS1=10.1.1.92
DOMAIN=onecloud
IPADDR=10.1.64.${aio_id}
PREFIX=24
GATEWAY=10.1.64.1
DEFROUTE=YES
MTU=1400
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
BOOTPROTO=static
ONBOOT=yes
IPADDR=10.1.65.${aio_id}
PREFIX=24
MTU=1400
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
BOOTPROTO=static
ONBOOT=yes
MTU=1400
EOF

cat > /etc/resolv.conf <<EOF
nameserver 10.1.1.92
search onecloud
EOF

cat >> /etc/hosts <<EOF
10.1.64.${aio_id} aio${aio_id}.onecloud aio${aio_id}
10.1.64.${compute_id} compute${compute_id}.onecloud compute${compute_id}
10.1.64.1 gw.onecloud gw
EOF

cat >> /etc/hostname <<EOF
aio${aio_id}
EOF
hostname aio${aio_id}

ifdown eth0; ifup eth0; ifdown eth1; ifup eth1; ifdown eth2; ifup eth2

umount /mnt
sed -e '/vdb/d ' -i /etc/fstab

yum update -y
yum install bind-utils screen vim -y
EOD

cat > /tmp/compute-init.sh <<EOD
#!/bin/bash
passwd centos <<EOF
centos
centos
EOF
passwd root <<EOF
root
root
EOF

sed -e 's/^.*ssh-rsa/ssh-rsa/' -i /root/.ssh/authorized_keys

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
DNS1=10.1.1.92
DOMAIN=onecloud
IPADDR=10.1.64.${compute_id}
PREFIX=24
GATEWAY=10.1.64.1
DEFROUTE=YES
MTU=1400
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
BOOTPROTO=static
ONBOOT=yes
IPADDR=10.1.65.${compute_id}
PREFIX=24
MTU=1400
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
BOOTPROTO=static
ONBOOT=yes
MTU=1400
EOF

cat > /etc/resolv.conf <<EOF
nameserver 10.1.1.92
search onecloud
EOF

cat >> /etc/hosts <<EOF
10.1.64.${aio_id} aio${aio_id}.onecloud aio${aio_id}
10.1.64.${compute_id} compute${compute_id}.onecloud compute${compute_id}
10.1.64.1 gw.onecloud gw
EOF

cat >> /etc/hostname <<EOF
compute${compute_id}
EOF
hostname compute${compute_id}

ifdown eth0; ifup eth0; ifdown eth1; ifup eth1; ifdown eth2; ifup eth2

umount /mnt
sed -e '/vdb/d' -i /etc/fstab

yum update -y
yum install bind-utils screen vim emacs -y
EOD

sixtyfour=`neutron net-list | awk '/ sixtyfour / {print $2}'`
sixtyfive=`neutron net-list | awk '/ sixtyfive / {print $2}'`
flat=`neutron net-list | awk '/ flat / {print $2}'`
image=`glance image-list | awk '/ centos7 / {print $2}'`

# Only eth0 on VLAN 64 and eth1 on VLAN 65
nova boot --image ${image} --flavor os.large --nic net-id=${sixtyfour},v4-fixed-ip=10.1.64.${aio_id} \
--nic net-id=${sixtyfive},v4-fixed-ip=10.1.65.${aio_id} --nic net-id=${flat} --config-drive True \
--user-data /tmp/aio-init.sh --availability-zone nova:centos-${an}.onecloudinc.com --key-name class aio${aio_id}
nova boot --image ${image} --flavor os.medium --nic net-id=${sixtyfour},v4-fixed-ip=10.1.64.${compute_id} \
--nic net-id=${sixtyfive},v4-fixed-ip=10.1.65.${compute_id} --nic net-id=${flat} --config-drive True \
--user-data /tmp/compute-init.sh --availability-zone nova:centos-${cn}.onecloudinc.com --key-name class compute${compute_id}

echo "aio VNC"
vnc aio${aio_id}
echo "compute VNC"
vnc compute${compute_id}

