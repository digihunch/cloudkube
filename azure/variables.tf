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
variable "pubkey_data" {
  type    = string
  default = null
}
variable "AdminGroupGUID" {
  type    = string
}
