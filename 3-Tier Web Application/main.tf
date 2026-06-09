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

provider "aws" {
  region = "eu-north-1"
}

# =========================
# AMI
# =========================
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# =========================
# VPC
# =========================
resource "aws_vpc" "main" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "clean-vpc"
  }
}

# =========================
# Internet Gateway
# =========================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# =========================
# PUBLIC SUBNETS
# =========================
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
}

# =========================
# PRIVATE SUBNETS
# =========================
resource "aws_subnet" "private1" {
  vpc_id           = aws_vpc.main.id
  cidr_block       = "10.20.11.0/24"
  availability_zone = "eu-north-1a"
}

resource "aws_subnet" "private2" {
  vpc_id           = aws_vpc.main.id
  cidr_block       = "10.20.12.0/24"
  availability_zone = "eu-north-1b"
}

# =========================
# ROUTE TABLE (PUBLIC)
# =========================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

# =========================
# ROUTE TABLE (PRIVATE - CLEAN)
# =========================
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "priv1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "priv2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}

# =========================
# SECURITY GROUPS
# =========================
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =========================
# IAM ROLE
# =========================
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ssm-role-clean"

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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "profile" {
  name = "ec2-profile-clean"
  role = aws_iam_role.ec2_role.name
}

# =========================
# BACKEND EC2 (FIXED → PUBLIC SUBNET)
# =========================
resource "aws_instance" "backend" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  iam_instance_profile = aws_iam_instance_profile.profile.name

  user_data = <<EOF
#!/bin/bash
dnf update -y
dnf install -y git nodejs npm

cd /home/ec2-user
git clone https://github.com/RedzoEbad/Terraform_Practice.git app

cd app/3-Tier\ Web\ Application/backend

cat > .env <<EOT
PORT=5000
MONGODB_URI=mongodb+srv://Ebadkhan2002:ebad123@cluster1.jt8rzjs.mongodb.net/?appName=blogApp
NODE_ENV=production
EOT

npm install
nohup node server.js > app.log 2>&1 &
EOF

  tags = {
    Name = "backend-clean"
  }
}

# =========================
# TARGET GROUP
# =========================
resource "aws_lb_target_group" "tg" {
  name     = "app-tg-clean"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/todos"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.backend.id
  port             = 5000
}

# =========================
# ALB
# =========================
resource "aws_lb" "alb" {
  name               = "app-alb-clean"
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

}

output "alb_url" {
  value = aws_lb.alb.dns_name
}
output "cloudfront_url" {
  value = aws_cloudfront_distribution.frontend.domain_name
}