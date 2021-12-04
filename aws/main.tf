resource "random_pet" "prefix" {}


module "network" {
  source                  = "./modules/network"
  vpc_cidr_block          = "147.207.0.0/16"
  mgmt_subnet_cidr_block  = "147.207.0.0/24"
  node_subnet1_cidr_block = "147.207.1.0/24"
  node_subnet2_cidr_block = "147.207.2.0/24"
  pod_subnet_cidr_block   = "147.207.3.0/24"
  resource_tags           = var.Tags
  resource_prefix         = random_pet.prefix.id
}

module "bastion" {
  source          = "./modules/bastion"
  mgmt_subnet_id  = module.network.vpc_info.mgmt_subnet_id
  public_key_data = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "")
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
}
