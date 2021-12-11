resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags                 = merge(var.resource_tags, { Name = "${var.resource_prefix}-MainVPC" })
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.mgmt_subnet_cidr_block
  map_public_ip_on_launch = true
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-MgmtSubnet" })
}

resource "aws_subnet" "nodesubnet1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.node_subnet1_cidr_block
  #map_public_ip_on_launch = false
  map_public_ip_on_launch = true 
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-NodeSubnet1" })
}

resource "aws_subnet" "nodesubnet2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.node_subnet2_cidr_block
  #map_public_ip_on_launch = false
  map_public_ip_on_launch = true 
  availability_zone       = data.aws_availability_zones.available.names[2]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-NodeSubnet2" })
}

resource "aws_subnet" "podsubnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.pod_subnet_cidr_block
  #map_public_ip_on_launch = false
  map_public_ip_on_launch = true 
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-PodSubnet" })
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.resource_tags, { Name = "${var.resource_prefix}-InternetGateway" })
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.publicsubnet.id
  allocation_id = aws_eip.nat_eip.id
  depends_on    = [aws_internet_gateway.internet_gw]
  tags          = merge(var.resource_tags, { Name = "${var.resource_prefix}-NATGateway" })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-PublicRouteTable" })
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gw.id
}

resource "aws_main_route_table_association" "vpc_rt_assoc" {
  vpc_id         = aws_vpc.eks_vpc.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "pubsub_rt_assoc" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "node_subnet_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-NodeSubnetRouteTable" })
}

resource "aws_route" "node_route_nat_gateway" {
  route_table_id         = aws_route_table.node_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  #nat_gateway_id         = aws_nat_gateway.nat_gw.id
  gateway_id             = aws_internet_gateway.internet_gw.id
}

resource "aws_route_table_association" "node_rt_assoc_1" {
  subnet_id      = aws_subnet.nodesubnet1.id
  route_table_id = aws_route_table.node_subnet_route_table.id
}

resource "aws_route_table_association" "node_rt_assoc_2" {
  subnet_id      = aws_subnet.nodesubnet2.id
  route_table_id = aws_route_table.node_subnet_route_table.id
}

resource "aws_route_table" "pod_subnet_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-PodSubnetRouteTable" })
}

resource "aws_route" "pod_route_nat_gateway" {
  route_table_id         = aws_route_table.pod_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  #nat_gateway_id         = aws_nat_gateway.nat_gw.id
  gateway_id             = aws_internet_gateway.internet_gw.id
}

resource "aws_route_table_association" "pod_rt_assoc" {
  subnet_id      = aws_subnet.podsubnet.id
  route_table_id = aws_route_table.pod_subnet_route_table.id
}
