resource "aws_iam_role" "eks_cluster_iam_role" {
  name               = "${var.resource_prefix}-eks-cluster-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags               = { Name = "${var.resource_prefix}-EKS-Cluster-Role" }
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "cluster_role_to_managed_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])
  role       = aws_iam_role.eks_cluster_iam_role.name
  policy_arn = each.value
}

data "aws_vpc" "eksVPC" {
  id = var.vpc_id
}

resource "aws_security_group" "cluster_security_group" {
  name        = "${var.resource_prefix}-cluster-sg"
  description = "security group for cluster"
  vpc_id      = var.vpc_id
  ingress {
    description = "inbound web traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.eksVPC.cidr_block]
  }
  egress {
    description = "outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.resource_prefix}-Cluster-SG" }
}

resource "aws_eks_cluster" "MainCluster" {
  name     = "${var.resource_prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_iam_role.arn
  vpc_config {
    subnet_ids              = var.node_subnet_ids
    security_group_ids      = compact([aws_security_group.cluster_security_group.id])
    endpoint_private_access = true
    endpoint_public_access  = false
  }
  version                   = var.kubernetes_version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  encryption_config {
    provider {
      key_arn = var.custom_key_arn
    }
    resources = ["secrets"]
  }
  tags       = { Name = "${var.resource_prefix}-Cluster" }
  depends_on = [aws_iam_role_policy_attachment.cluster_role_to_managed_policy]
}

resource "aws_eks_identity_provider_config" "ClusterOIDCConfig" {
  cluster_name = aws_eks_cluster.MainCluster.name

  oidc {
    identity_provider_config_name = "${var.resource_prefix}-eks-cluster-oidc-config"
    issuer_url                    = var.cognito_oidc_issuer_url
    client_id                     = var.cognito_oidc_client_id
    username_claim                = "email"
    groups_claim                  = "cognito:groups"
    groups_prefix                 = "gid:"
  }

  depends_on = [aws_eks_cluster.MainCluster]
}

resource "aws_eks_addon" "eks_main_addon" {
  cluster_name                = aws_eks_cluster.MainCluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "NONE"
  tags                        = { "eks_addon" = "vpc-cni" }
  depends_on                  = [aws_eks_cluster.MainCluster]
}

resource "aws_iam_role" "eks_node_iam_role" {
  name               = "${var.resource_prefix}-eks-node-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags               = { Name = "${var.resource_prefix}-EKS-Node-Role" }
}

resource "aws_iam_role_policy_attachment" "node_role_to_managed_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  role       = aws_iam_role.eks_node_iam_role.name
  policy_arn = each.value
}

resource "aws_launch_template" "eks_ng_lt" {
  for_each = { for ng in var.node_group_configs : ng.name => ng }
  name     = "${var.resource_prefix}-${each.value.name}-lt"
  key_name = var.ssh_pubkey_name
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.resource_prefix}-${each.value.name}-node-${each.value.cpu_arch}"
    }
  }
}

resource "aws_eks_node_group" "eks_ngs" {
  for_each        = { for ng in var.node_group_configs : ng.name => ng }
  cluster_name    = aws_eks_cluster.MainCluster.name
  node_group_name = "${var.resource_prefix}-eks-ng-${each.value.name}"
  node_role_arn   = aws_iam_role.eks_node_iam_role.arn
  instance_types  = [each.value.instance_type]
  ami_type        = each.value.ami_type
  subnet_ids      = var.node_subnet_ids
  labels = {
    cloudkube-node-group = "${each.value.name}"
  }

  # taint the arm64 nodes only
  dynamic "taint" {
    for_each = each.value.cpu_arch == "arm64" ? [1] : []
    content {
      key    = "arch"
      value  = "arm64"
      effect = "NO_SCHEDULE"
    }
  }
  scaling_config {
    desired_size = each.value.node_size_desired
    max_size     = each.value.node_size_max
    min_size     = each.value.node_size_min
  }
  update_config {
    max_unavailable = 1
  }

  # Note: with this launch_template block, the node group will create its own launch template based on the given 
  #       launch template to add security group and appropriate AMIs, and user data for joining node to cluster
  #       during bootstrapping. The ASG associated with the node group uses the generated launch template.
  launch_template {
    name    = "${var.resource_prefix}-${each.value.name}-lt"
    version = "$Latest"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_role_to_managed_policy,
    aws_eks_cluster.MainCluster
  ]
  tags = { Name = "${var.resource_prefix}-eks-ng-${each.value.name}-asg" }
}

