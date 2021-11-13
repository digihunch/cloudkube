resource "azurerm_user_assigned_identity" "default" {
  name                = "${var.resource_prefix}-aks-user-identity"
  location            = data.azurerm_resource_group.default.location
  resource_group_name = data.azurerm_resource_group.default.name
}

resource "azurerm_kubernetes_cluster" "default" {
  location                            = data.azurerm_resource_group.default.location
  resource_group_name                 = data.azurerm_resource_group.default.name
  name                                = "${var.resource_prefix}-aks"
  dns_prefix                          = "${var.resource_prefix}-k8s"
  kubernetes_version                  = var.aks_kubernetes_version
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true

  default_node_pool {
    name            = "default"
    type            = "VirtualMachineScaleSets"
    node_count      = 3
    min_count       = 3
    max_count       = 5
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
    pod_subnet_id   = var.aks_pod_subnet_id
    # https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#install-the-aks-preview-azure-cli
    vnet_subnet_id     = var.aks_node_subnet_id
    availability_zones = ["1", "2", "3"]
    # https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-node-distribution-across-zones
    enable_auto_scaling = true
  }

  identity {
    type = "SystemAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.default.id
  }

  role_based_access_control {
    enabled = true
    azure_active_directory {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aks_ad_admin_group_object_id
    }
  }

  network_profile {
    network_plugin = "azure" 
    network_policy = "calico"
    outbound_type = "userDefinedRouting"
  }
  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = var.aks_laws_id
    }
    # kube_dashboard is deprecated starting 1.19
    azure_policy {
      enabled = true
    }
  }

  auto_scaler_profile {
    scan_interval = "60s"
    scale_down_unneeded = "10m"
  }
  tags = var.resource_tags
}
