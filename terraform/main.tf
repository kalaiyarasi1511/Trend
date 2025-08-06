provider "aws" {
  region = "ap-south-1"
}

# VPC
resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "trend-vpc"
  }
}

# Subnet
resource "aws_subnet" "trend_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "trend-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id
}

# Route Table
resource "aws_route_table" "trend_rtb" {
  vpc_id = aws_vpc.trend_vpc.id
}

# Route
resource "aws_route" "trend_route" {
  route_table_id         = aws_route_table.trend_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.trend_igw.id
}

# Route Table Association
resource "aws_route_table_association" "trend_rta" {
  subnet_id      = aws_subnet.trend_subnet.id
  route_table_id = aws_route_table.trend_rtb.id
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins_ec2" {
  ami           = "ami-0dee22c13ea7a9a67" # Amazon Linux 2023
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.trend_subnet.id
  associate_public_ip_address = true
  key_name      = "linux-ssh-key" # Your key pair name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-17-amazon-corretto docker git
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              amazon-linux-extras install epel -y
              yum install -y jenkins
              systemctl start jenkins
              systemctl enable jenkins
              EOF

  tags = {
    Name = "trend-jenkins"
  }
}
