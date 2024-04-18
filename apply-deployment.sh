#!/bin/bash

# fail on any error
set -eu

terraform init -backend-config="access_key=$AWS_ACCESS_KEY" -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"

terraform destroy -auto-approve

#terraform apply -auto-approve