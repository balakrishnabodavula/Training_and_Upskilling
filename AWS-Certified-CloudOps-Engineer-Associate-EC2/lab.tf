resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Lab-VPC"
  })
}

resource "aws_subnet" "lab_public" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Lab-Public-Subnet"
    Type = "Public"
  })
}

resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Lab-IGW"
  })
}

resource "aws_route_table" "lab_public_rt" {
  vpc_id = aws_vpc.lab_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Lab-Public-RT"
  })
}

resource "aws_route_table_association" "lab_public_rta" {
  subnet_id      = aws_subnet.lab_public.id
  route_table_id = aws_route_table.lab_public_rt.id
}