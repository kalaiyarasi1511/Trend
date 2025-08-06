provider "aws" {
  region = "ap-south-1"
}

# ------------------------------
# VPC
# ------------------------------
resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "trend-vpc"
  }
}

# ------------------------------
# Subnet
# ------------------------------
resource "aws_subnet" "trend_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "trend-subnet"
  }
}

# ------------------------------
# Internet Gateway
# ------------------------------
resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id
  tags = {
    Name = "trend-igw"
  }
}

# ------------------------------
# Route Table & Route
# ------------------------------
resource "aws_route_table" "trend_rtb" {
  vpc_id = aws_vpc.trend_vpc.id
  tags = {
    Name = "trend-rtb"
  }
}

resource "aws_route" "trend_route" {
  route_table_id         = aws_route_table.trend_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.trend_igw.id
}

resource "aws_route_table_association" "trend_rta" {
  subnet_id      = aws_subnet.trend_subnet.id
  route_table_id = aws_route_table.trend_rtb.id
}

# ------------------------------
# IAM Role for EKS Cluster
# ------------------------------
resource "aws_iam_role" "eks_role" {
  name = "trend-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attach" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------
# EKS Cluster
# ------------------------------
resource "aws_eks_cluster" "trend_cluster" {
  name     = "trend-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [aws_subnet.trend_subnet.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy_attach]
}

# ------------------------------
# IAM Role for EKS Nodes
# ------------------------------
resource "aws_iam_role" "node_role" {
  name = "trend-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ------------------------------
# EKS Node Group
# ------------------------------
resource "aws_eks_node_group" "trend_nodes" {
  cluster_name    = aws_eks_cluster.trend_cluster.name
  node_group_name = "trend-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.trend_subnet.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
}

# ------------------------------
# Jenkins EC2 Instance
# ------------------------------
resource "aws_instance" "jenkins_ec2" {
  ami                         = "ami-0dee22c13ea7a9a67" # Amazon Linux 2023 (ap-south-1)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.trend_subnet.id
  associate_public_ip_address = true
  key_name                    = "linux-ssh-key"

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
