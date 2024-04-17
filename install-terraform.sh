#!/bin/bash

# This script installs Terraform on Amazon Linux using HashiCorp's official repository

# Fail on any error
set -eu

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Install yum-config-manager to manage your repositories
echo "Installing yum-utils..."
sudo yum install -y yum-utils

# Use yum-config-manager to add the official HashiCorp Linux repository
echo "Adding HashiCorp repository..."
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Update system to refresh repository links
echo "Updating system..."
sudo yum update -y

# Install Terraform
echo "Installing Terraform..."
sudo yum -y install terraform

# Verify installation
echo "Verifying Terraform installation..."
terraform --version
