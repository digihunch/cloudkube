output "bastion_info" {
  value = "ec2-user@${module.bastion.bastion_info}"
}
output "eks_endpoint" {
  value = module.eks.eks_endpoint
}
output "eks_su_arn" {
  value = module.eks.eks_su_arn
}
output "cognito_user_pool" {
  value = module.idp.cognito_info.pool_id
}
