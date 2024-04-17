#!/bin/bash

# fail on any error
set -eu

terraform init -backend-config="access_key=$AWS_ACCESS_KEY" -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"

terraform destroy -auto-approve

terraform apply -auto-approve -target=aws_ec2_transit_gateway.example_tgw 
terraform apply -auto-approve -target=aws_vpc.gogs_vpc
terraform apply -auto-approve -target=aws_subnet.gogs_public_subnet
terraform apply -auto-approve -target=aws_subnet.gogs_private_subnet

terraform apply -auto-approve