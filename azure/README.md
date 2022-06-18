<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 2.78.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.3 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 3.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks-cluster"></a> [aks-cluster](#module\_aks-cluster) | ./modules/aks | n/a |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./modules/bastion | n/a |
| <a name="module_byo_identity"></a> [byo\_identity](#module\_byo\_identity) | ./modules/identity | n/a |
| <a name="module_cluster-rbac"></a> [cluster-rbac](#module\_cluster-rbac) | ./modules/cluster-rbac | n/a |
| <a name="module_diag-setting"></a> [diag-setting](#module\_diag-setting) | ./modules/diag-setting | n/a |
| <a name="module_event-hub"></a> [event-hub](#module\_event-hub) | ./modules/eventhub | n/a |
| <a name="module_log-analytics"></a> [log-analytics](#module\_log-analytics) | ./modules/log-analytics | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |

## Resources

| Name | Type |
|------|------|
| [random_pet.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [tls_private_key.id_rsa](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AdminGroupGUID"></a> [AdminGroupGUID](#input\_AdminGroupGUID) | Object ID of the AD group or user to be assigned as cluster administrator | `string` | n/a | yes |
| <a name="input_KeepDiagLogging"></a> [KeepDiagLogging](#input\_KeepDiagLogging) | Whether or not to persist diagnostic log of AKS cluster to log analytics workspace and to event hub. If true, log analytics workspace and event hub will be created and aks will be configured to integration with them. | `bool` | `false` | no |
| <a name="input_ResourceGroup"></a> [ResourceGroup](#input\_ResourceGroup) | Name of the resource group where AKS cluster is to be created. The terraform identity must be an owner of this resource group. | `string` | n/a | yes |
| <a name="input_Tags"></a> [Tags](#input\_Tags) | Tags for every resource. | `map(any)` | <pre>{<br>  "Environment": "Dev",<br>  "Owner": "my@email.com"<br>}</pre> | no |
| <a name="input_cli_cidr_block"></a> [cli\_cidr\_block](#input\_cli\_cidr\_block) | Only SSH client IP from this CIDR block can connect to the bastion host. | `string` | `"0.0.0.0/0"` | no |
| <a name="input_pubkey_data"></a> [pubkey\_data](#input\_pubkey\_data) | Public key pre-loaded to bastion host as authorized public key | `string` | `null` | no |
| <a name="input_pubkey_path"></a> [pubkey\_path](#input\_pubkey\_path) | File that stores the public key to be pre-loaded to bastion host as authorized public key | `string` | `"~/.ssh/id_rsa.pub"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_login"></a> [bastion\_login](#output\_bastion\_login) | username and public IP of the bastion host |
| <a name="output_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#output\_kubernetes\_cluster\_name) | name of the AKS cluster resource |
<!-- END_TF_DOCS -->