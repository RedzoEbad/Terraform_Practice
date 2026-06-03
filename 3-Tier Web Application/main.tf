terraform {
  backend "s3" {
    bucket = "mybucketebadkhan1234323"
    key    = "tierApplication/terraform.tfstate"
    region = "eu-north-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
   tags = {
    Name = "main-vpc"
  }
}