#!/bin/bash

# This script installs Ansible on Amazon Linux 2023 and configures an environment by cloning a repository and running an Ansible playbook.

# Ensures the script is executed with root privileges.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Updates the system packages to the latest versions.
echo "Updating the system..."
if ! yum update -y; then
    echo "Failed to update the system. Exiting."
    exit 1
fi

# Installs Python3 if it is not already installed, as it is required by Ansible.
echo "Checking for Python3 and installing if not present..."
if ! yum install python3 -y; then
    echo "Failed to install Python3. Exiting."
    exit 1
fi

# Installs pip, the Python package installer, needed to install Ansible.
echo "Ensuring pip is installed..."
if ! yum install python3-pip -y; then
    echo "Failed to install pip. Exiting."
    exit 1
fi

# Installs Ansible and its dependencies using pip.
echo "Installing Ansible and its dependencies..."
if ! pip3 install ansible botocore boto3; then
    echo "Failed to install Ansible or its dependencies. Exiting."
    exit 1
fi

# Verifies the installation of Ansible.
echo "Verifying Ansible installation..."
if ! ansible --version; then
    echo "Ansible installation verification failed. Exiting."
    exit 1
fi

# Installs git to enable cloning of repositories.
echo "Installing git..."
if ! yum install git -y; then
    echo "Failed to install git. Exiting."
    exit 1
fi

# Clones the specified repository and navigates into the directory.
echo "Cloning repository and changing to directory..."
if ! git clone https://github.com/EpicMandM/gogs.git || ! cd gogs; then
    echo "Failed to clone repository or change directory. Exiting."
    exit 1
fi

# Fetches SSH key from AWS Secrets Manager and configures it for use.
echo "Configuring SSH key for repository access..."
SSH_KEY=$(aws secretsmanager get-secret-value --secret-id app-key-pair | jq -r '.SecretString')
if [ -z "$SSH_KEY" ]; then
    echo "Failed to retrieve SSH key. Exiting."
    exit 1
fi
echo "$SSH_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Executes the Ansible playbook with a specific inventory and extra arguments.
# echo "Running Ansible playbook..."
# if ! ansible-playbook -i inventory/aws_ec2.yml -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' site.yml; then
#     echo "Failed to execute Ansible playbook. Exiting."
#     exit 1
# fi

# echo "Script completed successfully."
