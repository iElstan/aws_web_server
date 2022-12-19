#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install ansible2 -y
sudo yum install mysql -y
cat <<EOF > /etc/ansible/ansible.cfg
[defaults]
host_key_checking = false
inventory = /home/ec2-user/hosts
EOF
aws s3 cp s3://rpeklov-webserver-data/ /home/ec2-user/ --recursive
sudo chown ec2-user:ec2-user /home/ec2-user/*
mv /home/ec2-user/id_rsa /home/ec2-user/.ssh/
sudo chmod 600 /home/ec2-user/.ssh/id_rsa
