# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrant file to test installation of Ceph, confiure block device and Ceph filesistem
#
# Based on instruction from http://ceph.com/docs/master/start/quick-ceph-deploy/
#
# admin - admin node
#
# node1 - osd2, mds, mon
# node2 - osd0, mon
# node3 - osd1, mon
#
# client - client node
#
# osd - Object Storage Device
# mds - Ceph Metadata Server
# mon - Ceph Monitor 
#
# for HOST in {node1,node2,node3}; do ssh $HOST "service ntpd stop&&ntpdate pool.ntp.org&&chkconfig ntpd on&&service ntpd start&&service ceph restart"; done
Vagrant.configure(2) do |config|
  # 
  # Vagrant boxes for libvirt or virtualbox
  # 
  #config.vm.box = "centos64"
  #config.vm.provider "libvirt"
  config.vm.box = "chef/centos-6.6"
  config.vm.provider "virtualbox"
  #
  # Creating nodes
  #
  config.vm.define :node3 do |node3|
    node3.vm.network "private_network", ip: "192.168.33.13"
    node3.vm.hostname = "node3"
    node3.vm.synced_folder "./common", "/vagrant"
    node3.vm.provision "shell", inline: $node
  end
  config.vm.define :node2 do |node2|
    node2.vm.network "private_network", ip: "192.168.33.12"
    node2.vm.hostname = "node2"
    node2.vm.synced_folder "./common", "/vagrant"
    node2.vm.provision "shell", inline: $node
  end
  config.vm.define :node1 do |node1|
    node1.vm.network "private_network", ip: "192.168.33.11"
    node1.vm.hostname = "node1"
    node1.vm.synced_folder "./common", "/vagrant"
    node1.vm.provision "shell", inline: $node
  end
#
# Creating client node
#
  config.vm.define :client do |client|
    client.vm.network "private_network", ip: "192.168.33.9"
    client.vm.hostname = "client"
    client.vm.synced_folder "./common", "/vagrant", type: "rsync"
    client.vm.provision "shell", inline: $node
  end
#
# Creating admin node
#
  config.vm.define :admin do |admin|
    admin.vm.network "private_network", ip: "192.168.33.10"
    admin.vm.hostname = "admin"
    admin.vm.synced_folder "./common", "/vagrant"
    admin.vm.provision "shell", inline: $admin
  end
#
# Admin node provisioning
#
$admin = <<SCRIPT
#!/bin/sh
>&2 echo Setting up Admin Node
#
# Check internet connection
#
ping -c 2 -W 2 google-public-dns-a.google.com
if [[ $? != 0 ]]
then
  echo "Can't connect to internet" >&2
  exit 1
fi
#
# Creating Ceph noarch repo and ceph deploy package
#
cp /vagrant/ceph-noarch.repo /etc/yum.repos.d/ceph-noarch.repo
yum install -y ceph-deploy ntp ntpdate ntp-doc
#
# Adding nodes to /etc/hosts
#
echo "192.168.33.9 client" >> /etc/hosts
echo "192.168.33.10 admin" >> /etc/hosts
echo "192.168.33.11 node1" >> /etc/hosts
echo "192.168.33.12 node2" >> /etc/hosts
echo "192.168.33.13 node3" >> /etc/hosts
#
# Prepare ssh keys
#
mkdir /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/
cp /vagrant/id_rsa /root/.ssh/
cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys
ssh-keyscan 192.168.33.9 >> /root/.ssh/known_hosts
ssh-keyscan client >> /root/.ssh/known_hosts
ssh-keyscan 192.168.33.10 >> /root/.ssh/known_hosts
ssh-keyscan admin >> /root/.ssh/known_hosts
ssh-keyscan 192.168.33.11 >> /root/.ssh/known_hosts
ssh-keyscan node1 >> /root/.ssh/known_hosts
ssh-keyscan 192.168.33.12 >> /root/.ssh/known_hosts
ssh-keyscan node2 >> /root/.ssh/known_hosts
ssh-keyscan 192.168.33.13 >> /root/.ssh/known_hosts
ssh-keyscan node3 >> /root/.ssh/known_hosts
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
#
# This is test installation, so, turning off iptables
#
service iptables stop
chkconfig iptables off
setenforce 0
#
# Sync time on all nodes
#
for HOST in {admin,node1,node2,node3,client}; do ssh $HOST "yum -y install ntp&&service ntpd stop&&ntpdate pool.ntp.org&&chkconfig ntpd on&&service ntpd start"; done
#
# Setup cluster
#
cd /root
mkdir cluster
cd cluster
#
# Clean data
#
ceph-deploy purgedata node1 node2 node3
ceph-deploy forgetkeys
#
# Create cluster
#
ceph-deploy new node1
#
# Correct minor bug in and start node install
#
sed -i "s/rpmkeys/rpm/" /usr/lib/python2.6/site-packages/ceph_deploy/util/pkg_managers.py
echo "osd_pool_default_size = 2" >> ceph.conf
ceph-deploy install admin node1 node2 node3
#
# Init default monitor
#
ceph-deploy mon create-initial
#
# Prepare data directories for storage devices and init it
#
ssh node2 "mkdir /var/local/osd0"
ssh node3 "mkdir /var/local/osd1"
ceph-deploy osd prepare node2:/var/local/osd0 node3:/var/local/osd1
ceph-deploy osd activate node2:/var/local/osd0 node3:/var/local/osd1
#
# Copy the configuration file and admin key to admin node and Ceph nodes
#
ceph-deploy admin admin node1 node2 node3
#
# Check cluster health
#
ceph health
if [[ $? != 0 ]]
then
  echo "WARNING. Cluster not started.Can't continue to add more osd and monitors" >&2
  exit 1
fi
#
# Add one more node osd to node1
#
ssh node1 "mkdir /var/local/osd2"
ceph-deploy osd prepare node1:/var/local/osd2
ceph-deploy osd activate node1:/var/local/osd2
#
# Add metadata server
#
ceph-deploy mds create node1
#
# Add Object Gateway
#
ceph-deploy rgw create node1
#
# Add additional monitors
#
ceph-deploy mon add node2
ceph-deploy mon add node3
#
# Check cluster health
#
ceph health
if [[ $? != 0 ]]
then
  echo "WARNING. Cluster not started. Can't continue and configure client!" >&2
  exit 1
fi
#
# Prepare Ceph Filesystem
#
ceph osd pool create cephfs_data 32
ceph osd pool create cephfs_metadata 32
ceph fs new ceph_fs cephfs_metadata cephfs_data
#
# Configure client
#
ceph-deploy install client
ceph-deploy admin client
#
# Add ELRepo and install MainLine kernel for centos 6 with rbd and ceph filesystem kernel modules support
# 
# Additional configuration will make after reboot by client.sh script
#
ssh client "cp /vagrant/client.sh /root/client.sh"
ssh client "chmod +x /root/client.sh"
ssh client "yum -y localinstall http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm"
ssh client "yum -y --enablerepo=elrepo-kernel install kernel-lt gcc"
ssh client "sed -i 's/default=1/default=0/' /boot/grub/grub.conf"
ssh client "echo '/root/client.sh > /tmp/client.out 2>&1' >> /etc/rc.local"
ssh client "reboot"
#
# Add time sync to all nodes after admin node reboot
#
echo '#Force time sync on nodes' >> /etc/rc.local
echo 'for HOST in {node1,node2,node3,client}; do ssh \$HOST "service ntpd stop&&ntpdate pool.ntp.org&&chkconfig ntpd on&&service ntpd start&&service ceph restart"; done' >> /etc/rc.local
#
# Cleaning packages
#
yum clean all
#
# Exit with cluster status
#
ceph health
exit $?
SCRIPT
#
# Ceph Nodes simple provisioning
#
$node = <<SCRIPT
#!/bin/sh
>&2 echo Setting up Node
#
# Check internet connection
#
ping -c 2 -W 2 google-public-dns-a.google.com
if [[ $? != 0 ]]
then
  echo "Can't connect to internet" >&2
  exit 1
fi
#
# Prepare ssh keys
#
mkdir /root/.ssh
cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
#
# Adding admin node and nodes to /etc/hosts
#
echo "192.168.33.9 client" >> /etc/hosts
echo "192.168.33.10 admin" >> /etc/hosts
echo "192.168.33.11 node1" >> /etc/hosts
echo "192.168.33.12 node2" >> /etc/hosts
echo "192.168.33.13 node3" >> /etc/hosts
#
# This is test installation, so turning off iptables
#
service iptables stop
chkconfig iptables off
setenforce 0
#
# CleanUp packages
#
yum clean all
SCRIPT
end
