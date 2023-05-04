# AppMesh Ingress Workshop

This is a workshop for AWS AppMesh based on the [ingress](https://github.com/aws/aws-app-mesh-examples/tree/main/walkthroughs/howto-k8s-ingress-gateway) example. It involves creating an EKS cluster and configure AppMesh for Ingress.

## Create an EKS cluster
Use the terraform template in cloudkube/aws to provision an EKS cluster and supporting resources. There are more than 50 resources and the whole process may take more than 30 minutes. Ensure the Terraform running environment remain connected with AWS. At the end, the output should print:
```sh
bastion_info = "ec2-user@ec2-35-166-73-32.us-west-2.compute.amazonaws.com"
cognito_user_pool = "us-west-2_hroD6VBSi"
eks_name = "decent-fly-eks-cluster"
eks_su_arn = "arn:aws:sts::9876543210:assumed-role/decent-fly-eks-manager-role/aws-go-sdk-1676524906050727000"
```
The template grabs SSH key from running environment and you should be able to SSH to Bastion host.

## Connect to Bastion host
The cloudkube template makes a dozen configurations automatically and we want to ensure they are done correctly. 

As soon as you connect to the Bastion host by SSH, environment variables `AWS_REGION`, `CLUSTER_NAME`, `EKS_MANAGER_ROLE_ARN` and `AWS_ACCOUNT_ID` should be set. They will be used in the future steps. You can echo them to ensure they are populated.


## Install AppMesh Controller
At first, we add the Helm repo, create required CRDs and namespace for AppMesh:
```sh
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"
kubectl create ns appmesh-system
```
As a managed service, AppMeesh needs to communicate with AWS backend, which allows user to create AppMesh objects from AWS console. So before installing AppMesh controller, we need to ensure that its Service Account has sufficient privilege to control AWS resources.

We can use **eksctl** utility to achieve this, in the following steps:
a. associate the cluster with AWS IAM as OIDC provider, which enables IRSA;
b. create a ServiceAccount in the specified namespace in K8s cluster;
c. create an IAM Role for Service Account (IRSA) to define what the Service Account can do on AWS resources in the account;

We let `eksctl` perform step b above as the master user of the cluster. Since the cloudkube template used EKS_MANAGER_ROLE as its IAM identity to create the EKS cluster, we need to let `eksctl` assume the same role in order to act as master user.

The IAM role that `eksctl` on the Bastion host starts with by default is the Instance Role of Bastion host. With that role, we tell `eksctl` to assume the EKS_MANAGER_ROLE by supplying the required environment variables. We can then verify the identity being used after setting the environment variables:
```sh
assume_role_result=$(aws sts assume-role --role-arn $EKS_MANAGER_ROLE_ARN --role-session-name EKS-Manager-Role-Session --output json)
export AWS_ACCESS_KEY_ID=$(echo $assume_role_result | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $assume_role_result | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $assume_role_result | jq -r .Credentials.SessionToken)
aws sts get-caller-identity
```
The output should display the IAM role name of the EKS_MANAGER_ROLE. After that, we can perform step a with `associate-iam-oidc-provider` sub-command, and b and c with `iamserviceaccount` sub-command:
```sh
eksctl utils associate-iam-oidc-provider \
    --region=$AWS_REGION \
    --cluster $CLUSTER_NAME \
    --approve

eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
    --override-existing-serviceaccounts \
    --approve
```
The second command should initialized creation of the specified IAM Role with a CloudFormation stack. Note that we only need to let `eksctl` assume the EKS_MANAGER_ROLE. After `eksctl` command, we should unset those environment variables so that `aws cli` and its dependent (e.g. kubectl login using aws cli) remain unimpacted. 
```
unset AWS_ACCESS_KEY_ID && unset AWS_SECRET_ACCESS_KEY && unset AWS_SESSION_TOKEN
```
After unsetting the variables, we can use helm to install the AppMesh Controller.
```sh
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller
```
We can check the version of AppMesh controller by checking the image version being used. We can also examine the setup by looking at the argument list of the controller pod:
```
kubectl -n appmesh-system get deployment appmesh-controller -o json  | jq -r ".spec.template.spec.containers[].image" | cut -f2 -d ':'
kubectl -n appmesh-system get deploy appmesh-controller -o yaml | less
```
Note, the step to unset the three environment variables is important in our workshop. Because in `~/.kube/config`, we've set up kubectl authentication to be based on `aws eks get-token` with `--role` switch. When kubectl connects to the API server, it invokes `aws cli` command which already explicitly assumes the EKS_MANAGER_ROLE from the instance role. Leaving `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN` defined is to tell the `aws cli` command start from EKS_MANAGER_ROLE to assume itself, which will report error. If kubectl fail to connect to API server, helm commands will fail too.
Unfortunately, in the rest of this workshop, when using `eksctl` command, we have to set the three environment variable again, and unset them afterwards.


## Prepare Workload Namespace
First, let's create the Mesh and the workload namespace, mark it as needing sidecar injection. Once we applied `mesh.yaml`, we can verify it:
```sh
kubectl apply -f mesh.yaml
kubectl describe mesh demo-mesh
```
Then we create the required Serive Account and IRSA, using `eksctl` utility. As explained, we need to get it to assume EKS_MANAGER_ROLE by setting the three environment variables, and unsetting them afterwards. 
```
cat proxy-auth-policy-colorapp-sa.json.tmpl | envsubst > /tmp/proxy-auth-policy-colorapp-sa.json && aws iam create-policy --policy-name enable-policy-authorization-colorapp-sa --policy-document file:///tmp/proxy-auth-policy-colorapp-sa.json
cat proxy-auth-policy-ingress-sa.json.tmpl | envsubst > /tmp/proxy-auth-policy-ingress-sa.json && aws iam create-policy --policy-name enable-policy-authorization-ingress-sa --policy-document file:///tmp/proxy-auth-policy-ingress-sa.json

# Remember to set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN

eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace demo \
    --name colorapp-sa \
    --attach-policy-arn  arn:aws:iam::$AWS_ACCOUNT_ID:policy/enable-policy-authorization-colorapp-sa \
    --override-existing-serviceaccounts \
    --approve

eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace demo \
    --name ingress-sa \
    --attach-policy-arn  arn:aws:iam::$AWS_ACCOUNT_ID:policy/enable-policy-authorization-ingress-sa \
    --override-existing-serviceaccounts \
    --approve

# Remember to unset AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN
```
In the steps above, we first created our own policies with `aws cli`. We then use `eksctl` to create Serivce Accounts and associate them with respective IAM roles that include the policies. These will enable two service accounts so that when we deploy our workload, the Service Account are empowered to inject sidecar containers. 

## Deploy Ingress Gateway and Workload

Now we can deploy the Ingress Gateway, by applying the `ingress.yaml` file. We need to ensure that the Deployment has the Pod in `Ready` status. The Ingress is driven by an Envoy Pod, whose container image is specific to AWS region and you can find the correct image URL [here](https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html). The manifiest includes the 
```sh
kubectl apply -f ingress.yaml
kubectl -n demo get deploy
kubectl -n demo get svc
export GW_ENDPOINT=$(kubectl -n demo get svc ingress-gw --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```
The manifest above includes a Service object of `LoadBalancer` type. It creates an underlying network load balancer connected to the private subnets. We can keep its DNS name in `GW_ENDPOINT` variable for later, but bear in mind that the load balancer may still take some time to warm up. You can check the status of the load balancer on AWS console or CLI. The manifest also consists of Virtual Gateway and Gateway Route resources. If the ingress pod fails to start, check its stdout.

We can then deploy AppMesh's workload routing resources and the actual workload (colorapp) resources:
```sh
kubectl apply -f routing.yaml
kubectl apply -f workload.yaml
kubectl -n demo get po
NAME                          READY   STATUS    RESTARTS   AGE
blue-85999d99f7-zntq8         2/2     Running   0          4h6m
green-7b56c484c5-zfdpd        2/2     Running   0          4h6m
ingress-gw-6748bd85b6-rhsgz   1/1     Running   0          96m
red-7bb745d95f-p6cth          2/2     Running   0          4h6m
white-6f8d5d49bc-7rgnx        2/2     Running   0          4h6m
yellow-5d4c557b89-4kgdr       2/2     Running   0          4h6m
```
Ensure that all Pods in the demo namespace are up and running. Note that the workload Pods have sidecars so they have two containers. If one of them fails to start, check its stdout. For the AppMesh routing resources, you can also see them in AWS console or CLI.

It may take a minute for the settings to apply to the underlying Network Load Balancer. We can verify deployment by sending different paths and headers:
```sh
curl $GW_ENDPOINT/paths/red ; echo;
curl -H "color_header: blue" $GW_ENDPOINT/headers ; echo;
```

If the command does not print expected result, there are a few things to check. The Load Balancer must be internal and has registered targets (nodes). You can also spin up a troubleshooting Pods and perform `curl` and `nc` from within the mesh:
```sh
kubectl -n demo run tmp-shell --rm -i --tty --image nicolaka/netshoot --annotations="appmesh.k8s.aws/sidecarInjectorWebhook=disabled"
```
We need the line of annotation to tell the Mesh to not inject Envoy sidecar. From the throw-away tester Pod, we can test connectivity to the internal IP of pods, and ingress.


## Configure storage class for stateful workload

To configure storage class, we first need to install CSI driver using Helm. The driver deployment uses the IRSA pattern again to communicate with AWS backend. Below are the steps:

```sh
export EBS_CSI_POLICY_NAME="manage-aws-ebs-sa"
# curl -sSL -o ebs-csi-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json
aws iam create-policy \
  --region ${AWS_REGION} \
  --policy-name ${EBS_CSI_POLICY_NAME} \
  --policy-document file://ebs-csi-policy.json
export EBS_CSI_POLICY_ARN=$(aws --region ${AWS_REGION} iam list-policies --query 'Policies[?PolicyName==`'$EBS_CSI_POLICY_NAME'`].Arn' --output text)

# Remember to set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN

eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --name ebs-csi-controller-irsa \
  --namespace kube-system \
  --attach-policy-arn $EBS_CSI_POLICY_ARN \
  --override-existing-serviceaccounts \
  --approve
 
# Remember to unset AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver

helm upgrade --install aws-ebs-csi-driver \
  --version=1.2.4 \
  --namespace kube-system \
  --set serviceAccount.controller.create=false \
  --set serviceAccount.snapshot.create=false \
  --set enableVolumeScheduling=true \
  --set enableVolumeResizing=true \
  --set enableVolumeSnapshot=true \
  --set serviceAccount.snapshot.name=ebs-csi-controller-irsa \
  --set serviceAccount.controller.name=ebs-csi-controller-irsa \
  aws-ebs-csi-driver/aws-ebs-csi-driver
```
We can verify the installation of csi-controller. If successufl, we can then configure a storage class, and a PVC.
```sh
kubectl -n kube-system rollout status deployment ebs-csi-controller
kubectl apply -f prom-sc.yaml
kubectl apply -f pvc.yaml
```
Now, we have a PVC in the appmesh-system namespace, using our own storage class, which has CSI provisioner.


## Observability
First, we install Prometheus with Helm, and specify the PVC we just created.
```sh
helm upgrade -i appmesh-prometheus eks/appmesh-prometheus \
--namespace appmesh-system \
--set retention=12h \
--set persistentVolumeClaim.claimName=prometheus
```
If the Prometheus pod is available in appmesh-system namespace, we can visit the console for Prometheus. We can configure that on the Ingress, or as a shortcut, use port-forwarding:

```sh
kubectl -n appmesh-system port-forward svc/appmesh-prometheus 9090:9090
```

The bastion host does not have a browswer, we can further forward the port to SSH client machine:
```sh
ssh ec2-user@ec2-35-166-73-32.us-west-2.compute.amazonaws.com -L 9090:localhost:9090
```

From the client machine, browse to localhost:9090, In the query box, select a metric, such as `envoy_http_downstream_rq_total` and hit Execute. 

## Clean up
1. Uninstall stateful workload (Prometheus) and delete PVs
```sh
helm -n appmesh-system uninstall appmesh-prometheus
kubectl delete -f pvc.yaml
kubectl -n appmesh-system get pv
kubectl -n appmesh-system delete pv pvc-8c241387-dc1c-4cc5-a44f-e38a1eb95571
kubectl delete -f prom-sc.yaml
```
The PV may take a couple minutes to delete.

2. Delete Workload, Routing, Ingress objects. The Service object with LoadBalancer type is deleted. You should not see a LoadBalancer in AWS Console. 
```sh
k delete -f workload.yaml -f routing.yaml 
k delete -f ingress.yaml -f mesh.yaml
```
3. In AWS Console, go to CloudFormation and delete the stacks created by `eksctl`
4. In AWS Console, delete the policies created above
5. Destroy the EKS cluster using Terraform.
