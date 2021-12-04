#! /bin/bash
echo "Entering script myuserdata"
yum update -y
yum install -y nc git jq 

runuser -l ec2-user -c 'curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl &&
chmod +x ./kubectl && mkdir -p $HOME/bin && mv ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin &&
echo "export PATH=$PATH:$HOME/bin" >> ~/.bashrc'

runuser -l ec2-user -c 'curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &&
chmod 700 get_helm.sh && ./get_helm.sh'

runuser -l ec2-user -c 'aws configure set region ${aws_region}'
echo "Leaving script myuserdata"
