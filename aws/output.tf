output "bastion_info" {
  value = "ec2-user@${module.bastion.bastion_info}"
}
