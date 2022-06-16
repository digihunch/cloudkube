variable "Tags" {
  description = "Tags for every resource."
  type        = map(any)
  default = {
    Environment = "Dev"
    Owner       = "my@email.com"
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
variable "oidc_provider_app_id" {
  type    = string
  default = "78098f11-e173-4427-8c3e-3506ad71aea9"
}
