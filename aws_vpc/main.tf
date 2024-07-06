resource "aws_key_pair" "ssh-pubkey" {
  key_name   = "${var.resource_prefix}-ssh-pubkey"
  public_key = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "")
}

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
  count  = length(var.public_subnets_cidr_list)
  domain = "vpc"
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

resource "aws_route_table_association" "pubsub_rt_assoc" {
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


resource "aws_security_group" "bastionsecgrp" {
  name        = "${var.resource_prefix}-cloudkube-sg"
  description = "security group for bastion"
  vpc_id      = aws_vpc.eks_vpc.id

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-BastionSecurityGroup" })
}


resource "aws_iam_role" "bastion_instance_role" {
  name = "${var.resource_prefix}-bastion-inst-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-Bastion-Instance-Role" })
}

resource "aws_iam_policy" "bastion_eks_policy" {
  name        = "${var.resource_prefix}-bastion_eks_policy"
  description = "bastion to allow awscli administrative activities from instance role."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "eks:Describe*",
        "eks:List*",
        "appmesh:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:CreatePolicy",
        "iam:ListPolicies",
        "sts:DecodeAuthorizationMessage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_role_eks_policy_attachment" {
  role       = aws_iam_role.bastion_instance_role.name
  policy_arn = aws_iam_policy.bastion_eks_policy.arn
}

resource "aws_iam_role_policy_attachment" "bastion_role_ssm_policy_attachment" {
  role       = aws_iam_role.bastion_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "inst_profile" {
  name = "${var.resource_prefix}-inst-profile"
  role = aws_iam_role.bastion_instance_role.name
}

resource "aws_launch_template" "bastion_launch_template" {
  name          = "${var.resource_prefix}-bastion-launch-template"
  key_name      = aws_key_pair.ssh-pubkey.key_name
  instance_type = var.instance_type
  user_data     = data.cloudinit_config.bastion_cloudinit.rendered
  image_id      = var.preferred_ami_id != "" ? data.aws_ami.preferred_ami[0].id : data.aws_ami.default_ami.id

  iam_instance_profile {
    name = aws_iam_instance_profile.inst_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  block_device_mappings {
    device_name = var.preferred_ami_id != "" ? data.aws_ami.preferred_ami[0].root_device_name : data.aws_ami.default_ami.root_device_name
    ebs {
      volume_size = 100
      encrypted   = true
    }
  }
  vpc_security_group_ids = [aws_security_group.bastionsecgrp.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      prefix  = var.resource_prefix
      purpose = "bastion"
      Name    = "${var.resource_prefix}-bastion"
    }
  }
}

resource "aws_autoscaling_group" "bastion_host_asg" {
  vpc_zone_identifier = aws_subnet.internalsvcsubnets[*].id
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  name                = "${var.resource_prefix}-bastion-asg"

  launch_template {
    id      = aws_launch_template.bastion_launch_template.id
    version = aws_launch_template.bastion_launch_template.latest_version
  }
}

