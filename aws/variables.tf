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
variable "cli_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}
variable "pubkey_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
variable "cluster_admin_cognito_group" {
  type    = string
  default = "cluster-admin-group"
}
variable "init_eks_admin_email" {
  type = string
  default = "test@example.com"
}
