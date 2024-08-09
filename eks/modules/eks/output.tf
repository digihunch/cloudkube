output "eks_name" {
  value = aws_eks_cluster.MainCluster.id
}
output "eks_arn" {
  value = aws_eks_cluster.MainCluster.arn
}
output "eks_endpoint" {
  value = aws_eks_cluster.MainCluster.endpoint
}
