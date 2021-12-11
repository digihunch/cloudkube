#! /bin/bash
echo "Entering script myuserdata"

echo aws_region=${aws_region}
echo eks_name=${eks_name}
#echo eks_arn=${eks_arn}
echo eks_endpoint=${eks_endpoint}
echo eks_config_certificate=${eks_config_certificate}
echo eks_tls_certificate=${eks_tls_certificate}

yum update -y
yum install -y nc git jq 

runuser -l ec2-user -c 'curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl &&
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator &&
mkdir -p $HOME/bin && chmod +x ./kubectl && chmod +x ./aws-iam-authenticator && 
mv ./kubectl $HOME/bin/kubectl && mv ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && 
export PATH=$PATH:$HOME/bin && echo "export PATH=$PATH:$HOME/bin" >> ~/.bashrc'

runuser -l ec2-user -c 'curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &&
chmod 700 get_helm.sh && ./get_helm.sh && rm get_helm.sh'

runuser -l ec2-user -c 'aws configure set region ${aws_region} && aws eks --region us-east-1 update-kubeconfig --name ${eks_name}'
echo "Leaving script myuserdata"
