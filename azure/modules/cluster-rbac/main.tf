# After AKS cluster creation, if there are AD users, AD groups, other service principal or managed identities that needs to be assigned as cluster admin, RBAC admin, RBAC reader or RBAC writer, they should be assigned here.
# Kubernetes RBAC managed can be done in a separate automation process.

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
