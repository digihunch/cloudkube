# RBAC role assignment that has to be done after AKS cluster creation are done here.
resource "azurerm_role_assignment" "cluster_admin_assignment" {
  scope                = var.rbac_aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.rbac_principal_object_id
}
#resource "azurerm_role_assignment" "admin_assignment" {
#  scope                = var.rbac_aks_cluster_id
#  role_definition_name = "Azure Kubernetes Service RBAC Admin"
#  principal_id         = var.rbac_principal_object_id
#}
#resource "azurerm_role_assignment" "reader_assignment" {
#  scope                = var.rbac_aks_cluster_id
#  role_definition_name = "Azure Kubernetes Service RBAC Reader"
#  principal_id         = var.rbac_principal_object_id
#}
#resource "azurerm_role_assignment" "writer_assignment" {
#  scope                = var.rbac_aks_cluster_id
#  role_definition_name = "Azure Kubernetes Service RBAC Writer"
#  principal_id         = var.rbac_principal_object_id
#}
