#! /bin/bash
echo "Entering init script"
echo alias k=kubectl >> /home/${os_user}/.bashrc
echo export KUBECONFIG=/home/${os_user}/.kube/config >> /home/${os_user}/.bashrc
echo "Before using kubectl, run: kubelogin convert-kubeconfig" >> /etc/motd
echo "${id_rsa}" > /home/${os_user}/.ssh/id_rsa
echo "${id_rsa_pub}" > /home/${os_user}/.ssh/id_rsa.pub
chown ${os_user}:${os_user} /home/${os_user}/.ssh/id_rsa && chmod 600 /home/${os_user}/.ssh/id_rsa
chown ${os_user}:${os_user} /home/${os_user}/.ssh/id_rsa.pub && chmod 644 /home/${os_user}/.ssh/id_rsa.pub
apt-get update
apt-get install -y apt-transport-https ca-certificates curl unzip

### Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

### Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

### Configure kubelogin
echo "KUBE_CLUSTER_FQDN=${cluster_fqdn}"
echo "KUBECONFIG=\n${kube_config}"
mkdir -p /home/${os_user}/.kube && echo "${kube_config}" > /home/${os_user}/.kube/config
sed -i -e 's/config-mode: 1/config-mode: \"1\"/g' /home/${os_user}/.kube/config
chown -R ${os_user}:${os_user} /home/${os_user}/.kube && chmod -R 700 /home/${os_user}/.kube
cd /tmp && wget https://github.com/Azure/kubelogin/releases/download/v0.0.30/kubelogin-linux-amd64.zip && unzip kubelogin-linux-amd64.zip && sudo mv bin/linux_amd64/kubelogin /usr/local/bin


echo "Leaving init script"
