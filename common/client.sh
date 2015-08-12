#!/bin/sh
#
# Create block device image and map it to block device
#
modprobe rbd
cd /etc/ceph
rbd create bd128 --size 128
rbd map bd128 --name client.admin
sudo mkfs.ext4 -m0 /dev/rbd/rbd/bd128
mkdir -p /mnt/ceph-bd128
echo '/dev/rbd/rbd/bd128 /mnt/ceph-bd128                       ext4    defaults' >> /etc/fstab
mount /mnt/ceph-bd128
mkdir -p /mnt/ceph-fs
#
# Mount Ceph Filesistem using kernel module via monitor on node1
#
modprobe ceph
echo 'node1:6789:/ /mnt/ceph-fs                       ceph    name=admin,secretfile=/etc/ceph/admin.secret' >> /etc/fstab
cat ceph.client.admin.keyring | grep key | sed -r 's/^.*key = //' > /etc/ceph/admin.secret
mount /mnt/ceph-fs
#
# Comment out self in /etc/rc.local
#
sed -i "s@/root/client.sh@# /root/client.sh@" /etc/rc.local
