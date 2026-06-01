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


resource "aws_s3_bucket" "example1234" {
  bucket = "my-tf-test-bucket-12432434325432434343435233422"

  tags = {
    Name        = "My bucket-12344"
  }
}


variable "abc" {
  description = "my name is s3"
  type = list(string)
  default = ["s2ds-dsffsdfsfsdfddfvsv" , "sdfsdfg23_345gfdvfdgfgfgdfsgdf"]
}

resource "aws_s3_bucket" "example12345" {
  count = 2
  bucket = var.abc[count.index]

  tags = {
    Name        = "My bucket-12344"
  }
  
  depends_on = [aws_s3_bucket.example1234]
}


resource "aws_instance" "example" {
  ami           = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
    
  }
  depends_on = [aws_s3_bucket.example12345]
}



resource "aws_instance" "web" {
  ami  = "ami-12345678"
  instance_type = "t2.micro"

  lifecycle {
   prevent_destroy = true 
  }
}