output "eventhub_name" {
  value = azurerm_eventhub.eventhub.name
}
output "eventhub_authn_rule_id" {
  value = azurerm_eventhub_namespace_authorization_rule.ehnsauthrule.id
}
