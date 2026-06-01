terraform {
    backend "s3" {
    bucket = "mybucketebadkhan1234323"
    key    = "dev4/terraform.tfstate"
    region = "eu-north-1"
  }
   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region = "eu-north-1"
}


resource "aws_s3_bucket" "website" {
  bucket = "my-static-site-123456789jdkshjdsjfksdfsdkjfksdksdhf"
}
