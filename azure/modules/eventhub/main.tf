resource "azurerm_eventhub_namespace" "ehns" {
  name                = "${var.resource_prefix}-ehns"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  sku                 = "Standard"
  capacity            = 1
  tags                = var.resource_tags
}


# Create Event hub

resource "azurerm_eventhub" "eventhub" {
  name                = "${var.resource_prefix}-eventhub"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  partition_count     = 2
  message_retention   = 1
}

# Create an authorization rule

resource "azurerm_eventhub_namespace_authorization_rule" "ehnsauthrule" {
  name                = "${var.resource_prefix}-ehnsauthrule"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = data.azurerm_resource_group.cluster_rg.name

  listen = true
  send   = true
  manage = true
}
