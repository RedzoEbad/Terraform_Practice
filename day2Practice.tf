terraform {
  backend "s3" {
    bucket = "mybucketbadkhan1234323"
    key    = "dev/terraform.tfstate"
    region = "eu-north-1"
    use_lockfile = true 
  }
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
    Environment = "DEV"
  }
}

variable "env" {
  default = "dev"
  type = string
}

locals {
  env = var.env

}

resource "aws_s3_bucket" "example1234" {
  bucket = "my-tf-test-bucket-12432434325432434343435233422"

  tags = {
    Name        = "My bucket-12344"
    Environment = locals.env
  }
}


resource "aws_s3_bucket" "example1234" {
  bucket = "my-tf-test-bucket-12432434325432434343435233422"

  tags = {
    Name        = "My bucket-12344"
    Environment =  locals.env
  }
}