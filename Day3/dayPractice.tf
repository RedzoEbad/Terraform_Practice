terraform {
  backend "s3" {
    bucket       = "mybucketbadkhan1234323"
    key          = "devnew/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ✅ FIX: Proper AMI lookup using SSM
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_s3_bucket" "example" {
  count  = var.counts
  bucket = var.bucket_name

  tags = {
    Environment = var.env
  }
}

resource "aws_instance" "example" {
  count         = 2
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}

variable "counts" {
  type = number

  validation {
    condition     = var.counts <= 5
    error_message = "not allowed only 5 allowed"
  }
}

variable "bucket_name" {
  type    = string
  default = "helodnsfgsdjfkdjfksdfjdk"
}

variable "env" {
  type = string

  validation {
    condition     = contains(["prod", "dev"], var.env)
    error_message = "not allowed"
  }
}