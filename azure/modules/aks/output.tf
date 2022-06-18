output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}
output "kubernetes_cluster_id" {
  value = azurerm_kubernetes_cluster.default.id
}
#output "aks_identity_principal_id" {
#  value = azurerm_user_assigned_identity.aks_byo_id.principal_id 
#}
output "aks_node_resource_group" {
  value = azurerm_kubernetes_cluster.default.node_resource_group
}
output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.default.fqdn
}
output "kube_config" {
  value = azurerm_kubernetes_cluster.default.kube_config_raw
}
