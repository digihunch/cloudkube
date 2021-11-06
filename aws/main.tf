resource "random_pet" "prefix" {}

module "iam_role" {
  source = "./modules/iamrole"
  resource_tags   = var.Tags
}

module "network" {
  source = "./modules/network"
  vpc_cidr_block = "172.17.0.0/16"
  mgmt_subnet_cidr_block = "172.17.1.0/24"
  node_subnet_cidr_block = "172.17.2.0/24"
  pod_subnet_cidr_block = "172.17.3.0/24"
  resource_tags   = var.Tags
}


module "bastion" {
  source = "./modules/bastion"
  mgmt_subnet_id = module.network.vpc_info.mgmt_subnet_id 
  public_key_data = var.pubkey_data 
  role_name = module.iam_role.role_info.ec2_iam_role_name
  resource_tags   = var.Tags
  depends_on = [module.iam_role]
}
