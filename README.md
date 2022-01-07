# cloudkube

Cloud Kube project includes Terraform templates to create secure, scalable Kubernetes platforms with relevant logging and monitoring construct in Azure and AWS. It aims to serve as a baseline for production use.


## Azure Kubernetes Service
The template needs to run by a service principal with sufficient privilege, such as an owner of a target resource group.

The following environment variables are expected for Terraform:
- ARM_SUBSCRIPTION_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_ENVIRONMENT
- ARM_TENANT_ID


For input variables required, refer to README.md in the azure directory. 

## AWS Elastic Kubernetes Service
The template will create an EKS cluster with Terraform template