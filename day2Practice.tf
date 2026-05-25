terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "example123" {
  bucket = "my-tf-test-bucket-124324343254324343434352334"

  tags = {
    Name        = "My bucket-12344"
    Environment = "Dev1231234"
  }
}