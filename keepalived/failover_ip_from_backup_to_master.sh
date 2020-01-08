#!/bin/bash

###### ###### ###### ###### ###### ###### ###### ###### ###### ######
# Description:
#
# moves the HAProxy service IP from one ec2 instance
# to another and starts HAProxy on that server
#
# Setup:
#
# You need, at a minimum, the following permissions:
# {
#   "Statement": [
#     {
#       "Action": [
#         "ec2:AssignPrivateIpAddresses",
#         "ec2:UnassignPrivateIpAddresses",
#         "ec2:DescribeInstances"
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
#
# Usage:
#
# ./thisScript.sh <serviceIP> <failedEc2IP> <healthyEc2IP>
#
# Example:
# ./thisScript.sh '10.0.0.5' '10.0.0.10' '10.0.0.11'
#
###### ###### ###### ###### ###### ###### ###### ###### ###### ######


# http://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o errexit
set -o nounset

LOAD_BALANCING_SERVICE_IP=$1
FAILED_EC2_PRIVATE_IP=$2
HEALTHY_EC2_PRIVATE_IP=$3

# Obtain NetworkInterfaceIds
FAILED_EC2_NETWORK_INTERFACE_ID=$(\
  aws ec2 describe-instances \
  --filters Name=private-ip-address,Values=${FAILED_EC2_PRIVATE_IP} | \
  jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
)
HEALTHY_EC2_NETWORK_INTERFACE_ID=$(\
  aws ec2 describe-instances \
  --filters Name=private-ip-address,Values=${HEALTHY_EC2_PRIVATE_IP} | \
  jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
)

echo "Executing High Availability Failover for HAProxy Service IP"

# Remove HAProxy Service IP from failed ec2
echo "Removing IP ${LOAD_BALANCING_SERVICE_IP} from failed ec2 at ${FAILED_EC2_PRIVATE_IP}"
aws ec2 unassign-private-ip-addresses \
  --network-interface-id ${FAILED_EC2_NETWORK_INTERFACE_ID} \
  --private-ip-addresses ${LOAD_BALANCING_SERVICE_IP} \

# Add HAProxy Service IP to healthy ec2
echo "Adding IP ${LOAD_BALANCING_SERVICE_IP} to healthy ec2 at ${HEALTHY_EC2_PRIVATE_IP}"
aws ec2 assign-private-ip-addresses \
  --network-interface-id ${HEALTHY_EC2_NETWORK_INTERFACE_ID} \
  --private-ip-addresses ${LOAD_BALANCING_SERVICE_IP} \
  --allow-reassignment

# Consume HAProxy Service IP in Ubuntu 18.04
echo "Adding IP ${LOAD_BALANCING_SERVICE_IP} to eth0 on Ubuntu 18.04 machine using netplan apply"
sudo bash -c "echo '
network:
  version: 2
  ethernets:
    eth0:
      addresses:
      - ${LOAD_BALANCING_SERVICE_IP}/24' > /etc/netplan/keepalived_haproxy_service_ip.yaml"
sudo netplan apply

sudo service haproxy start
