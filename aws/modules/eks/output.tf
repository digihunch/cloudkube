output "eks_name" {
  value = aws_eks_cluster.MainCluster.id
}
output "eks_arn" {
  value = aws_eks_cluster.MainCluster.arn
}
output "eks_endpoint" {
  value = aws_eks_cluster.MainCluster.endpoint
}
data "aws_eks_cluster_auth" "MainClusterAuth" {
  name = aws_eks_cluster.MainCluster.name
}
output "eks_cluster_kubectl_config" {
  value = {
    host                   = aws_eks_cluster.MainCluster.endpoint
    token                  = data.aws_eks_cluster_auth.MainClusterAuth.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.MainCluster.certificate_authority[0].data)
  }
}
output "eks_su_arn" {
  value = data.aws_caller_identity.current.arn
}
