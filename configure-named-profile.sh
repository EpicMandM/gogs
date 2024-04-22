#!/bin/bash

# Fail on any error
set -eu

# Configure named profile
aws configure set aws_access_key_id $AWS_ACCESS_KEY --profile $PROFILE_NAME 
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $PROFILE_NAME 
aws configure set region $AWS_REGION --profile $PROFILE_NAME

# Verify that profile is configured
aws configure list --profile $PROFILE_NAME