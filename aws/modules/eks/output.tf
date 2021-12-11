output "eks_name" {
  value = aws_eks_cluster.MainCluster.id
}
output "eks_arn" {
  value = aws_eks_cluster.MainCluster.arn
}
output "eks_endpoint" {
  value = aws_eks_cluster.MainCluster.endpoint 
}
output "eks_config_certificate" {
  value = aws_eks_cluster.MainCluster.certificate_authority[0].data
}
output "eks_tls_certificate" {
  value = aws_eks_cluster.MainCluster.identity[0].oidc[0].issuer
}
output "eks_cluster_role_name" {
  value = aws_iam_role.eks_cluster_iam_role.name 
}
