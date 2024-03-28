#!/bin/bash

# fail on any error
set -eu

# go back to the previous directory

# initialize terraform
terraform init -backend-config="access_key=$AWS_ACCESS_KEY" -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"

# # apply terraform
terraform apply -auto-approve

# destroy terraform
# terraform destroy -auto-approve