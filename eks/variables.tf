variable "Tags" {
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
variable "amd64_nodegroup_count" {
  type    = number
  default = 2
}
variable "arm64_nodegroup_count" {
  type    = number
  default = 1
}
