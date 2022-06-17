resource "random_pet" "prefix" {}

resource "tls_private_key" "id_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "network" {
  source          = "./modules/network"
  resource_group  = var.ResourceGroup
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
  ssh_client_cidr_block = var.cli_cidr_block
}

module "log-analytics" {
  source          = "./modules/log-analytics"
  resource_group  = var.ResourceGroup
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
}

module "event-hub" {
  source          = "./modules/eventhub"
  resource_group  = var.ResourceGroup
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
}

module "aks-cluster" {
  source          = "./modules/aks"
  resource_group  = var.ResourceGroup
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
  aks_spec = {
    cluster_name              = "aks_cluster_main"
    kubernetes_version        = "1.23.3"
    pod_subnet_id             = module.network.pod_subnet_id
    node_subnet_id            = module.network.node_subnet_id
    laws_id                   = module.log-analytics.laws_id
    node_os_user = "kubeadmin"
    node_public_key = trimspace(tls_private_key.id_rsa.public_key_openssh)
    admin_group_ad_object_ids = [var.AdminGroupGUID]
    system_node_pool = {
      name                                = "sysnp0"
      vm_size                             = "Standard_D2s_v4"
      zones                               = ["1", "2", "3"]
      node_count                          = 1
      cluster_auto_scaling                = false
      cluster_auto_scaling_min_node_count = 3
      cluster_auto_scaling_max_node_count = 3
      node_labels = {
        pool_name          = "system-np"
      }
    }
    workload_node_pools = [{
      name                                = "wlnp1"
      vm_size                             = "Standard_D2s_v4"
      zones                               = ["1", "2", "3"]
      node_count                          = 3
      cluster_auto_scaling                = true
      cluster_auto_scaling_min_node_count = 3
      cluster_auto_scaling_max_node_count = 9
      node_labels = {
        pool_name = "workload-np01"
        "px/metadata-node" = "true"
      }
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
  depends_on = [module.network, module.log-analytics]
}

module "bastion" {
  source            = "./modules/bastion"
  resource_group    = var.ResourceGroup
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
  bastion_subnet_id = module.network.mgmt_subnet_id
  aks_cluster_fqdn  = module.aks-cluster.aks_fqdn
  kube_config       = module.aks-cluster.kube_config
  public_key_data   = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "") 
  bastion_id_rsa = {
    private_key_data = trimspace(tls_private_key.id_rsa.private_key_openssh),
    public_key_data = trimspace(tls_private_key.id_rsa.public_key_openssh),
  }
  depends_on        = [tls_private_key.id_rsa, module.network, module.aks-cluster]
}

module "aks-rbac" {
  source                       = "./modules/rbac"
  resource_group               = var.ResourceGroup
  rbac_principal_object_id     = var.AdminGroupGUID
  rbac_aks_cluster_id          = module.aks-cluster.kubernetes_cluster_id
  rbac_aks_principal_id        = module.aks-cluster.aks_identity_principal_id
  rbac_aks_node_resource_group = module.aks-cluster.aks_node_resource_group
  depends_on                   = [module.aks-cluster]
}

module "diag-setting" {
  source          = "./modules/diag-setting"
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
  ds_laws = {
    laws_id         = module.log-analytics.laws_id
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
    eventhub_name   = module.event-hub.eventhub_name
    eh_auth_rule_id = module.event-hub.eventhub_authn_rule_id
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
