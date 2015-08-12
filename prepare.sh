#!/bin/sh
echo Preparing to up admin and nodes
#
# Generating ssh keys to allow access to nodes from admin node
#
rm -f ./common/id_*
ssh-keygen -f ./common/id_rsa -P ""
chmod +x common/*.sh 
