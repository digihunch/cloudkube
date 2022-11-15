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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.eksVPC.cidr_block]
  }
  egress {
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
  #  kubernetes_network_config {
  #    service_ipv4_cidr = "147.206.8.0/24"
  #  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_identity_provider_config" "ClusterOIDCConfig" {
  cluster_name = aws_eks_cluster.MainCluster.name

  oidc {
    identity_provider_config_name = "${var.resource_prefix}-eks-cluster-oidc-config"
    issuer_url = var.cognito_oidc_issuer_url
    client_id = var.cognito_oidc_client_id
    username_claim = "email"
    groups_claim = "cognito:groups"
    groups_prefix = "gid:"
  }
}

data "tls_certificate" "eks-cluster-tls-cert" {
  url = aws_eks_cluster.MainCluster.identity[0].oidc[0].issuer
}
resource "aws_eks_addon" "eks_main_addon" {
  cluster_name      = aws_eks_cluster.MainCluster.name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
  tags              = merge(var.resource_tags, { "eks_addon" = "vpc-cni" })
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

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnlyNodeRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_iam_role.name
}

resource "aws_eks_node_group" "sys_ng" {
  cluster_name    = aws_eks_cluster.MainCluster.name
  node_group_name = "${var.resource_prefix}-eks-sys-ng0"
  node_role_arn   = aws_iam_role.eks_node_iam_role.arn
  subnet_ids      = var.node_subnet_ids
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEKSCNIPolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnlyNodeRole,
  ]
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-EKS-System-Node-Group-0" })
}

resource "aws_eks_node_group" "biz_ng" {
  cluster_name    = aws_eks_cluster.MainCluster.name
  node_group_name = "${var.resource_prefix}-eks-biz-ng1"
  node_role_arn   = aws_iam_role.eks_node_iam_role.arn
  subnet_ids      = var.node_subnet_ids
  scaling_config {
    desired_size = 3
    max_size     = 9
    min_size     = 3
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEKSCNIPolicyNodeRole,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnlyNodeRole,
  ]
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-EKS-Business-Node-Group-1" })
}
