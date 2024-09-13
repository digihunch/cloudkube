variable "vpc_config" {
  type = object({
    vpc_cidr                  = string
    az_count                  = number
    public_subnet_pfxlen      = number
    internalsvc_subnet_pfxlen = number
    node_subnet_pfxlen        = number
    pod_subnet_pfxlen         = number
  })
  default = {
    vpc_cidr                  = "147.206.0.0/16"
    az_count                  = 3
    public_subnet_pfxlen      = 24
    internalsvc_subnet_pfxlen = 22
    node_subnet_pfxlen        = 22
    pod_subnet_pfxlen         = 22
  }
  validation {
    condition     = can(cidrhost(var.vpc_config.vpc_cidr, 32))
    error_message = "Input variable vpc_config.vpc_cidr must be a valid IPv4 CIDR."
  }
  validation {
    condition     = var.vpc_config.az_count >= 1 && var.vpc_config.az_count <= 3
    error_message = "Input variable vpc_config.az_count must be a numeric value between 1, 2 or 3"
  }
}
#variable "vpc_cidr_block" {
#  type = string
#}
#variable "public_subnets_cidr_list" {
#  type = list(any)
#}
#variable "internalsvc_subnets_cidr_list" {
#  type = list(any)
#}
#variable "node_subnets_cidr_list" {
#  type = list(any)
#}
#variable "pod_subnets_cidr_list" {
#  type = list(any)
#}
variable "resource_prefix" {
  type = string
}
