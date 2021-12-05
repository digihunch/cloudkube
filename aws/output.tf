output "bastion_info" {
  value = "ec2-user@${module.bastion.bastion_info}"
}
output "cluster_info" {
  value = module.eks.endpoint
}
output "cluster_auth" {
  value = module.eks.kubeconfig-certificate-authority-data
}
