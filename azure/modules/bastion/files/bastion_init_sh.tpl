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
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
curl https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update && apt-get install -y kubectl helm
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
echo "KUBE_CLUSTER_FQDN=${cluster_fqdn}"
echo "KUBECONFIG=\n${kube_config}"
mkdir -p /home/${os_user}/.kube && echo "${kube_config}" > /home/${os_user}/.kube/config
sed -i -e 's/config-mode: 1/config-mode: \"1\"/g' /home/${os_user}/.kube/config
chown -R ${os_user}:${os_user} /home/${os_user}/.kube && chmod -R 700 /home/${os_user}/.kube
cd /tmp && wget https://github.com/Azure/kubelogin/releases/download/v0.0.13/kubelogin-linux-amd64.zip && unzip kubelogin-linux-amd64.zip && sudo mv bin/linux_amd64/kubelogin /usr/local/bin
echo "Leaving init script"
