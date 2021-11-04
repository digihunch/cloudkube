<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 2.78.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks-cluster"></a> [aks-cluster](#module\_aks-cluster) | ./modules/aks | n/a |
| <a name="module_aks-rbac"></a> [aks-rbac](#module\_aks-rbac) | ./modules/rbac | n/a |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./modules/bastion | n/a |
| <a name="module_log-analytics"></a> [log-analytics](#module\_log-analytics) | ./modules/log-analytics | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |

## Resources

| Name | Type |
|------|------|
| [random_pet.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [local_file.pubkey_path](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AdminGroupGUID"></a> [AdminGroupGUID](#input\_AdminGroupGUID) | n/a | `string` | `"112233445-cce6-4aed-830d-66677799933"` | no |
| <a name="input_ResourceGroup"></a> [ResourceGroup](#input\_ResourceGroup) | n/a | `string` | n/a | yes |
| <a name="input_Tags"></a> [Tags](#input\_Tags) | Tags for every resource. | `map(any)` | <pre>{<br>  "Environment": "Dev",<br>  "Owner": "my@email.com"<br>}</pre> | no |
| <a name="input_pubkey_data"></a> [pubkey\_data](#input\_pubkey\_data) | n/a | `string` | `null` | no |
| <a name="input_pubkey_file"></a> [pubkey\_file](#input\_pubkey\_file) | n/a | `string` | `"~/.ssh/id_rsa.pub"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_login"></a> [bastion\_login](#output\_bastion\_login) | n/a |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | n/a |
| <a name="output_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#output\_kubernetes\_cluster\_name) | n/a |

## Usage 
To execute in command line
```sh
export TF_VAR_ResourceGroup=app-sg && terraform init -backend-config=environments/dev.tfvars && terraform plan
```
To re-generate document
```sh
terraform-docs markdown table --output-file README.md --output-mode inject ./
```
<!-- END_TF_DOCS -->
