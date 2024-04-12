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

resource "aws_db_instance" "gogs_db" {
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "postgres"
  engine_version      = "15.4"
  instance_class      = "db.t3.micro"
  identifier          = "gogs"
  username            = var.db_username
  password            = var.db_password
  skip_final_snapshot = true
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

resource "aws_iam_policy_attachment" "administrator-access" {
  name       = "administrator-access-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk"
  roles      = [aws_iam_role.gogs-for-ec2.name]
}

resource "aws_iam_policy_attachment" "ec2-full-access" {
  name       = "ec2-full-access-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  roles      = [aws_iam_role.gogs-for-ec2.name]
}

resource "aws_iam_policy_attachment" "elasticbeanstalk-web-tier" {
  name       = "elasticbeanstalk-web-tier-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  roles      = [aws_iam_role.gogs-for-ec2.name]
}

resource "aws_iam_instance_profile" "gogs-for-ec2" {
  name = "gogs-for-ec2-instance-profile"
  role = aws_iam_role.gogs-for-ec2.name
}

resource "aws_vpc" "gogs_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "gogs_public_subnet" {
  vpc_id     = aws_vpc.gogs_vpc.id
  cidr_block = "10.0.1.0/24"
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

resource "aws_security_group" "lb_security_group" {
  name        = "lb-security-group"
  description = "Security group for EC2 Load Balancer"
  vpc_id      = aws_vpc.gogs_vpc.id

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

resource "aws_instance" "lb1" {
  ami                    = "ami-051f8a213df8bc089"  # Replace this with the actual AMI ID
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.gogs_public_subnet.id
  key_name               = "your-key-pair"  # Replace this with your key pair for SSH access
  associate_public_ip_address = true
  security_groups        = [aws_security_group.lb_security_group.id]

  iam_instance_profile   = aws_iam_instance_profile.gogs-for-ec2.name

}

resource "aws_instance" "nfs1" {
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.gogs_private_subnet.id
  iam_instance_profile = aws_iam_instance_profile.gogs-for-ec2.name
}

resource "aws_instance" "db1" {
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.gogs_private_subnet.id
  iam_instance_profile = aws_iam_instance_profile.gogs-for-ec2.name
}

resource "aws_instance" "appgogs" {
  count         = 2
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.gogs_private_subnet.id
  iam_instance_profile = aws_iam_instance_profile.gogs-for-ec2.name
}

# Output for Load Balancer public IP
output "lb_public_ip" {
  value = aws_instance.lb1.public_ip
}
