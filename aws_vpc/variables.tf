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
variable "pubkey_data" {
  type    = string
  default = null
}
variable "instance_type" {
  type    = string
  default = "t2.micro" #g4dn.xlarge for GPU 
}
variable "preferred_ami_id" {
  type    = string
  default = "" #ami-04b70fa74e45c3917 for ubuntu 2024 us-east-1
}
variable "pubkey_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
variable "resource_prefix" {
  type    = string
  default = "rosa"
}
variable "resource_tags" {
  type = map(any)
  default = {
    Environment = "Dev"
    Owner       = "test@example.com"
  }
}
