#!/bin/bash
set -x
#6663c1e1-a95c-42b9-afe0-b21971f62a35
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
yum -y update

echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
service sshd restart

yum -y install curl git iputils check-update gcc wget libcurl openssl unzip python3-distutils jq build-essential python36 python36-pip python3-venv ruby
curl -O https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
rm -f get-pip.py

while [ ! -f /home/ec2-user/.ssh/id_rsa ]
do
  sleep 2
done

chmod 400 /home/ec2-user/.ssh/id_rsa

cd /home/ec2-user
wget https://aws-codedeploy-eu-north-1.s3.eu-north-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
service codedeploy-agent start

mkdir flaskapp
cd flaskapp
python3 -m venv venv
source venv/bin/activate
pip install flask

git clone https://github.com/SaxProfanityBandit/learning-terraform-for-aws.git
export FLASK_APP=learning-terraform-for-aws/index.py
export FLASK_ENV=development

flask run