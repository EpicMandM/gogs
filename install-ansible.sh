#!/bin/bash

# This script installs Ansible on Amazon Linux 2023

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the system
echo "Updating the system..."
yum update -y

# Install Python if not installed (Ansible dependency)
echo "Checking and installing Python..."
yum install python3 -y

# Install pip for Python3 if not installed
echo "Checking and installing pip..."
yum install python3-pip -y

# Install Ansible via pip
echo "Installing Ansible..."
pip3 install ansible

# Verify installation
echo "Verifying Ansible installation..."
ansible --version
