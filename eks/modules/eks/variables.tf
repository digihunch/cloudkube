variable "node_subnet_ids" {
  type = list(any)
}
variable "vpc_id" {
  type = string
}
variable "ssh_pubkey_name" {
  type = string
}
variable "cognito_oidc_issuer_url" {
  type = string
}
variable "cognito_user_pool_id" {
  type = string
}
variable "cognito_oidc_client_id" {
  type = string
}
variable "custom_key_arn" {
  type = string
}
variable "arm64_nodegroup_count" {
  type = number
}
variable "amd64_nodegroup_count" {
  type = number
}
variable "amd64_nodegroup_inst_type" {
  type = string
}
variable "arm64_nodegroup_inst_type" {
  type = string
}
variable "amd64_nodegroup_ami_type" {
  type = string
}
variable "arm64_nodegroup_ami_type" {
  type = string
}
variable "kubernetes_version" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
