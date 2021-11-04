data "local_file" "pubkey_path" {
  filename = pathexpand(var.pubkey_file)
}
