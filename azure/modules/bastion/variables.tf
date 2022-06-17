variable "resource_group" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "aks_cluster_fqdn" {
  type = string
  default = "unknown"
}
variable "kube_config" {
  type = string
  default = "unknown"
}
variable "bastion_subnet_id" {
  type = string
}
variable "public_key_data" {
  type = string
}
variable "os_user" {
  type    = string
  default = "kubeadmin"
}
variable "bastion_id_rsa" {
  description = "RSA key pair for Bastion"
  type = object({
    private_key_data = string,
    public_key_data = string,
  })
  default = {
    private_key_data = "empty-private-key",
    public_key_data = "empty-public-key",
  }
}
