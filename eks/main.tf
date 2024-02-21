resource "random_pet" "prefix" {}

module "encryption" {
  source          = "./modules/encryption"
  resource_tags   = var.Tags
  resource_prefix = random_pet.prefix.id
  ssh_pubkey_data = var.pubkey_data != null ? var.pubkey_data : (fileexists(var.pubkey_path) ? file(var.pubkey_path) : "")
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
  vpc_cidr_block = var.vpc_cidr_block
  public_subnets_cidr_list = var.public_subnets_cidr_list
  internalsvc_subnets_cidr_list = var.internalsvc_subnets_cidr_list
  datasvc_subnets_cidr_list = var.datasvc_subnets_cidr_list
  node_subnets_cidr_list = var.node_subnets_cidr_list
  pod_subnets_cidr_list = var.pod_subnets_cidr_list
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
  ssh_pubkey_name = module.encryption.ssh_pubkey_name
  cognito_oidc_issuer_url = module.idp.cognito_info.issuer_url
  cognito_user_pool_id    = module.idp.cognito_info.pool_id
  cognito_oidc_client_id  = module.idp.cognito_info.client_id
  custom_key_arn          = module.encryption.custom_key_id
  amd64_nodegroup_count = var.amd64_nodegroup_count
  arm64_nodegroup_count = var.arm64_nodegroup_count
  amd64_nodegroup_inst_type = var.amd64_nodegroup_inst_type
  arm64_nodegroup_inst_type = var.arm64_nodegroup_inst_type
  amd64_nodegroup_ami_type = var.amd64_nodegroup_ami_type
  arm64_nodegroup_ami_type = var.arm64_nodegroup_ami_type
  kubernetes_version = var.kubernetes_version
  resource_tags           = var.Tags
  resource_prefix         = random_pet.prefix.id
  depends_on              = [time_sleep.iam_propagation, module.iam, module.network, module.encryption]
}

module "bastion" {
  source = "./modules/bastion"
  providers = {
    aws = aws.power-user
  }
  vpc_id = module.network.vpc_info.vpc_id
  bastion_subnet_ids = module.network.vpc_info.internalsvc_subnet_ids
  ssh_pubkey_name = module.encryption.ssh_pubkey_name 
  eks_name                    = module.eks.eks_name
  eks_arn                     = module.eks.eks_arn
  cognito_oidc_issuer_url     = module.idp.cognito_info.issuer_url
  cognito_user_pool_id        = module.idp.cognito_info.pool_id
  cognito_oidc_client_id      = module.idp.cognito_info.client_id
  bastion_role_name           = module.iam.iam_info.bastion_role_name
  eks_manager_role_name       = module.iam.iam_info.eks_manager_role_name
  cluster_admin_cognito_group = var.cluster_admin_cognito_group
  custom_key_arn              = module.encryption.custom_key_id
  resource_tags               = var.Tags
  resource_prefix             = random_pet.prefix.id
  depends_on                  = [module.eks, module.network, module.iam, module.encryption]
}
