output "eks_name" {
  value = aws_eks_cluster.MainCluster.id
}
output "eks_arn" {
  value = aws_eks_cluster.MainCluster.arn
}
output "eks_endpoint" {
  value = aws_eks_cluster.MainCluster.endpoint
}
output "eks_su_arn" {
  value = data.aws_caller_identity.current.arn
}
