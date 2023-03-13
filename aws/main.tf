resource "random_pet" "prefix" {}

module "kms" {
  source          = "./modules/kms"
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
}

module "idp" {
  source = "./modules/idp"
  providers = {
    aws = aws.power-user
  }
  init_admin_email            = var.init_eks_admin_email
  cluster_admin_cognito_group = var.cluster_admin_cognito_group
  resource_tags               = var.Tags
  resource_prefix             = random_pet.prefix.id
}

module "iam" {
  source = "./modules/iam"
  providers = {
    aws = aws.power-user
  }
  cognito_up_arn  = module.idp.cognito_info.pool_arn
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
  depends_on      = [module.idp]
}

resource "time_sleep" "iam_propagation" {
  create_duration = "15s"
  triggers = {
    eks_manager_role_arn = module.iam.iam_info.eks_manager_role_arn
  }
}

module "network" {
  providers = {
    aws = aws.power-user
  }
  source                 = "./modules/network"
  vpc_cidr_block         = "147.207.0.0/16"
  mgmt_subnet_cidr_block = "147.207.0.0/24"
  node_subnets_cidr_list = ["147.207.1.0/24", "147.207.2.0/24", "147.207.3.0/24"]
  #  pod_subnet_cidr_block   = "147.207.4.0/24"
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
}

module "eks" {
  source = "./modules/eks"
  providers = {
    aws = aws.eks-manager
  }
  node_subnet_ids = module.network.vpc_info.node_subnet_ids
  vpc_id          = module.network.vpc_info.vpc_id
  #  pod_subnet_id =  module.network.vpc_info.pod_subnet_id 
  cognito_oidc_issuer_url = module.idp.cognito_info.issuer_url
  cognito_user_pool_id    = module.idp.cognito_info.pool_id
  cognito_oidc_client_id  = module.idp.cognito_info.client_id
  custom_key_arn          = module.kms.custom_key_id
  amd64_nodegroup_count = var.amd64_nodegroup_count
  arm64_nodegroup_count = var.arm64_nodegroup_count
  resource_tags           = var.Tags
  resource_prefix         = random_pet.prefix.id
  depends_on              = [time_sleep.iam_propagation, module.iam, module.network, module.kms]
}

module "bastion" {
  source = "./modules/bastion"
  providers = {
    aws = aws.power-user
  }
  mgmt_subnet_id              = module.network.vpc_info.mgmt_subnet_id
  public_key_data             = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "")
  eks_name                    = module.eks.eks_name
  eks_arn                     = module.eks.eks_arn
  cognito_oidc_issuer_url     = module.idp.cognito_info.issuer_url
  cognito_user_pool_id        = module.idp.cognito_info.pool_id
  cognito_oidc_client_id      = module.idp.cognito_info.client_id
  bastion_role_name           = module.iam.iam_info.bastion_role_name
  eks_manager_role_name       = module.iam.iam_info.eks_manager_role_name
  ssh_client_cidr_block       = var.cli_cidr_block
  cluster_admin_cognito_group = var.cluster_admin_cognito_group
  custom_key_arn              = module.kms.custom_key_id
  resource_tags               = var.Tags
  resource_prefix             = random_pet.prefix.id
  depends_on                  = [module.eks, module.network, module.iam, module.kms]
}
