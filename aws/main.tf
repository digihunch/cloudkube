resource "random_pet" "prefix" {}


module "network" {
  source                 = "./modules/network"
  vpc_cidr_block         = "147.207.0.0/16"
  mgmt_subnet_cidr_block = "147.207.0.0/24"
  node_subnets_cidr_list = ["147.207.1.0/24", "147.207.2.0/24", "147.207.3.0/24"]
  #  pod_subnet_cidr_block   = "147.207.4.0/24"
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
}

module "eks" {
  source          = "./modules/eks"
  node_subnet_ids = module.network.vpc_info.node_subnet_ids
  vpc_id          = module.network.vpc_info.vpc_id
  #  pod_subnet_id =  module.network.vpc_info.pod_subnet_id 
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
}

module "bastion" {
  source                     = "./modules/bastion"
  mgmt_subnet_id             = module.network.vpc_info.mgmt_subnet_id
  public_key_data            = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "")
  eks_name                   = module.eks.eks_name
  eks_arn                    = module.eks.eks_arn
  eks_cluster_kubectl_config = module.eks.eks_cluster_kubectl_config
  oidc_provider_app_id       = var.oidc_provider_app_id
  resource_tags              = var.Tags
  resource_prefix            = random_pet.prefix.id
}
