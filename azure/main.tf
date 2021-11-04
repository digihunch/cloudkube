resource "random_pet" "prefix" {}

module "network" {
  source          = "./modules/network"
  resource_group  = var.ResourceGroup
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
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
  source                       = "./modules/aks"
  resource_group               = var.ResourceGroup
  resource_prefix              = random_pet.prefix.id
  resource_tags                = var.Tags
  aks_kubernetes_version       = "1.21.2"
  aks_network_plugin           = "azure"
  aks_ad_admin_group_object_id = [var.AdminGroupGUID]
  aks_pod_subnet_id            = module.network.pod_subnet_id
  aks_node_subnet_id           = module.network.node_subnet_id
  aks_laws_id                  = module.log-analytics.laws_id
  depends_on                   = [module.network, module.log-analytics]
}

module "bastion" {
  source            = "./modules/bastion"
  resource_group    = var.ResourceGroup
  resource_prefix   = random_pet.prefix.id
  resource_tags     = var.Tags
  bastion_subnet_id = module.network.mgmt_subnet_id
  aks_cluster_fqdn  = module.aks-cluster.aks_fqdn
  kube_config       = module.aks-cluster.kube_config
  public_key_data   = var.pubkey_data
  depends_on        = [module.network, module.aks-cluster]
}

module "aks-rbac" {
  source                   = "./modules/rbac"
  rbac_principal_object_id = var.AdminGroupGUID
  rbac_aks_id              = module.aks-cluster.kubernetes_cluster_id
  depends_on               = [module.aks-cluster]
}

module "diag-setting" {
  source          = "./modules/diag-setting"
  resource_prefix = random_pet.prefix.id
  resource_tags   = var.Tags
  ds_eh_aks_id    = module.aks-cluster.kubernetes_cluster_id
  ds_laws_id      = module.log-analytics.laws_id
  ds_eh_name      = module.event-hub.eventhub_name
  ds_ehar_id      = module.event-hub.eventhub_authn_rule_id
  depends_on      = [module.event-hub, module.log-analytics, module.aks-cluster]
}
