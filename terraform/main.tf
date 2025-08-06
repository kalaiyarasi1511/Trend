provider "aws" {
  region = "ap-south-1"
}

# -----------------------
# VPC
# -----------------------
resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "trend-vpc" }
}

# -----------------------
# Subnets (Two AZs)
# -----------------------
resource "aws_subnet" "trend_subnet_a" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = { Name = "trend-subnet-a" }
}

resource "aws_subnet" "trend_subnet_b" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = { Name = "trend-subnet-b" }
}

# -----------------------
# Internet Gateway & Route
# -----------------------
resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id
  tags   = { Name = "trend-igw" }
}

resource "aws_route_table" "trend_rtb" {
  vpc_id = aws_vpc.trend_vpc.id
  tags   = { Name = "trend-rtb" }
}

resource "aws_route" "trend_route" {
  route_table_id         = aws_route_table.trend_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.trend_igw.id
}

resource "aws_route_table_association" "trend_rta_a" {
  subnet_id      = aws_subnet.trend_subnet_a.id
  route_table_id = aws_route_table.trend_rtb.id
}

resource "aws_route_table_association" "trend_rta_b" {
  subnet_id      = aws_subnet.trend_subnet_b.id
  route_table_id = aws_route_table.trend_rtb.id
}

# -----------------------
# IAM Roles
# -----------------------
resource "aws_iam_role" "eks_role" {
  name = "trend-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node_role" {
  name = "trend-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  role       = aws_iam_role.node_role.name
  policy_arn = each.value
}

# -----------------------
# EKS Cluster
# -----------------------
resource "aws_eks_cluster" "trend_cluster" {
  name     = "trend-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids         = [aws_subnet.trend_subnet_a.id, aws_subnet.trend_subnet_b.id]
    endpoint_public_access = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# -----------------------
# EKS Node Group
# -----------------------
resource "aws_eks_node_group" "trend_nodes" {
  cluster_name    = aws_eks_cluster.trend_cluster.name
  node_group_name = "trend-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.trend_subnet_a.id, aws_subnet.trend_subnet_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  depends_on = [aws_eks_cluster.trend_cluster]
}

# -----------------------
# Jenkins EC2 Instance
# -----------------------
resource "aws_instance" "jenkins_ec2" {
  ami                    = "ami-0dee22c13ea7a9a67" # Amazon Linux 2023
  instance_type          = "t2.micro"
  key_name               = "linux-ssh-key"
  subnet_id              = aws_subnet.trend_subnet_a.id
  associate_public_ip_address = true

  tags = { Name = "trend-jenkins" }

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y java-17-amazon-corretto docker git
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    amazon-linux-extras enable jenkins
    amazon-linux-extras install epel -y
    yum install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOT
}

