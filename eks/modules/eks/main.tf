locals {
  eks_cluster_version = "1.26"
  inst_type_amd64_ng = "t3.medium"
  inst_type_arm64_ng = "m7g.large"
  ami_type_amd64     = "AL2_x86_64"
  ami_type_arm64     = "AL2_ARM_64"
}


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
  tags               = merge(var.resource_tags, { Name = "${var.resource_prefix}-EKS-Cluster-Role" })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_iam_role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_iam_role.name
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
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-Cluster-SG" })
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
  version                   = local.eks_cluster_version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  encryption_config {
    provider {
      key_arn = var.custom_key_arn
    }
    resources = ["secrets"]
  }
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-Cluster" })
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
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
  cluster_name      = aws_eks_cluster.MainCluster.name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
  tags              = merge(var.resource_tags, { "eks_addon" = "vpc-cni" })
  depends_on        = [aws_eks_cluster.MainCluster]
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
  tags               = merge(var.resource_tags, { Name = "${var.resource_prefix}-EKS-Node-Role" })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicyNodeRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCNIPolicyNodeRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSSSMPolicyNodeRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnlyNodeRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMPolicyNodeRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_launch_template" "amd64_lt" {
  count = var.amd64_nodegroup_count
  name = "${var.resource_prefix}-eks-amd64-lt${count.index}"
  key_name = var.ssh_pubkey_name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.resource_prefix}-AMD64NG${count.index}-EKSNode"
    }
  }
}

resource "aws_eks_node_group" "amd64_ng" {
  count = var.amd64_nodegroup_count 
  cluster_name    = aws_eks_cluster.MainCluster.name
  node_group_name = "${var.resource_prefix}-eks-amd64-ng${count.index}"
  node_role_arn   = aws_iam_role.eks_node_iam_role.arn
  instance_types  = [local.inst_type_amd64_ng]
  ami_type        = local.ami_type_amd64
  subnet_ids      = (var.amd64_nodegroup_count > 0) ? [var.node_subnet_ids[count.index % length(var.node_subnet_ids)]] : null
  labels = {
    cloudkube-node-type = "amd64-nodegroup-${count.index}"
  }
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  update_config {
    max_unavailable = 1
  }
  launch_template {
    id = aws_launch_template.amd64_lt[count.index].id
    version = aws_launch_template.amd64_lt[count.index].latest_version 
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEKSCNIPolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnlyNodeRole,
    aws_eks_cluster.MainCluster
  ]
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-AMD64-EKSNG${count.index}-ASG" })
}

resource "aws_launch_template" "arm64_lt" {
  count = var.arm64_nodegroup_count
  name = "${var.resource_prefix}-eks-arm64-lt${count.index}"
  key_name = var.ssh_pubkey_name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.resource_prefix}-ARM64NG${count.index}-EKSNode"
    }
  }
}

resource "aws_eks_node_group" "arm64_ng" {
  count = var.arm64_nodegroup_count 
  cluster_name    = aws_eks_cluster.MainCluster.name
  node_group_name = "${var.resource_prefix}-eks-arm64-ng${count.index}"
  node_role_arn   = aws_iam_role.eks_node_iam_role.arn
  instance_types  = [local.inst_type_arm64_ng]
  ami_type        = local.ami_type_arm64
  subnet_ids      = (var.arm64_nodegroup_count > 0) ? [var.node_subnet_ids[count.index % length(var.node_subnet_ids)]] : null
  labels = {
    cloudkube-node-type = "arm64-nodegroup-${count.index}"
  }
  taint {
    key = "arch"
    value = "arm64"
    effect = "NO_SCHEDULE"
  }
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  update_config {
    max_unavailable = 1
  }
  launch_template {
    id = aws_launch_template.arm64_lt[count.index].id
    version = aws_launch_template.arm64_lt[count.index].latest_version 
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEKSCNIPolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnlyNodeRole,
    aws_iam_role_policy_attachment.AmazonSSMPolicyNodeRole,
    aws_eks_cluster.MainCluster
  ]
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-ARM64-EKSNG${count.index}-ASG" })
}
