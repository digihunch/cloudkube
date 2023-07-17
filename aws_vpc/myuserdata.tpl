#! /bin/bash
echo "Entering script myuserdata"
echo Bootstrapping in progress >> /etc/motd
echo aws_region=${aws_region}
yum update -y
yum install -y nc git jq

curl --silent --location "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz" | tar xz -C /usr/local/bin --exclude 'README.md' && \
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /usr/local/bin && \
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
chmod ugo+x /usr/local/bin/kubectl /usr/local/bin/oc /usr/local/bin/eksctl /usr/local/bin/helm

runuser -l ec2-user -c '
  echo alias k=kubectl >> ~/.bashrc && \
  echo "source <(kubectl completion bash)" >> ~/.bashrc && \
  echo export AWS_REGION=${aws_region} >> ~/.bashrc && \
  echo export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) >> ~/.bashrc
'
sed -i 's/Bootstrapping in progress/Bootstrapping completed/g' /etc/motd
echo "Leaving script myuserdata"
