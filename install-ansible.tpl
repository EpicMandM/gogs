#!/bin/bash

# Script to install and configure Ansible on Amazon Linux

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Update the system
echo "Updating the system..."
yum update -y

echo "Installing Python3 and pip..."
yum install -y python3 python3-pip

echo "Installing Ansible and dependencies..."
pip3 install ansible boto3 botocore

echo "Verifying Ansible installation..."
ansible --version

echo "Installing git..."
yum install -y git

echo "Cloning repository and configuring SSH key..."
git clone https://github.com/EpicMandM/gogs.git && cd gogs
aws secretsmanager get-secret-value --secret-id app-key-pair | jq -r '.SecretString' > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

export VAULT_PASSWORD='${vault_password}'

echo "Running Ansible playbook..."
ansible-playbook -i inventory/aws_ec2.yml -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' --vault-password-file=<(echo "$vault_password") site.yml

echo "Script completed successfully."
