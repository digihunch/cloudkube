#! /bin/bash
echo "Entering script myuserdata"

echo aws_region=${aws_region}
echo eks_name=${eks_name}
echo eks_cluster_arn=${eks_cluster_arn}
echo eks_manager_role_arn=${eks_manager_role_arn}
echo cognito_oidc_issuer_url=${cognito_oidc_issuer_url}
echo cognito_user_pool_id=${cognito_user_pool_id}
echo cognito_oidc_client_id=${cognito_oidc_client_id}
echo cluster_admin_cognito_group=${cluster_admin_cognito_group}

yum update -y
yum install -y nc git jq 
yum remove awscli -y 
runuser -l ec2-user -c 'curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update'

runuser -l ec2-user -c 'curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.7/2022-10-31/bin/linux/amd64/kubectl &&
curl -o aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.7/2022-10-31/bin/linux/amd64/aws-iam-authenticator &&
mkdir -p $HOME/bin && chmod +x ./kubectl && chmod +x ./aws-iam-authenticator && 
mv ./kubectl $HOME/bin/kubectl && mv ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && 
export PATH=$PATH:$HOME/bin && echo "export PATH=$PATH:$HOME/bin" >> ~/.bashrc && echo alias k=kubectl >> ~/.bashrc && echo "source <(kubectl completion bash)" >> ~/.bashrc && echo export AWS_REGION=${aws_region} >> ~/.bashrc && echo export CLUSTER_NAME=${eks_name} >> ~/.bashrc && echo export EKS_MANAGER_ROLE_ARN=${eks_manager_role_arn} >> ~/.bashrc && echo export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) >> ~/.bashrc'

runuser -l ec2-user -c 'curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &&
chmod 700 get_helm.sh && ./get_helm.sh && rm get_helm.sh'

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

runuser -l ec2-user -c 'aws eks update-kubeconfig --region ${aws_region} --name ${eks_name} --role-arn ${eks_manager_role_arn}'

echo aws eks update-kubeconfig --region ${aws_region} --name ${eks_name} --role-arn ${eks_manager_role_arn}
echo Connect to cluster with kubectl >> /etc/motd
echo To configure kubectl to use cognito user, check the script configure_cognito_user_kubectl.sh

runuser -l ec2-user -c 'cat << EOF > ~/init_cognito_config.sh
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
echo "Leaving script myuserdata"
