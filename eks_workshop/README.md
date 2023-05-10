## How to create internet-facing and internal Services

On EKS, always use the latest version of AWS Load Balancer Controller. With this controller, EKS provisions an NLB when a LoadBalancer Type of Service object is created in Kubernetes, or a ALB when a Kubernetes standard Ingress object is created. Most of the time, I use my own choice of Ingress CRD on top of a Service Object with Load Balancer type. Therefore I only care about using NLB, which also reduces dependency on CSP.

EKS needs to have the permission to provision load balancers. Although it can inherit this permission from the IAM role of the Node's instance profile, for finer grain control, we should use the IRSA (IAM role for Service Account) permission model. We need to create a service account that links to the Load Balancer Controller as well as a separate IAM role that can create load balancers. 

1. Install the latest version of AWS Load Balancer Controller (v2.5.1 as of May 2023), following option A of [this page](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/#option-a-iam-roles-for-service-accounts-irsa), or the [document](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html). 
Note, the documentation includes both options (with eksctl and with aws cli) to configure IRSA and role. To use eksctl we may need to use a different caller identity. 

2. Label the subnets for internal and external load balancers. For HA, there should be multiple subnets for each purposes.

3. Create Service Object with appropriate annotations:

```sh

CLUSTER_NAME=abc
eksctl utils associate-iam-oidc-provider \
    --region $AWS_REGION \
    --cluster $CLUSTER_NAME \
    --approve
# enable OIDC provider

eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::662890235123:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
# note, this command creates the role, and the role only needs to be created once in the account.

helm repo add eks https://aws.github.io/eks-charts && helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

kubectl get deployment -n kube-system aws-load-balancer-controller
```
3. Ensure that the subnets for load balancer are labeled as:
- `kubernetes.io/role/internal-elb=1` for hosting internal lbs
- `kubernetes.io/role/elb=1` for hosting internet-facing lbs

4. Follow the section (Optional) Deploy a sample application, on the [document](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)

5. Change the load balancer type to internal. For more annotation options, read the [controller documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/).

