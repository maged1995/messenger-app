#!/bin/bash

docker login --username $DOCKERHUB_USERNAME --password $DOCKERHUB_PASSWORD

OWNER_ID=371713243830
CREATION_DATE=$(date +"%y%m%d%H%M%S")
STAGING_CLUSTER_NAME=stagingCluster-$CREATION_DATE
PROJECT_NAME=messenger

DB_NAME=${DB_NAME} DB_USER=${DB_USER} \
DB_PASS=${DB_PASS} DB_HOST=${DB_HOST} \
KEY_ID=${AWS_ACCESS_KEY_ID} ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
BUCKET_NAME=${S3_BUCKET_NAME} yq -i '
  .stringData.postgres-db = strenv(DB_NAME) |
  .stringData.postgres-user = strenv(DB_USER) |
  .stringData.postgres-pass = strenv(DB_PASS) |
  .stringData.postgres-host = strenv(DB_HOST) |
  .stringData.aws-access-key-id = strenv(KEY_ID) |
  .stringData.aws-secret-access-key = strenv(ACCESS_KEY) |
  .stringData.aws-bucket-name = strenv(BUCKET_NAME)
  ' ./staging/messenger-secrets.yaml

if docker build -t django-app ./messenger_api | grep 'Successfully built'; then
  :
else 
  exit 1
fi

docker image tag django-app maged1995/django-app:$CREATION_DATE
docker image tag django-app maged1995/django-app:latest

docker image push maged1995/django-app:$CREATION_DATE
docker image push maged1995/django-app:latest

eksctl create cluster --name $STAGING_CLUSTER_NAME --region us-east-1 --nodegroup-name linux-nodes --node-type t2.medium --nodes 1

FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')

kubectl label nodes ${FIRST_NODE_NAME} server-name=serverA

eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=$STAGING_CLUSTER_NAME --approve

# eksctl create iamserviceaccount \
#   --cluster=$STAGING_CLUSTER_NAME \
#   --namespace=kube-system \
#   --name=aws-load-balancer-controller \
#   --attach-policy-arn=arn:aws:iam::$OWNER_ID:policy/AWSLoadBalancerControllerIAMPolicy \
#   --override-existing-serviceaccounts \
#   --approve \
#   --region us-east-1

kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

CLUSTER_VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-$STAGING_CLUSTER_NAME-cluster/VPC)

echo $CLUSTER_VPC | jq '.Vpcs[0] | {ParameterKey: "VpcId", ParameterValue: .VpcId}' > ./staging/aws_config/vpc.json

ROLE_ARN=$(eksctl get iamidentitymapping --cluster $STAGING_CLUSTER_NAME --region us-east-1 -o json | jq -r '.[0].rolearn')

echo $ROLE_ARN

aws iam attach-role-policy \
  --role-name ${ROLE_ARN:31} \
  --policy-arn arn:aws:iam::$OWNER_ID:policy/AWSLoadBalancerControllerIAMPolicy

echo "policy attached"

VPC_ID=$(echo $CLUSTER_VPC | jq -r '.Vpcs[0].VpcId')

aws ec2 describe-subnets --filters \
  Name=tag:kubernetes.io/role/elb,Values=1 \
  Name=vpc-id,Values=$VPC_ID | jq -r '.Subnets[0] | {ParameterKey: "SubnetId", ParameterValue: .SubnetId}' > ./staging/aws_config/subnet.json

echo "subnets"

aws ec2 create-tags --resources $VPC_ID --tags Key=appName,Value=$PROJECT_NAME

echo "vpc tagged"

PROJECT_VPCS=$(aws ec2 describe-vpcs --filters Name=tag:appName,Values=$PROJECT_NAME)

echo $PROJECT_VPCS

name=minimal-ingress-$CREATION_DATE yq eval \
  '.metadata.name = env(name)' \
  staging/templates/ingress.yaml > staging/ingress.yaml

#AFTER kubectl apply

kubectl apply -f ./staging

ALB=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .LoadBalancerName')

# ALB=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | select(.Scheme == "internal") | .LoadBalancerName')

while [ -z $ALB ]
do
  echo 'waiting for Application Load Balancer to be created'
  sleep 30s
  ALB=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .LoadBalancerName')
done

ALB_STATE=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .State.Code')

while [ $ALB_STATE != "active" ]
do
  echo 'waiting for Application Load Balancer to be active'
  sleep 30s
  ALB_STATE=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .State.Code')
done

aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | {ParameterKey: "LoadBalancerARN", ParameterValue: .LoadBalancerArn}' > ./staging/aws_config/alb.json

jq -s '.' ./staging/aws_config/subnet.json ./staging/aws_config/vpc.json ./staging/aws_config/alb.json > ./staging/aws_config/routing.json

# delete network load balancer stack, if exists

if aws elbv2 describe-load-balancers | grep "internet-facing"; then 
  aws cloudformation delete-stack --stack-name "${PROJECT_NAME}-networking"
fi

# wait for stack to finish deleting old network load balancer stack, if exists

NLB_STATE=$(aws elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | select(.Scheme == "internet-facing") | .State.Code')

while [ -z ! $NLB_STATE ]
do
  echo 'waiting for Network Load Balancer to be deleted'
  sleep 30s
  NLB_STATE=$(aws elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | select(.Scheme == "internet-facing") | .State.Code')
done

aws cloudformation deploy --template-file ./staging/aws_config/routing.yml --tags project=$PROJECT_NAME --stack-name "${PROJECT_NAME}-networking" --parameter-overrides file://staging/aws_config/routing.json

