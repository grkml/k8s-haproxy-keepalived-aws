#!/bin/bash

###### ###### ###### ###### ###### ###### ###### ######
# Description:
#
# attaches an IP of your choice to the primary NIC
# an instance you specify
#
# Setup:
#
# You need, at a minimum, the following permissions:
# {
#  "Statement": [
#    {
#      "Action": [
#        "ec2:AssignPrivateIpAddresses",
#        "ec2:DescribeInstances"
#      ],
#      "Effect": "Allow",
#      "Resource": "*"
#    }
#  ]
# }
#
# Usage:
#
# ./assign_private_ip.sh ip_address instance_id
#
# Example:
# ./assign_private_ip.sh '10.0.3.15' 'i-100ffabd'
#
###### ###### ###### ###### ###### ###### ###### ######


# http://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o errexit
set -o nounset

IP=$1
INSTANCE_ID=$2

ENI=$(\
  aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID | \
  jq -r \
  '.Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' \
)

echo "Adding IP $IP to ENI $ENI"

aws ec2 assign-private-ip-addresses \
  --network-interface-id $ENI \
  --private-ip-addresses $IP \
  --allow-reassignment
