output "kubernetes_cluster_name" {
  value = module.aks-cluster.kubernetes_cluster_name
}
output "bastion_login" {
  value = "${module.bastion.username}@${module.bastion.host}"
}
output "byo_mi_clientid" {
  value = module.byo_identity.managed_id.client_id
}
