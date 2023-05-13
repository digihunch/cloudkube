# Cloud Kube - Functional Kubernetes cluster implementations on Azure and AWS

Most enterprises start with a secure networking foundation known as lanzing zone and build Kubernetes cluster on top of it. For SMBs and startups without such a landing zone looking to create their own Kubernetes clusters, they have to build both their own networking infrastructure and the cluster. CloudKube aims to serve as an opinionated baseline architecture for this purpose. It includes Terraform templates to create a secure, scalable Kubernetes platform on top of basic but secure networking infrastructures.


## EKS
The Terraform template code is stored in [eks](https://github.com/digihunch/cloudkube/tree/main/eks) directory. It creates the following items:
- A VPC
- Several subnets for different purposes across three availability zones
- A bastion hosts in a private subnet, with common utilities (kubectl, eksctl, helm) installed and configured.
- An EKS cluster with endpoint exposed in private subnet
- Several node groups, including both AMD64 and ARM64 nodes
- Cognito identity store for authenticating management traffic
- Other resources related to IAM and encryption


### Access to Bastion

The template picks up the file `~/.ssh/id_rsa.pub` and add the public key as authorized key on bastion host, as well as EKS nodes.

It is stronly recommended that user connect `kubectl` to the cluster from the Bastion host. You may SSH to the bastion host using [Session Manager plugin for AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). Alternatively, you can use the bastion host as a SOCKS5 proxy, and connect with `kubectl` from your local machine via the [SOCKS5 Proxy](https://kubernetes.io/docs/tasks/extend-kubernetes/socks5-proxy-access-api/).


### Identity for kubectl to connect to API server
As stated in the [documentation](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html), when you create an Amazon EKS cluster using an IAM entity (e.g. IAM user, role, federated user etc), that IAM entity is automatically granted `system:masters` permissions in the cluster's role-based access control (RBAC) configuration in the Amazon EKS control plane. This IAM entity does **not** appear in any visible configuration.

In this project, I first create an IAM role and use the role to create EKS cluster. The role is thereby the implicit master identity for the cluster. The template then creates an EC2 instace as bastion host, who can assume the IAM role and therefore act as the master of the cluster to finish the rest of the configuration from within the cluster. 

This cannot be achieved by using an IAM user to create a cluster. To see what identity kubectl uses to access the cluster, turn on Authentication logging and check API access log from CloudWatch.

Apart from the implicit master, we can also configure the cluster to use any OIDC identity provider. The project implements an AWS Cognito user pool as identity provider, with a hard-coded user credential. It then connects the EKS cluster to the Cognito user pool. The project also provide a script you can use to configure kubectl to use the Cognito identity to connect to the cluster. This part is a re-implementation of [this](https://aws.amazon.com/blogs/containers/introducing-oidc-identity-provider-authentication-amazon-eks/) solution in Terraform. 

### Deployment
First, set the environment variables with the parameter values you wish to customize for Terraform. For example: 
```sh
export AWS_REGION="us-east-1"
export TF_VAR_arm64_nodegroup_count=0 
```
Check out the variables for more options. Then We can deploy the whole stack with the Terraform triology:
```sh
terraform init
terraform plan
terraform apply
```
It can take 30 minutes to create the cluster, at the end, the output will read:
```sh
bastion_info = "i-0bee5f10c7af1f769"
cognito_user_pool = "us-west-2_VmntWU32w"
eks_name = "quality-anchovy-eks-cluster"
```
On the bastion host, you will find the bootstrapping script has already configured kubectl to use the implicit master identity, and prepared the script ([configure_kubectl_cognito_user.sh](https://github.com/digihunch/cloudkube/blob/main/aws/modules/bastion/custom_userdata.sh#L6) in home directory) for you to change kubectl to use Cognito user's identity. Check cloud init script to see what it does and /var/log/cloud-init-out.log for what happened during bootstrapping. 

You can use either identity with kubectl to test cluster functionality. Going into production, to map more IAM users or roles to Kubernetes Roles, follow the [document](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html). For example, if your AWS console session does not have visibility to workloads in [EKS resource view](https://aws.amazon.com/blogs/containers/introducing-kubernetes-resource-view-in-amazon-eks-console/), you will need to map the IAM user with appropriate Kubernetes Role. Suppose your console uses [account's root user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html), you may map it to system master by adding the following entry to `aws-auth` configmap in `kube-system` namespace:
```yaml
  mapUsers: |
    - groups:
      - system:masters
      userarn: arn:aws:iam::<root-account-id>:root
      username: root
```
This change takes effect immediately.
In production the better way to do this is to have a viewer role and ask console user to assume that role.

![Diagram](asset/eks.drawio.png)

Once testing is completed, to tear downt the cluster, destroy the stack:
```sh
terraform destroy
```

## AWS VPC
If the EKS template is too opinionated and the user only needs a basic and secure networking foundation, this template in [`aws_vpc`](https://github.com/digihunch/cloudkube/tree/main/aws_vpc) directory provisions the required networking components (e.g. VPC, subnet, etc) with labelling as well as a bastion host. Users needs to access the bastion host in private subnet via Session Manager. To SSH to the bastion host, configure [Session Manager plugin for AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). 

You may use `eksctl` to build cluster on the existing networking, or build a [ROSA](https://docs.openshift.com/rosa/welcome/index.html) cluster.


## Azure Kubernetes Service
The template needs to run by a service principal with sufficient privilege, such as an owner of a target resource group.

The terraform code template is stored in the [azure](https://github.com/digihunch/cloudkube/tree/main/azure) directory. The template was tested with Terraform executable. The cluster created is integrated with Azure AD. To access the API server using kubectl, you will need to be a member of the AD Group, whose object ID is specified as parameter.

Before deployment, run:
```sh
export TF_VAR_ResourceGroup=AutomationTest
export TF_VAR_AdminGroupGUID=74d661ce-cce6-4aed-830d-5abc732a1132
export TF_VAR_cli_cidr_block=$(timeout 2 dig +short myip.opendns.com @resolver1.opendns.com || curl http://checkip.amazonaws.com)/32
```

The value of environment variable TF_VAR_cli_cidr_block will be passed to Terraform as input variable. The Bastion host will open port 22 to any IP address on the CIDR. The dig command gets the public IP of the terminal to run terraform. It the input variable cli_cidr_block is not provided, it defaults to 0.0.0.0/0.

The Terraform template will assign the specified Azure AD group as administrator to the newly created AKS cluster. This activity requires owner permission on the AKS cluster. Since the cluster is not created until the Terraform template is run, we need grant the Azure user owner permisson for the whole resource group.

The Azure AD group that is specified as cluster administrator by UUID, must be a [security-enabled](https://docs.microsoft.com/en-us/graph/api/resources/groups-overview?view=graph-rest-1.0#group-types-in-azure-ad-and-microsoft-graph) AD group. Group type of an AD group can be viewed on Azure portal.

The bastion host will load up a public key fetched from your local environment (~/.ssh/id_rsa.pub). If that is not the public key you want to give out, specify the key value in TF_VAR_pubkey_data.
Then we can login to azure and run terraform from the directory:
```sh
export TF_VAR_cli_cidr_block=$(timeout 2 dig +short myip.opendns.com @resolver1.opendns.com || curl http://checkip.amazonaws.com)/32
# Log in to Azure, If your environment does not have browsers prompted, use --use-device-code switch
az login

# if not on correct subscription by default, set subscription explicitly
az account set --subscription 9xa2z737-0998-2234-91d6-0a39a06xd913

terraform init
terraform plan
terraform apply
```
The cluster creation will take as long as 20 minutes. With the following output:
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