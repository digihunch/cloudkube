variable "CommonTags" {
  description = "Tags for every resource."
  type        = map(any)
  default = {
    Environment = "Dev"
    Owner       = "test@example.com"
  }
}
variable "pubkey_data" {
  type    = string
  default = null
}
variable "pubkey_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
variable "vpc_cidr_block" {
  type    = string
  default = "147.206.0.0/16"
}
variable "public_subnets_cidr_list" {
  type    = list(any)
  default = ["147.206.0.0/22", "147.206.4.0/22", "147.206.8.0/22"]
}
variable "internalsvc_subnets_cidr_list" {
  type    = list(any)
  default = ["147.206.16.0/22", "147.206.20.0/22", "147.206.24.0/22"]
}
variable "datasvc_subnets_cidr_list" {
  type    = list(any)
  default = ["147.206.32.0/22", "147.206.36.0/22", "147.206.40.0/22"]
}
variable "node_subnets_cidr_list" {
  type    = list(any)
  default = ["147.206.48.0/22", "147.206.52.0/22", "147.206.56.0/22"]
}
variable "pod_subnets_cidr_list" {
  type    = list(any)
  default = ["147.206.64.0/18", "147.206.128.0/18", "147.206.192.0/18"]
}
variable "cluster_admin_cognito_group" {
  type    = string
  default = "cluster-admin-group"
}
variable "init_eks_admin_email" {
  type    = string
  default = "test@example.com"
}
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}
# Valid Values for AMI type: https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html
variable "node_group_configs" {
  type = list(map(any))
  default = [
    {
      name              = "ng1"
      cpu_arch          = "amd64"
      instance_type     = "t3.medium"
      ami_type          = "BOTTLEROCKET_x86_64"
      node_size_desired = 3
      node_size_min     = 3
      node_size_max     = 3
    },
    {
      name              = "ng2"
      cpu_arch          = "amd64"
      instance_type     = "t3.medium"
      ami_type          = "AL2023_x86_64_STANDARD"
      node_size_desired = 3
      node_size_min     = 3
      node_size_max     = 3
    },
    {
      name              = "ng3"
      cpu_arch          = "arm64"
      instance_type     = "m7g.large"
      ami_type          = "BOTTLEROCKET_ARM_64"
      node_size_desired = 3
      node_size_min     = 3
      node_size_max     = 3
    }
  ]
}
