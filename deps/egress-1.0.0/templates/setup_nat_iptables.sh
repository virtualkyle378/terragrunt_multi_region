#!/bin/bash

yum install awscli -y

echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
/sbin/iptables -A FORWARD -i eth0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
echo "$INSTANCE_ID"
REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region)
echo "$REGION"

aws ec2 modify-instance-attribute --no-source-dest-check --region "$REGION" --instance-id "$INSTANCE_ID"

# Install SSM https://aws.amazon.com/premiumsupport/knowledge-center/install-ssm-agent-ec2-linux/
# It is not included by default on ecs optimized instances
pushd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
popd
