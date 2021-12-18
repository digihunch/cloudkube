#! /bin/bash
echo "Entering custom script"
ComName=`curl -s http://169.254.169.254/latest/meta-data/public-hostname|cut -d. -f2-`

runuser -l ec2-user -c 'CURRENT_VERSION=$(curl -Ls https://api.github.com/repos/Versent/saml2aws/releases/latest  | jq -r .tag_name | cut -dv -f2) && wget -c https://github.com/Versent/saml2aws/releases/download/v${CURRENT_VERSION}/saml2aws_${CURRENT_VERSION}_linux_amd64.tar.gz -O - | tar -xzv -C ~/bin && chmod u+x ~/bin/saml2aws'


echo "Leaving custom script"
