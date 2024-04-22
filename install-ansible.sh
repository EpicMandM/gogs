echo "Cloning repository and configuring SSH key..."
git clone https://github.com/EpicMandM/gogs.git
cd gogs
aws secretsmanager get-secret-value --secret-id app-key-pair | jq -r '.SecretString' > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

VAULT_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ansible-vault-password --query 'SecretString' --output text)

if [ $? -ne 0 ]; then
    echo "Failed to retrieve the vault password from AWS Secrets Manager"
    exit 1
fi

echo "Running Ansible playbook..."
ansible-playbook -i inventory/aws_ec2.yml -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' --vault-password-file=<(echo "$VAULT_PASSWORD") site.yml

if [ $? -ne 0 ]; then
    echo "Ansible playbook execution failed."
    exit 1
fi

echo "Script completed successfully."
