#!/bin/bash
set -x

exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
yum -y update

echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
service sshd restart

yum -y install curl iputils check-update gcc wget libcurl openssl unzip python3-distutils jq build-essential python36 python36-pip

while [ ! -f /home/ec2-user/.ssh/id_rsa ]
do
  sleep 2
done

chmod 400 /home/ec2-user/.ssh/id_rsa