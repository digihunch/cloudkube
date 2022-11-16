output "bastion_info" {
  value = "ec2-user@${module.bastion.bastion_info}"
}
output "eks_name" {
  value = module.eks.eks_name
}
output "eks_su_arn" {
  value = module.eks.eks_su_arn
}  # the IAM arn that is invisibly configured by default as mapped to the cluster admin of the EKS cluster.
output "cognito_user_pool" {
  value = module.idp.cognito_info.pool_id
}
