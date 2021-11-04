variable "Tags" {
  description = "Tags for every resource."
  type        = map(any)
  default = {
    Environment = "Dev"
    Owner       = "my@email.com"
  }
}
variable "ResourceGroup" {
  type    = string
  # export TF_VAR_ResourceGroup=xxx
}
variable "pubkey_file" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
variable "pubkey_data" {
  type    = string
  default = null
}
variable "AdminGroupGUID" {
  type    = string
  default = "xyz"
}
