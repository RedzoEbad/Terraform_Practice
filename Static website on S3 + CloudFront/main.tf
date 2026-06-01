terraform {
    backend "s3" {
    bucket = "mybucketebadkhan1234323"
    key    = "terraform.tfstate"
    region = "eu-north-1"
  }
   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}
provider "aws" {
  region = "eu-north-1"
}


