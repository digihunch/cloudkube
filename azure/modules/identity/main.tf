resource "random_uuid" "customrole" {}

resource "azurerm_user_assigned_identity" "aks_byo_id" {
  name                = "${var.resource_prefix}-aks-byo-identity"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  tags                = var.resource_tags
}

resource "azurerm_role_definition" "kubelet_id_assigner" {
  role_definition_id = random_uuid.customrole.result
  name               = "CustomKubeletIdentityPermission"
  scope              = data.azurerm_resource_group.cluster_rg.id

  permissions {
    actions     = ["Microsoft.ManagedIdentity/userAssignedIdentities/assign/action"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_resource_group.cluster_rg.id,
  ]
}

resource "azurerm_role_assignment" "kubeletidassigner_assignment" {
  scope              = data.azurerm_resource_group.cluster_rg.id
  role_definition_id = azurerm_role_definition.kubelet_id_assigner.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.aks_byo_id.principal_id
}

resource "azurerm_role_assignment" "networkcontributor_assignment" {
  role_definition_name             = "Network Contributor"
  scope                            = data.azurerm_resource_group.cluster_rg.id
  principal_id                     = azurerm_user_assigned_identity.aks_byo_id.principal_id
  skip_service_principal_aad_check = true
}
