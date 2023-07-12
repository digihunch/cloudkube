
The purpose of this example is to separate network stack from EKS cluster.
1. It creates networking stack for EKS cluster with Terraform, with bastion host
2. The terraform output also specifies the eksctl command to create a cluster
3. It creates a private EKS cluster using eksctl with Fargate profile. 

Use this stack to create private cluster with Fargate provile and minimized standing cost.

1 x Bastion EC2
1 x EKS control plane
1 x Fargate 
3 x NAT Gateway

```sh
terraform init
terraform plan
terraform apply

# The apply output includes
# 1. Bastion Host instance ID
# 2. Bastion Host Security Group ID
# 3. Next set of commands to set environment variable
# Load the environment variables, then create private cluster using eksctl
envsubst < private-cluster.yaml.tmpl | tee | eksctl create cluster -f -
```
Cluster creation may take more than 20 minutes, with public endpoint disabled at the end and no access to cluster endpoint from outside of the VPC. 

Then use SOCKS5 proxy to connect from outside of VPC: 

``````
BASTION_SECURITY_GROUP_ID=$(terraform output -raw bastion_sg_id)
CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name private-cluster --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
 
# In Cluster Endpoint's security group, open up port 443 to Bastion host
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SECURITY_GROUP_ID --source-group $BASTION_SECURITY_GROUP_ID --protocol tcp --port 443
 
# Test with connecting to Bastion host with ssh i-0750643179667a5b6, assuming .ssh/config file is configured as above. From the bastion host, you can test:
# curl -k https://EC5405EE1846F19F9F61ED28FB12A6A9.sk1.us-west-2.eks.amazonaws.com/api  
# if you get an HTTP response, even an error code 403, the bastion host has TCP connectivity to cluster endpoint
 
# then we can start an SSH session as a SOCKS5 proxy on the remote host
ssh -D 1080 -q -N i-0750643179667a5b6
 
# add > /dev/null 2>&1 & to push it to background, or use ctrl+z after running the command
# to validate that the SOCKS5 proxy is working, you can run the same curl command with a proxy parameter:
# curl -k https://EC5405EE1846F19F9F61ED28FB12A6A9.sk1.us-west-2.eks.amazonaws.com/api --proxy socks5://localhost:1080
 
# you can instruct kubectl to use the SOCKS5 proxy with the following environment variable
export HTTPS_PROXY=socks5://localhost:1080
 
kubectl get node
```