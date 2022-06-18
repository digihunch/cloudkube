output "managed_id" {
  value = {
    id           = azurerm_user_assigned_identity.aks_byo_id.id
    client_id    = azurerm_user_assigned_identity.aks_byo_id.client_id
    principal_id = azurerm_user_assigned_identity.aks_byo_id.principal_id
  }
}
