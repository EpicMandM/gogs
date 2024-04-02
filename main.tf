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
    
 setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBAllocatedStorage"
    value     = "10"
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBDeletionPolicy"
    value     = "Delete"
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "HasCoupledDatabase"
    value     = "true"
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBEngine"
    value     = "postgres"
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBEngineVersion"
    value     = "15.4"
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBInstanceClass"
    value     = "db.t3.micro"
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBPassword"
    value     = var.db_password
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBUser"
    value     = var.db_username
  }
  }


}


    