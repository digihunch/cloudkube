#! /bin/bash
echo Bootstrapping in progress >> /etc/motd
echo "Entering script myuserdata"

echo aws_region=${aws_region}
echo eks_name=${eks_name}
echo eks_cluster_arn=${eks_cluster_arn}
echo eks_manager_role_arn=${eks_manager_role_arn}
echo cognito_oidc_issuer_url=${cognito_oidc_issuer_url}
echo cognito_user_pool_id=${cognito_user_pool_id}
echo cognito_oidc_client_id=${cognito_oidc_client_id}
echo cluster_admin_cognito_group=${cluster_admin_cognito_group}

yum update -y && yum install -y nc git jq 

curl --silent -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.2/2023-03-17/bin/linux/amd64/kubectl && \
curl --silent -o /usr/local/bin/aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.2/2023-03-17/bin/linux/amd64/aws-iam-authenticator && \
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /usr/local/bin && \
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
chmod ugo+x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/eksctl /usr/local/bin/helm

runuser -l ec2-user -c '
  echo alias k=kubectl >> ~/.bashrc && \
  echo "source <(kubectl completion bash)" >> ~/.bashrc && \
  echo export AWS_REGION=${aws_region} >> ~/.bashrc && \
  echo export CLUSTER_NAME=${eks_name} >> ~/.bashrc && \
  echo export EKS_MANAGER_ROLE_ARN=${eks_manager_role_arn} >> ~/.bashrc && \
  echo export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) >> ~/.bashrc && \
  aws eks update-kubeconfig --region ${aws_region} --name ${eks_name} --role-arn ${eks_manager_role_arn} && \
  cat << EOF > ~/init_cognito_config.sh
#! /bin/bash
export aws_region=${aws_region}
export eks_name=${eks_name}
export eks_cluster_arn=${eks_cluster_arn}
export eks_manager_role_arn=${eks_manager_role_arn}
export cognito_oidc_issuer_url=${cognito_oidc_issuer_url}
export cognito_user_pool_id=${cognito_user_pool_id}
export cognito_oidc_client_id=${cognito_oidc_client_id}
export cluster_admin_cognito_group=${cluster_admin_cognito_group}
export cognito_username=test@example.com
export cognito_password=Blah123$
EOF
'

echo To configure kubectl to use cognito user, check the script configure_cognito_user_kubectl.sh
echo "Leaving script myuserdata"
sed -i 's/Bootstrapping in progress/Bootstrapping completed/g' /etc/motd
