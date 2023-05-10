data "aws_vpc" "eksVPC" {
  id = var.vpc_id
}

data "tls_certificate" "eks-cluster-tls-cert" {
  url = aws_eks_cluster.MainCluster.identity[0].oidc[0].issuer
}

data "aws_caller_identity" "current" {}
