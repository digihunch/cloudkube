output "custom_key_id" {
  value = aws_kms_key.customKey.arn
}
output "ssh_pubkey_name" {
  value = aws_key_pair.ssh-pubkey.key_name 
}
