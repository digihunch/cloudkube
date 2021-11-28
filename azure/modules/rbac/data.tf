data "azurerm_resource_group" "default" {
  name = var.resource_group
}
#data "azurerm_resource_group" "node_resource_group" {
#  name = var.rbac_aks_node_resource_group
#}
