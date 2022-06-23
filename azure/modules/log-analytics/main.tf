resource "azurerm_log_analytics_workspace" "laws" {
  name                = "${var.resource_prefix}-laws"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.resource_tags
}

resource "azurerm_log_analytics_solution" "lasol" {
  solution_name         = "ContainerInsights"
  location              = var.resource_location
  resource_group_name   = data.azurerm_resource_group.cluster_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.laws.id
  workspace_name        = azurerm_log_analytics_workspace.laws.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
