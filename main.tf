provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "gogs-terraform-state"
    key     = "build/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform"
  }
}

resource "aws_iam_role" "gogs-for-ec2" {
  name = "gogs-for-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "ec2_secrets_role" {
  name = "EC2SecretsManagerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "efs_access_policy" {
  name        = "EFSAccessPolicy"
  description = "Policy to allow EC2 instances to access EFS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "SecretsManagerAccessPolicy"
  description = "Policy to access specific secrets in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource  = "arn:aws:secretsmanager:us-east-1:577317039358:secret:app-key-pair-OtDRMy"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_full_access_policy" {
  name        = "EC2FullAccessPolicy"
  description = "Policy granting full access to EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ec2:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_access_attach" {
  role       = aws_iam_role.gogs-for-ec2.name
  policy_arn = aws_iam_policy.efs_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_full_access_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.ec2_full_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "secrets_policy_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
}

resource "aws_iam_role_policy_attachment" "secrets_policy_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
}


resource "aws_iam_policy_attachment" "ec2-full-access" {
  name       = "ec2-full-access-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  roles      = [aws_iam_role.gogs-for-ec2.name]
}

resource "aws_iam_instance_profile" "gogs-for-ec2" {
  name = "gogs-for-ec2-instance-profile"
  role = aws_iam_role.gogs-for-ec2.name
}

resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "EC2SecretsInstanceProfile"
  role = aws_iam_role.ec2_secrets_role.name
}

resource "aws_vpc" "gogs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "gogs_public_subnet" {
  vpc_id                  = aws_vpc.gogs_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "gogs_private_subnet" {
  vpc_id     = aws_vpc.gogs_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "gogs_gw" {
  vpc_id = aws_vpc.gogs_vpc.id
}

resource "aws_route_table" "gogs_public_route_table" {
  vpc_id = aws_vpc.gogs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gogs_gw.id
  }
}

resource "aws_route_table_association" "gogs_public_route_association" {
  subnet_id      = aws_subnet.gogs_public_subnet.id
  route_table_id = aws_route_table.gogs_public_route_table.id
}

resource "aws_eip" "nat_gateway_eip" {
}

resource "aws_nat_gateway" "gogs_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.gogs_public_subnet.id
  depends_on    = [aws_internet_gateway.gogs_gw]
}

resource "aws_route_table" "gogs_private_route_table" {
  vpc_id = aws_vpc.gogs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gogs_nat_gateway.id
  }
}

resource "aws_route_table_association" "gogs_private_route_association" {
  subnet_id      = aws_subnet.gogs_private_subnet.id
  route_table_id = aws_route_table.gogs_private_route_table.id
}


resource "aws_security_group" "lb_security_group" {
  name        = "lb-security-group"
  description = "Security group for EC2 Load Balancer"
  vpc_id      = aws_vpc.gogs_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Load Balancer Security Group"
  }
}


resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.gogs_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2 Security Group"
  }
}


resource "aws_security_group_rule" "allow_nfs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_security_group.id
  cidr_blocks       = [aws_vpc.gogs_vpc.cidr_block]  # Adjust as necessary
}

resource "aws_efs_file_system" "nfs_shares" {
  creation_token = "nfs_shares"

  tags = {
    Name = "nfs_shares"
  }
}

resource "aws_efs_mount_target" "nfs_shares_targets" {
  for_each           = { for subnet in [aws_subnet.gogs_private_subnet] : subnet.id => subnet }
  file_system_id     = aws_efs_file_system.nfs_shares.id
  subnet_id          = each.value.id
  security_groups    = [aws_security_group.ec2_security_group.id]
}


resource "aws_instance" "lb1" {
  ami                         = "ami-051f8a213df8bc089"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.gogs_public_subnet.id
  key_name                    = "app-key-pair"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.lb_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.gogs-for-ec2.name

  tags = {
    Role = "lb"
    Name = "lb1"
  }
}

resource "aws_instance" "db1" {
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.gogs_private_subnet.id
  key_name               = "app-key-pair"
  iam_instance_profile   = aws_iam_instance_profile.gogs-for-ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tags = {
    Role = "db"
    Name = "db1"
  }
}

resource "aws_instance" "appgogs" {
  count                  = 2
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.gogs_private_subnet.id
  key_name               = "app-key-pair"
  iam_instance_profile   = aws_iam_instance_profile.gogs-for-ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tags = {
    Role = "app"
    Name = "appgogs-${count.index + 1}"
  }
}

resource "aws_instance" "ansible-control-node" {
  ami                         = "ami-051f8a213df8bc089"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.gogs_public_subnet.id
  key_name                    = "app-key-pair"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.lb_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_secrets_profile.name

  user_data = filebase64("${path.module}/install-ansible.sh")
}
