output "bastion_info" {
  value = aws_instance.bastion.public_dns
}
