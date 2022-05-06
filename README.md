# cloud kube

Cloud Kube project includes Terraform templates to create secure, scalable Kubernetes platforms with relevant logging and monitoring construct in Azure and AWS. It aims to serve as a opinionated baseline architecture for production use. 

This project does NOT aim to be portable to any client environment because different Kubernetes deployments have significant architectural variations.

## Azure Kubernetes Service
The template needs to run by a service principal with sufficient privilege, such as an owner of a target resource group.

The following environment variables are expected for Terraform:
- ARM_SUBSCRIPTION_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_ENVIRONMENT
- ARM_TENANT_ID

The terraform code template is stored in the [azure](https://github.com/digihunch/cloudkube/tree/main/azure) directory. The template was tested with Terraform executable. 

Before deployment, run:
```sh
export TF_VAR_ResourceGroup=AutomationTest
export TF_VAR_AdminGroupGUID=74d661ce-cce6-4aed-830d-5abc732a1132
export TF_VAR_pubkey_data="ssh-rsa xxxbbrsapublickeyforsshaccess last.first@CLOUDKUBE"
```
Then we can login to azure and run terraform from the directory:
```sh
# Log in to Azure, If your environment does not have browsers prompted, use --use-device-code switch
az login

# if not on correct subscription by default, set subscription explicitly
az account set --subscription 9xa2z737-0998-2234-91d6-0a39a06xd913

terraform init
terraform plan
terraform apply
```
The creation will take as long as 20 minutes. With the following output:
```sh
bastion_login = "kubeadmin@121.234.84.104"
kube_config = <sensitive>
kubernetes_cluster_name = "kind-macaque-aks_cluster_main"
```

The first result is the username and public IP of bastion host. The kubernetes cluster is on private subnet and its API server is not publicly accessible. The bastion host has network route to the API server and will have kubectl configured automatically. From your environment SSH to the bastion host, and wait until the cloud init process finish configuring kubectl. You can watch the log for cloud init with:
```sh
tail -F /var/log/cloud-init-output.log
```
Then we can test kubectl access with a command, which should first prompt you to login to Azure with device code:
```sh
kubectl get no
```
Once loggined to Azure from portal. The command should return something like:
```sh
W0506 17:51:17.456782    3900 azure.go:92] WARNING: the azure auth plugin is deprecated in v1.22+, unavailable in v1.25+; use https://github.com/Azure/kubelogin instead.
To learn more, consult https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code EL2USX792 to authenticate.
NAME                             STATUS   ROLES   AGE     VERSION
aks-sysnp0-19666103-vmss000000   Ready    agent   12m     v1.23.3
aks-wlnp1-17983182-vmss000000    Ready    agent   5m18s   v1.23.3
aks-wlnp1-17983182-vmss000001    Ready    agent   6m28s   v1.23.3
aks-wlnp1-17983182-vmss000002    Ready    agent   5m39s   v1.23.3
```

## AWS Elastic Kubernetes Service
The template will create an EKS cluster with Terraform template