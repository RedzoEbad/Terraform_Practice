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

# =====================================================
# VPC
# =====================================================
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# =====================================================
# INTERNET GATEWAY
# =====================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# =====================================================
# PUBLIC SUBNETS (WEB TIER)
# =====================================================
resource "aws_subnet" "public_web_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-web-az1"
  }
}

resource "aws_subnet" "public_web_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-web-az2"
  }
}

# =====================================================
# PRIVATE SUBNETS (APP TIER)
# =====================================================
resource "aws_subnet" "private_app_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "private-app-az1"
  }
}

resource "aws_subnet" "private_app_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "private-app-az2"
  }
}

# =====================================================
# PRIVATE SUBNETS (DB TIER)
# =====================================================
resource "aws_subnet" "private_db_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "private-db-az1"
  }
}

resource "aws_subnet" "private_db_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "private-db-az2"
  }
}

# =====================================================
# PUBLIC ROUTE TABLE
# =====================================================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# =====================================================
# PRIVATE ROUTE TABLES (AZ AWARE FIX)
# =====================================================
resource "aws_route_table" "private_app_rt_az1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-app-rt-az1"
  }
}

resource "aws_route_table" "private_app_rt_az2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-app-rt-az2"
  }
}

resource "aws_route_table" "private_db_rt_az1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-rt-az1"
  }
}

resource "aws_route_table" "private_db_rt_az2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-rt-az2"
  }
}

# =====================================================
# EIPS FOR NAT GATEWAYS
# =====================================================
resource "aws_eip" "nat_az1" {
  domain = "vpc"
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"
}

# =====================================================
# NAT GATEWAYS
# =====================================================
resource "aws_nat_gateway" "nat_az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_web_az1.id

  tags = {
    Name = "nat-az1"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_web_az2.id

  tags = {
    Name = "nat-az2"
  }

  depends_on = [aws_internet_gateway.igw]
}

# =====================================================
# ROUTES (APP TIER FIXED PER AZ)
# =====================================================
resource "aws_route" "app_az1_default" {
  route_table_id         = aws_route_table.private_app_rt_az1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az1.id
}

resource "aws_route" "app_az2_default" {
  route_table_id         = aws_route_table.private_app_rt_az2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az2.id
}

# =====================================================
# ROUTES (DB TIER FIXED PER AZ)
# =====================================================
resource "aws_route" "db_az1_default" {
  route_table_id         = aws_route_table.private_db_rt_az1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az1.id
}

resource "aws_route" "db_az2_default" {
  route_table_id         = aws_route_table.private_db_rt_az2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az2.id
}

# =====================================================
# ROUTE TABLE ASSOCIATIONS
# =====================================================
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_web_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_web_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "app_az1" {
  subnet_id      = aws_subnet.private_app_az1.id
  route_table_id = aws_route_table.private_app_rt_az1.id
}

resource "aws_route_table_association" "app_az2" {
  subnet_id      = aws_subnet.private_app_az2.id
  route_table_id = aws_route_table.private_app_rt_az2.id
}

resource "aws_route_table_association" "db_az1" {
  subnet_id      = aws_subnet.private_db_az1.id
  route_table_id = aws_route_table.private_db_rt_az1.id
}

resource "aws_route_table_association" "db_az2" {
  subnet_id      = aws_subnet.private_db_az2.id
  route_table_id = aws_route_table.private_db_rt_az2.id
}

# =====================================================
# SECURITY GROUPS (UNCHANGED - CORRECT)
# =====================================================
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
  name        = "app-sg"
  description = "Allow traffic only from web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow DB access only from app tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}