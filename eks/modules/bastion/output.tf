output "bastion_info" {
  value = join(",", data.aws_instances.bastion_instances.ids)
}
