#!/bin/bash

###### ###### ###### ###### ###### ###### ###### ###### ###### ######
# Description:
#
# Removes IP from Ubuntu with netplan apply and retores original
# ec2 networking state
#
###### ###### ###### ###### ###### ###### ###### ###### ###### ######


# http://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o errexit
set -o nounset

sudo /bin/bash -c " \
  mv /etc/netplan/50-cloud-init.yaml /tmp/50-cloud-init.yaml && \
  rm -rf /etc/netplan/* && \
  mv /tmp/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml && \
  netplan apply"
sudo service haproxy stop
