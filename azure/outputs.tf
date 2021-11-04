output "kubernetes_cluster_name" {
  value = module.aks-cluster.kubernetes_cluster_name
}
output "bastion_login" {
  value = "${module.bastion.username}@${module.bastion.host}"
}
output "kube_config" {
  value     = module.aks-cluster.kube_config
  sensitive = true
}
