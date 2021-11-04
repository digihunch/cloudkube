<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 2.78.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks-cluster"></a> [aks-cluster](#module\_aks-cluster) | ./modules/aks | n/a |
| <a name="module_aks-rbac"></a> [aks-rbac](#module\_aks-rbac) | ./modules/rbac | n/a |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./modules/bastion | n/a |
| <a name="module_diag-setting"></a> [diag-setting](#module\_diag-setting) | ./modules/diag-setting | n/a |
| <a name="module_event-hub"></a> [event-hub](#module\_event-hub) | ./modules/eventhub | n/a |
| <a name="module_log-analytics"></a> [log-analytics](#module\_log-analytics) | ./modules/log-analytics | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |

## Resources

| Name | Type |
|------|------|
| [random_pet.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AdminGroupGUID"></a> [AdminGroupGUID](#input\_AdminGroupGUID) | n/a | `string` | `"xyz"` | no |
| <a name="input_ResourceGroup"></a> [ResourceGroup](#input\_ResourceGroup) | n/a | `string` | n/a | yes |
| <a name="input_Tags"></a> [Tags](#input\_Tags) | Tags for every resource. | `map(any)` | <pre>{<br>  "Environment": "Dev",<br>  "Owner": "my@email.com"<br>}</pre> | no |
| <a name="input_pubkey_data"></a> [pubkey\_data](#input\_pubkey\_data) | n/a | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_login"></a> [bastion\_login](#output\_bastion\_login) | n/a |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | n/a |
| <a name="output_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#output\_kubernetes\_cluster\_name) | n/a |
<!-- END_TF_DOCS -->