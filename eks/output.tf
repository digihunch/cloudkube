output "bastion_info" {
  value       = module.bastion.bastion_info
  description = "Instance ID of the bastion host"
}
output "eks_name" {
  value       = module.eks.eks_name
  description = "EKS cluster name"
}
output "eks_su_arn" {
  value       = module.eks.eks_su_arn
  description = "The IAM arn that is implicitly configured as mapped to the cluster admin of the EKS cluster"
}
output "cognito_user_pool" {
  value       = module.idp.cognito_info.pool_id
  description = "Name of the cognito user pool"
}
