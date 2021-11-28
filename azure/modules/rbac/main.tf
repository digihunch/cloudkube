resource "azurerm_role_assignment" "cluster_admin_assignment" {
  scope                = var.rbac_aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.rbac_principal_object_id
}
resource "azurerm_role_assignment" "admin_assignment" {
  scope                = var.rbac_aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = var.rbac_principal_object_id
}
resource "azurerm_role_assignment" "reader_assignment" {
  scope                = var.rbac_aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  principal_id         = var.rbac_principal_object_id
}
resource "azurerm_role_assignment" "writer_assignment" {
  scope                = var.rbac_aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = var.rbac_principal_object_id
}
resource "azurerm_role_assignment" "networkcontributor_assignment" {
  role_definition_name             = "Network Contributor"
  scope                            = data.azurerm_resource_group.default.id
  principal_id                     = var.rbac_aks_principal_id
  skip_service_principal_aad_check = true
}
resource "azurerm_role_assignment" "nodergcontributor_assignment" {
  role_definition_name             = "Contributor"
  scope                            = data.azurerm_resource_group.node_resource_group.id
  principal_id                     = var.rbac_aks_principal_id
  skip_service_principal_aad_check = true
}
