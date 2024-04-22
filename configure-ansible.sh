#!/bin/bash

# Script to install and configure Ansible on Amazon Linux

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

yum install -y python3 python3-pip

echo "Installing Ansible and dependencies..."
pip3 install ansible boto3 botocore

echo "Verifying Ansible installation..."
ansible --version
if [ $? -ne 0 ]; then
    echo "Ansible installation failed."
    exit 1
fi


echo "Installing git..."
yum install -y git

echo "Script completed successfully."
