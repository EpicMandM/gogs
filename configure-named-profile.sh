#!/bin/bash

# Fail on any error
set -eu

# Configure named profile
aws configure set aws_access_key_id $AWS_ACCESS_KEY --profile $PROFILE_NAME 
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $PROFILE_NAME 
aws configure set region $AWS_REGION --profile $PROFILE_NAME

# Verify that profile is configured
aws configure list --profile $PROFILE_NAME

echo "Retrieving SSH key from Secrets Manager"

SSH_KEY=$(aws secretsmanager get-secret-value --secret-id app-key-pair | jq -r '.SecretString')

echo "$SSH_KEY" > ~/.ssh/id_rsa

chmod 600 ~/.ssh/id_rsa