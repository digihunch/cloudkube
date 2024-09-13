locals {
  # Get Prefix Length from VPC CIDR
  vpc_pfxlen = parseint(regex("/(\\d+)$", var.vpc_config.vpc_cidr)[0], 10)

  # Calculate subnet size for each type of subnet per AZ, in the order of public subnet, internal subnet and node subnet
  subnet_sizes = [var.vpc_config.public_subnet_pfxlen - local.vpc_pfxlen, var.vpc_config.internalsvc_subnet_pfxlen - local.vpc_pfxlen, var.vpc_config.node_subnet_pfxlen - local.vpc_pfxlen, var.vpc_config.pod_subnet_pfxlen - local.vpc_pfxlen]

  # Calculate the Subnet CIDRs for each type of subnet, in all AZs
  subnet_cidrs = cidrsubnets(var.vpc_config.vpc_cidr, flatten([for i in range(var.vpc_config.az_count) : local.subnet_sizes])...)

  # For each type of subnet, build a list of CIDRs for the subnet type in all AZs 
  public_subnets_cidr_list   = [for idx, val in local.subnet_cidrs : val if idx % 4 == 0]
  internal_subnets_cidr_list = [for idx, val in local.subnet_cidrs : val if idx % 4 == 1]
  node_subnets_cidr_list     = [for idx, val in local.subnet_cidrs : val if idx % 4 == 2]
  pod_subnets_cidr_list      = [for idx, val in local.subnet_cidrs : val if idx % 4 == 3]
}

resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_config.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.resource_prefix}-MainVPC" }
}

resource "aws_default_security_group" "defaultsg" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = { Name = "${var.resource_prefix}-DefaultSG" }
}

data "aws_availability_zones" "this" {}

resource "aws_subnet" "public_subnets" {
  for_each = {
    for cidr in local.public_subnets_cidr_list :
    substr(data.aws_availability_zones.this.names[index(local.public_subnets_cidr_list, cidr)], -2, -1) => {
      subnet_cidr_block = cidr
      availability_zone = data.aws_availability_zones.this.names[index(local.public_subnets_cidr_list, cidr)]
    }
  }
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = each.value.availability_zone
  tags                    = { Name = "${var.resource_prefix}-PublicSubnet-${each.key}", "kubernetes.io/role/elb" = 1 }
}

resource "aws_subnet" "internal_subnets" {
  for_each = {
    for cidr in local.internal_subnets_cidr_list :
    substr(data.aws_availability_zones.this.names[index(local.internal_subnets_cidr_list, cidr)], -2, -1) => {
      subnet_cidr_block = cidr
      availability_zone = data.aws_availability_zones.this.names[index(local.internal_subnets_cidr_list, cidr)]
    }
  }
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = each.value.availability_zone
  tags                    = { Name = "${var.resource_prefix}-InternalServiceSubnet-${each.key}", "kubernetes.io/role/internal-elb" = 1 }
}

resource "aws_subnet" "node_subnets" {
  for_each = {
    for cidr in local.node_subnets_cidr_list :
    substr(data.aws_availability_zones.this.names[index(local.node_subnets_cidr_list, cidr)], -2, -1) => {
      subnet_cidr_block = cidr
      availability_zone = data.aws_availability_zones.this.names[index(local.node_subnets_cidr_list, cidr)]
    }
  }

  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = each.value.availability_zone
  tags                    = { Name = "${var.resource_prefix}-NodeSubnet-${each.key}" }
}

resource "aws_subnet" "pod_subnets" {
  for_each = {
    for cidr in local.pod_subnets_cidr_list :
    substr(data.aws_availability_zones.this.names[index(local.pod_subnets_cidr_list, cidr)], -2, -1) => {
      subnet_cidr_block = cidr
      availability_zone = data.aws_availability_zones.this.names[index(local.pod_subnets_cidr_list, cidr)]
    }
  }
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = each.value.availability_zone
  tags                    = { Name = "${var.resource_prefix}-PodSubnet-${each.key}" }
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = { Name = "${var.resource_prefix}-InternetGateway" }
}

resource "aws_eip" "nat_eips" {
  for_each = aws_subnet.public_subnets
}

resource "aws_nat_gateway" "nat_gws" {
  for_each      = aws_subnet.public_subnets
  subnet_id     = aws_subnet.public_subnets[each.key].id
  allocation_id = aws_eip.nat_eips[each.key].id
  depends_on    = [aws_internet_gateway.internet_gw]
  tags          = { Name = "${var.resource_prefix}-NATGateway${each.key}" }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = { Name = "${var.resource_prefix}-PublicRouteTable" }
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

resource "aws_route_table_association" "pubsub_rt_assocs" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "priv2nat_subnet_route_tables" {
  for_each = aws_subnet.public_subnets
  vpc_id   = aws_vpc.eks_vpc.id
  tags     = { Name = "${var.resource_prefix}-PrivateToNATSubnetRouteTable${each.key}" }
}

resource "aws_route" "node_route_nat_gateways" {
  for_each               = aws_route_table.priv2nat_subnet_route_tables
  route_table_id         = aws_route_table.priv2nat_subnet_route_tables[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gws[each.key].id
}

resource "aws_route_table_association" "node_rt_assocs" {
  for_each       = aws_subnet.node_subnets
  subnet_id      = resource.aws_subnet.node_subnets[each.key].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[each.key].id
}
resource "aws_route_table_association" "internalsvc_rt_assocs" {
  for_each       = aws_subnet.internal_subnets
  subnet_id      = resource.aws_subnet.internal_subnets[each.key].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[each.key].id
}
resource "aws_route_table_association" "pod_rt_assocs" {
  for_each       = aws_subnet.pod_subnets
  subnet_id      = resource.aws_subnet.pod_subnets[each.key].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[each.key].id
}
