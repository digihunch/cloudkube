resource "random_pet" "prefix" {}

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "byo_identity" {
  source            = "./modules/identity"
  resource_group    = data.azurerm_resource_group.stack_rg.name
  resource_location = coalesce(var.ResourceLocation, data.azurerm_resource_group.stack_rg.location)
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
}

module "network" {
  source                = "./modules/network"
  resource_group        = data.azurerm_resource_group.stack_rg.name
  resource_location     = coalesce(var.ResourceLocation, data.azurerm_resource_group.stack_rg.location)
  resource_prefix       = random_pet.prefix.id
  resource_tags         = var.Tags
  ssh_client_cidr_block = var.cli_cidr_block
}

module "log-analytics" {
  count             = var.KeepDiagLogging ? 1 : 0
  source            = "./modules/log-analytics"
  resource_group    = data.azurerm_resource_group.stack_rg.name
  resource_location = coalesce(var.ResourceLocation, data.azurerm_resource_group.stack_rg.location)
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
}

module "event-hub" {
  count             = var.KeepDiagLogging ? 1 : 0
  source            = "./modules/eventhub"
  resource_group    = data.azurerm_resource_group.stack_rg.name
  resource_location = coalesce(var.ResourceLocation, data.azurerm_resource_group.stack_rg.location)
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
}

# The time_sleep resource forces a 10s wait between byo_identity (including role assignment) and creation of AKS cluster. Because role assignment takes time to propagate and take effect in Azure.
resource "time_sleep" "wait" {
  depends_on = [module.byo_identity] 
  create_duration = "10s"
}

module "aks-cluster" {
  source            = "./modules/aks"
  resource_group    = data.azurerm_resource_group.stack_rg.name
  resource_location = coalesce(var.ResourceLocation, data.azurerm_resource_group.stack_rg.location)
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
  aks_byo_mi        = module.byo_identity.managed_id
  aks_spec = {
    cluster_name              = "aks_cluster_main"
    kubernetes_version        = "1.27.1"
    pod_subnet_id             = module.network.pod_subnet_id
    node_subnet_id            = module.network.node_subnet_id
    laws_id                   = var.KeepDiagLogging ? module.log-analytics[0].laws_id : null
    node_os_user              = "kubeadmin"
    node_public_key           = trimspace(tls_private_key.id_rsa.public_key_openssh)
    admin_group_ad_object_ids = [var.AdminGroupGUID]
    system_node_pool = {
      name                                = "systemnp"
      vm_size                             = "Standard_DS3_v2"
      zones                               = ["1", "2", "3"]
      node_count                          = 1
      cluster_auto_scaling                = false
      cluster_auto_scaling_min_node_count = 1
      cluster_auto_scaling_max_node_count = 1
      node_labels = {
        pool_name = "np-system"
      }
      node_taints = null
    }
    workload_node_pools = [{
      name                                = "applnp"
      vm_size                             = "Standard_DS3_v2"
      zones                               = ["1", "2", "3"]
      node_count                          = 3
      cluster_auto_scaling                = true
      cluster_auto_scaling_min_node_count = 3
      cluster_auto_scaling_max_node_count = 9
      node_labels = {
        pool_name          = "np-application"
        "px/metadata-node" = "true"
      }
      node_taints = null
#      }, {
#      name                                = "storagenp"
#      vm_size                             = "Standard_D2s_v3"
#      zones                               = ["1", "2", "3"]
#      node_count                          = 3
#      cluster_auto_scaling                = false
#      cluster_auto_scaling_min_node_count = 3
#      cluster_auto_scaling_max_node_count = 3
#      node_labels = {
#        pool_name = "np-storage"
#      }
#      node_taints = [
#        "storage-node=true:NoSchedule"
#      ]
    }]
    auto_scaler_profile = {
      balance_similar_node_groups      = false,
      expander                         = "random",
      max_graceful_termination_sec     = 600,
      max_node_provisioning_time       = "15m",
      max_unready_nodes                = 3,
      max_unready_percentage           = 45,
      new_pod_scale_up_delay           = "10s",
      scale_down_delay_after_add       = "10m",
      scale_down_delay_after_delete    = "10s",
      scale_down_delay_after_failure   = "3m",
      scan_interval                    = "10s",
      scale_down_unneeded              = "10m",
      scale_down_unready               = "20m",
      scale_down_utilization_threshold = 0.5,
      empty_bulk_delete_max            = 10,
      skip_nodes_with_local_storage    = true,
      skip_nodes_with_system_pods      = true,
    }
  }
  depends_on = [module.network, module.byo_identity, module.log-analytics, time_sleep.wait]
}

module "bastion" {
  source            = "./modules/bastion"
  resource_group    = data.azurerm_resource_group.stack_rg.name
  resource_location = coalesce(var.ResourceLocation, data.azurerm_resource_group.stack_rg.location)
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
  bastion_subnet_id = module.network.mgmt_subnet_id
  aks_cluster_fqdn  = module.aks-cluster.aks_fqdn
  kube_config       = module.aks-cluster.kube_config
  public_key_data   = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "")
  bastion_id_rsa = {
    private_key_data = trimspace(tls_private_key.id_rsa.private_key_openssh),
    public_key_data  = trimspace(tls_private_key.id_rsa.public_key_openssh),
  }
  depends_on = [tls_private_key.id_rsa, module.network, module.aks-cluster]
}

module "cluster-rbac" {
  source                       = "./modules/cluster-rbac"
  resource_group               = data.azurerm_resource_group.stack_rg.name
  rbac_principal_object_id     = var.AdminGroupGUID
  rbac_aks_cluster_id          = module.aks-cluster.kubernetes_cluster_id
  rbac_aks_principal_id        = module.byo_identity.managed_id.principal_id
  rbac_aks_node_resource_group = module.aks-cluster.aks_node_resource_group
  depends_on                   = [module.aks-cluster]
}

module "diag-setting" {
  count           = var.KeepDiagLogging ? 1 : 0
  source          = "./modules/diag-setting"
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
  ds_laws = {
    laws_id         = var.KeepDiagLogging ? module.log-analytics[0].laws_id : null
    tgt_resource_id = module.aks-cluster.kubernetes_cluster_id
    logs = [{
      category          = "kube-scheduler"
      enabled           = true
      retention_enabled = false
      retention_days    = 30
      }, {
      category          = "kube-apiserver"
      enabled           = true
      retention_enabled = false
      retention_days    = 30
    }],
    metric = {
      category          = "AllMetrics"
      enabled           = true
      retention_enabled = false
      retention_days    = 30
    }
  }

  ds_eventhub = {
    eventhub_name   = var.KeepDiagLogging ? module.event-hub[0].eventhub_name : null
    eh_auth_rule_id = var.KeepDiagLogging ? module.event-hub[0].eventhub_authn_rule_id : null
    tgt_resource_id = module.aks-cluster.kubernetes_cluster_id
    logs = [{
      category          = "kube-scheduler"
      enabled           = true
      retention_enabled = false
      retention_days    = 30
      }, {
      category          = "kube-apiserver"
      enabled           = true
      retention_enabled = false
      retention_days    = 30
    }]
  }
  depends_on = [module.event-hub, module.log-analytics, module.aks-cluster]
}
