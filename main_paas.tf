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

resource "aws_elastic_beanstalk_application" "gogs" {
  name        = "gogs"
  description = "gogs"
}


resource "aws_elastic_beanstalk_environment" "gogs" {
  name                = "gogs"
  application         = aws_elastic_beanstalk_application.gogs.name
  solution_stack_name = "64bit Amazon Linux 2 v3.9.0 running Go 1"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.gogs-for-ec2.name
  }

}



    