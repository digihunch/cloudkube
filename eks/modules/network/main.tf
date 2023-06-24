resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags                 = merge(var.resource_tags, { Name = "${var.resource_prefix}-MainVPC" })
}

resource "aws_default_security_group" "defaultsg" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.resource_tags, { Name = "${var.resource_prefix}-DefaultSG" })
}

resource "aws_subnet" "publicsubnets" {
  count                   = length(var.public_subnets_cidr_list)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnets_cidr_list[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.this.names[count.index]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-PublicSubnet${count.index}", "kubernetes.io/role/elb" = 1 })
}

resource "aws_subnet" "internalsvcsubnets" {
  count                   = length(var.internalsvc_subnets_cidr_list)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.internalsvc_subnets_cidr_list[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.this.names[count.index]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-InternalServiceSubnet${count.index}", "kubernetes.io/role/internal-elb" = 1 })
}

resource "aws_subnet" "datasvcsubnets" {
  count                   = length(var.datasvc_subnets_cidr_list)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.datasvc_subnets_cidr_list[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.this.names[count.index]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-DataServiceSubnet${count.index}" })
}

resource "aws_subnet" "nodesubnets" {
  count                   = length(var.node_subnets_cidr_list)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.node_subnets_cidr_list[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.this.names[count.index]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-NodeSubnet${count.index}" })
}

resource "aws_subnet" "podsubnets" {
  count                   = length(var.pod_subnets_cidr_list)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.pod_subnets_cidr_list[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.this.names[count.index]
  tags                    = merge(var.resource_tags, { Name = "${var.resource_prefix}-PodSubnet${count.index}" })
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.resource_tags, { Name = "${var.resource_prefix}-InternetGateway" })
}

resource "aws_eip" "nat_eips" {
  count = length(var.public_subnets_cidr_list)
}

resource "aws_nat_gateway" "nat_gws" {
  count         = length(var.public_subnets_cidr_list)
  subnet_id     = aws_subnet.publicsubnets[count.index].id
  allocation_id = aws_eip.nat_eips[count.index].id
  depends_on    = [aws_internet_gateway.internet_gw]
  tags          = merge(var.resource_tags, { Name = "${var.resource_prefix}-NATGateway${count.index}" })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.resource_tags, { Name = "${var.resource_prefix}-PublicRouteTable" })
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
  count          = length(var.public_subnets_cidr_list)
  subnet_id      = aws_subnet.publicsubnets[count.index].id 
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "priv2nat_subnet_route_tables" {
  vpc_id = aws_vpc.eks_vpc.id
  count  = length(var.public_subnets_cidr_list)
  tags   = merge(var.resource_tags, { Name = "${var.resource_prefix}-PrivateToNATSubnetRouteTable${count.index}" })
}

resource "aws_route" "node_route_nat_gateways" {
  count                  = length(var.public_subnets_cidr_list)
  route_table_id         = aws_route_table.priv2nat_subnet_route_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gws[count.index].id
}

resource "aws_route_table_association" "node_rt_assocs" {
  count          = length(resource.aws_subnet.nodesubnets)
  subnet_id      = resource.aws_subnet.nodesubnets[count.index].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[count.index].id
}
resource "aws_route_table_association" "internalsvc_rt_assocs" {
  count          = length(resource.aws_subnet.internalsvcsubnets)
  subnet_id      = resource.aws_subnet.internalsvcsubnets[count.index].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[count.index].id
}
resource "aws_route_table_association" "datasvc_rt_assocs" {
  count          = length(resource.aws_subnet.datasvcsubnets)
  subnet_id      = resource.aws_subnet.datasvcsubnets[count.index].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[count.index].id
}
resource "aws_route_table_association" "pod_rt_assocs" {
  count          = length(resource.aws_subnet.podsubnets)
  subnet_id      = resource.aws_subnet.podsubnets[count.index].id
  route_table_id = aws_route_table.priv2nat_subnet_route_tables[count.index].id
}
