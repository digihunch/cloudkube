resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = merge(var.resource_tags,{ Name="Vpc" })
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.mgmt_subnet_cidr_block
  map_public_ip_on_launch = true
  tags = merge(var.resource_tags,{ Name="MgmtSubnet" })
}

resource "aws_subnet" "nodesubnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.node_subnet_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = merge(var.resource_tags,{ Name="NodeSubnet" })
}

resource "aws_subnet" "podsubnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.pod_subnet_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = merge(var.resource_tags,{ Name="PodSubnet" })
}

resource "aws_internet_gateway" "maingw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = var.resource_tags
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.maingw.id
  }
}

resource "aws_route_table_association" "pubsub_rt_assoc" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_main_route_table_association" "vpc_rt_assoc" {
  vpc_id         = aws_vpc.eks_vpc.id
  route_table_id = aws_route_table.public_route_table.id
}
