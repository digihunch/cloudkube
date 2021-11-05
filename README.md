# cloudkube

Cloud Kube project is for Terraform templates to create secure, produciton grade Kubernetes clusters and relevant logging and monitoring stack in Azure and AWS.


## Azure
The template needs to run with a service principal with sufficient privilege, such as contributor of resource group, without excluding:
- Microsoft.Authorization/*/Write
- Microsoft.Authorization/*/Delete
The following environment variables are expected for Terraform:
- ARM_SUBSCRIPTION_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_ENVIRONMENT
- ARM_TENANT_ID


For input variables required, refer to README.md in the azure directory. 

## AWS
