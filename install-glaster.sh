#!/bin/bash
apt-get -y update && apt-get -y upgrade
apt-get install -y software-properties-common
add-apt-repository ppa:gluster/glusterfs-6 && apt-get update # Use the latest glusterFS version instead of 6, which was the latest at the time of writing this tutorial
apt-get install -y glusterfs-server
systemctl enable glusterd # automatically start glusterfs on boot
systemctl start glusterd # start glusterfs right now
systemctl status glusterd # Should show status active