output "endpoint" {
  value = aws_eks_cluster.MainCluster.endpoint 
}
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.MainCluster.certificate_authority[0].data
}
output "eks_tls_certificate" {
  value = aws_eks_cluster.MainCluster.identity[0].oidc[0].issuer
}
