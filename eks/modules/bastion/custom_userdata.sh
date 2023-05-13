#! /bin/bash
echo "Entering custom script"

cat << 'EOF' > /home/ec2-user/configure_kubectl_cognito_user.sh
#!/bin/bash

source init_cognito_config.sh

kubectl create clusterrolebinding cluster-admin-role-binding --clusterrole=cluster-admin --group=gid:$cluster_admin_cognito_group

authn_result=$(aws cognito-idp admin-initiate-auth --auth-flow ADMIN_USER_PASSWORD_AUTH --client-id $cognito_oidc_client_id --auth-parameters USERNAME=$cognito_username,PASSWORD=$cognito_password --user-pool-id $cognito_user_pool_id --query "AuthenticationResult.[RefreshToken, IdToken]" --region $aws_region)

refresh_token=$(echo $authn_result | jq -r .[0])
id_token=$(echo $authn_result | jq -r .[1])

kubectl config set-credentials cognito-user \
  --auth-provider=oidc \
  --auth-provider-arg=idp-issuer-url=$cognito_oidc_issuer_url \
  --auth-provider-arg=client-id=$cognito_oidc_client_id \
  --auth-provider-arg=refresh-token=$refresh_token \
  --auth-provider-arg=id-token=$id_token

kubectl config set-context oidc-admin --cluster $eks_cluster_arn --user cognito-user
kubectl config use-context oidc-admin
EOF

chown ec2-user:ec2-user /home/ec2-user/configure_kubectl_cognito_user.sh && chmod u+wx /home/ec2-user/configure_kubectl_cognito_user.sh
echo "Leaving custom script"
