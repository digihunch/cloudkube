output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}
output "kubernetes_cluster_id" {
  value = azurerm_kubernetes_cluster.default.id
}
output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.default.fqdn
}
output "kube_config" {
  value = azurerm_kubernetes_cluster.default.kube_config_raw
}
