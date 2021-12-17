#! /bin/bash
echo "Entering custom script"
ComName=`curl -s http://169.254.169.254/latest/meta-data/public-hostname|cut -d. -f2-`

runuser -l ec2-user -c 'CURRENT_VERSION=$(curl -Ls https://api.github.com/repos/Versent/saml2aws/releases/latest  | jq -r .tag_name | cut -dv -f2) && wget -c https://github.com/Versent/saml2aws/releases/download/v${CURRENT_VERSION}/saml2aws_${CURRENT_VERSION}_linux_amd64.tar.gz -O - | tar -xzv -C ~/bin && chmod u+x ~/bin/saml2aws'


runuser -l ec2-user -c 'cat << EOF > ~/.saml2aws
[default]
name                    = default
app_id                  = 78098f11-e173-4427-8c3e-3506ad71aea9
url                     = https://account.activedirectory.windowsazure.com
username                = first.last@company.com
provider                = AzureAD
mfa                     = PhoneAppNotification
skip_verify             = false
timeout                 = 0
aws_urn                 = urn:amazon:webservices
aws_session_duration    = 14400
aws_profile             = org 
resource_id             =
subdomain               =
role_arn                =
region                  =
http_attempts_count     =
http_retry_delay        =
credentials_file        =
saml_cache              = false
disable_remember_device = false
disable_sessions        = false
EOF
'

echo "Leaving custom script"
