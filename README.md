# cloud kube

Cloud Kube project includes Terraform templates to create secure, scalable Kubernetes platforms with relevant logging and monitoring construct in Azure and AWS. It aims to serve as a opinionated baseline architecture for production use. 

This project does NOT aim to be portable to any client environment because different Kubernetes deployments have significant architectural variations.

## Azure Kubernetes Service
The template needs to run by a service principal with sufficient privilege, such as an owner of a target resource group.

The terraform code template is stored in the [azure](https://github.com/digihunch/cloudkube/tree/main/azure) directory. The template was tested with Terraform executable. The cluster created is integrated with Azure AD. To access the API server using kubectl, you will need to be a member of the AD Group, whose object ID is specified as parameter.

Before deployment, run:
```sh
export TF_VAR_ResourceGroup=AutomationTest
export TF_VAR_AdminGroupGUID=74d661ce-cce6-4aed-830d-5abc732a1132
```
The bastion host will load up a public key fetched from your local environment (~/.ssh/id_rsa.pub). If that is not the public key you want to give out, specify the key value in TF_VAR_pubkey_data.
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

The first result is the username and public IP of bastion host. The kubernetes cluster is on private subnet and its API server is not publicly accessible. The bastion host has network route to the API server and will have kubectl configured automatically. From your environment SSH to the bastion host, and wait until the cloud init process finish configuring kubectl. You can watch the log for cloud init with a tail command and initialize kubelogin
```sh
tail -F /var/log/cloud-init-output.log
kubelogin convert-kubeconfig
```
Since May 2022, we changed to use [kubelogin](https://github.com/Azure/kubelogin) as a helper to kubectl for connection because the azure auth plugin is deprecated in v1.22+ and becomes unavailable in v1.25+. We configured [kubelogin](https://github.com/Azure/kubelogin#device-code-flow-interactive) for interactive login with device code.
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
Once testing is completed, to tear downt the cluster, destroy the stack:
```sh
terraform destroy
```
## AWS Elastic Kubernetes Service
The code is stored in [aws](https://github.com/digihunch/cloudkube/tree/main/aws) directory. The template will create a VPC with private subnet and an EKS cluster with Terraform template. A bastion host is created on one of the public subnet of the same VPC, with access to the cluster API server.
API server authentication is based on the user AWS IAM user. It is not configured for OIDC integration with any third party identity store.

Since I use saml2aws to log into my AWS account, the following steps is based on this assumption. The bastion host also needs to have saml2aws configured for user to log in correctly, in order to connect to the cluster API server from the bastion host.

From your environment, log on to aws using saml2aws:
```sh
saml2aws login
```
The configuration of saml2aws is stored in ~/.saml2aws file, including the profile name. Suppose the profile name is org.
```sh
export AWS_REGION="us-east-1"
export AWS_PROFILE="org"

terraform init
terraform plan
terraform apply
```
It can take 20 minutes to create the cluster, at the end, the output will read:
```sh
bastion_info = "ec2-user@ec2-44-201-17-43.compute-1.amazonaws.com"
eks_endpoint = "https://0ED83B8BD5F9550243D5563A8D9E8A92.gr7.us-east-1.eks.amazonaws.com"
```
The end point will only be accessible from bastion host. SSH to bastion host. The public key is fetched from your environment (~/.ssh/id_rsa.pub file) so SSH should just work. Once logged onto the bastion host, the motd should read something like:

To configure kubectl, edit .saml2aws with app_id, url, username, then run the following to login again on the bastion host. This will allow the IAM user to configure its kubeconfig:
```sh
saml2aws login
aws eks update-kubeconfig --name clean-glider-eks-cluster --profile org --region us-east-1
```
The cluster name in this case is clean-glider-eks-cluster. Once cloud-init has completed, run the two commands as instructed. The second should configure kubeconfig automatically.
```sh
[ec2-user@ip-147-207-0-226 ~]$ saml2aws login
Using IdP Account default to access AzureAD https://account.activedirectory.windowsazure.com
To use saved password just hit enter.
? Username first.last@myorg.com
? Password *************

Authenticating as first.last@myorg.com ...
Phone approval required.
Selected role: arn:aws:iam::762497387634:role/my-org-account
Requesting AWS credentials using SAML assertion.
Logged in as: arn:aws:sts::762497387634:assumed-role/my-org-account/first.last@myorg.com

Your new access key pair has been stored in the AWS configuration.
Note that it will expire at 2022-05-07 04:22:38 +0000 UTC
To use this credential, call the AWS CLI with the --profile option (e.g. aws --profile org ec2 describe-instances).
[ec2-user@ip-147-207-0-226 ~]$ aws eks update-kubeconfig --name clean-glider-eks-cluster --profile org --region us-east-1
Added new context arn:aws:eks:us-east-1:762497387634:cluster/clean-glider-eks-cluster to /home/ec2-user/.kube/config
```
With this we should be able to connect with kubectl:
```sh
kubectl get no
NAME                            STATUS   ROLES    AGE     VERSION
ip-147-207-1-27.ec2.internal    Ready    <none>   4m31s   v1.21.5-eks-9017834
ip-147-207-2-135.ec2.internal   Ready    <none>   4m23s   v1.21.5-eks-9017834
ip-147-207-2-222.ec2.internal   Ready    <none>   4m17s   v1.21.5-eks-9017834
ip-147-207-3-8.ec2.internal     Ready    <none>   4m43s   v1.21.5-eks-9017834
```
Once testing is completed, to tear downt the cluster, destroy the stack:
```sh
terraform destroy
```
