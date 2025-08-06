resource "aws_subnet" "trend_subnet_a" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.10.0/24"  # Changed
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = { Name = "trend-subnet-a" }
}

resource "aws_subnet" "trend_subnet_b" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.20.0/24"  # Changed
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = { Name = "trend-subnet-b" }
}

