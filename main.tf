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
    cidr_blocks = ["10.0.0.0/16"]
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


resource "aws_instance" "lb1" {
  ami                         = "ami-051f8a213df8bc089"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.gogs_public_subnet.id
  key_name                    = "app-key-pair"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.lb_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.gogs-for-ec2.name

}

resource "aws_instance" "nfs1" {
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.gogs_private_subnet.id
  key_name               = "app-key-pair"
  iam_instance_profile   = aws_iam_instance_profile.gogs-for-ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}

resource "aws_instance" "db1" {
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.gogs_private_subnet.id
  key_name               = "app-key-pair"
  iam_instance_profile   = aws_iam_instance_profile.gogs-for-ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}

resource "aws_instance" "appgogs" {
  count                  = 2
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.gogs_private_subnet.id
  key_name               = "app-key-pair"
  iam_instance_profile   = aws_iam_instance_profile.gogs-for-ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}

data "template_file" "dev_hosts" {
  template = file("${path.module}/inventory/templates/hosts.cfg.tpl")

  vars = {
    nfs1_ip      = aws_instance.nfs1.private_ip
    db1_ip       = aws_instance.db1.private_ip
    lb1_ip       = aws_instance.lb1.public_ip
    appgogs_1_ip = aws_instance.appgogs[0].private_ip
    appgogs_2_ip = aws_instance.appgogs[1].private_ip
  }
}

resource "null_resource" "dev-hosts" {
  triggers = {
    template_rendered = data.template_file.dev_hosts.rendered
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.dev_hosts.rendered}' > ${path.module}/inventory/hosts.cfg"
  }
}

resource "aws_ec2_transit_gateway" "example_tgw" {
  description = "Transit Gateway for CodeBuild and EC2 instances communication"

  tags = {
    Name = "MyTransitGateway"
  }
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "default_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.example_tgw.id
  vpc_id             = data.aws_vpc.default.id
  subnet_ids         = data.aws_subnets.default.ids

  tags = {
    Name = "Default VPC Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "custom_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.example_tgw.id
  vpc_id             = aws_vpc.gogs_vpc.id
  subnet_ids         = [aws_subnet.gogs_public_subnet.id, aws_subnet.gogs_private_subnet.id]

  tags = {
    Name = "Custom VPC Attachment"
  }
}



data "aws_route_tables" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Route from default VPC to custom VPC
resource "aws_route" "default_to_ec2" {
  for_each               = toset(data.aws_route_tables.default.ids)
  route_table_id         = each.value
  destination_cidr_block = aws_vpc.gogs_vpc.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.example_tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.default_vpc_attachment, aws_ec2_transit_gateway_vpc_attachment.custom_vpc_attachment]
}

# Route from custom VPC to default VPC
resource "aws_route" "ec2_to_default" {
  route_table_id         = aws_route_table.gogs_public_route_table.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.example_tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.default_vpc_attachment, aws_ec2_transit_gateway_vpc_attachment.custom_vpc_attachment]
}
