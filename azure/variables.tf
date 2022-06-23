variable "Tags" {
  description = "Tags for every resource."
  type        = map(any)
  default = {
    Environment = "Dev"
    Owner       = "my@email.com"
  }
}
variable "ResourceGroup" {
  type = string
}
variable "ResourceLocation" {
  type    = string
  default = "Canada Central"
}
variable "pubkey_data" {
  type    = string
  default = null
}
variable "pubkey_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
variable "cli_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}
variable "AdminGroupGUID" {
  type = string
}
variable "KeepDiagLogging" {
  type    = bool
  default = false
}
