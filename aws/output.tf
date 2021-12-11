output "bastion_info" {
  value = "ec2-user@${module.bastion.bastion_info}"
}
output "eks_endpoint" {
  value = module.eks.eks_endpoint
}
#output "eks_config_certificate" {
#  value = module.eks.eks_config_certificate
#}
