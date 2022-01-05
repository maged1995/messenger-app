#!/bin/bash

OWNER_ID=371713243830
CREATION_DATE=$(date +"%y%m%d%H%M%S")
STAGING_CLUSTER_NAME=stagingCluster-$CREATION_DATE
PROJECT_NAME=messenger

if docker build -t django-app ./messenger_api | grep 'Successfully built'; then
  :
else 
  exit 1
fi

docker image tag django-app maged1995/django-app:$CREATION_DATE
docker image tag django-app maged1995/django-app:latest

docker image push maged1995/django-app:$CREATION_DATE
docker image push maged1995/django-app:latest

eksctl create cluster --name $STAGING_CLUSTER_NAME --region eu-central-1 --nodegroup-name linux-nodes --node-type t2.medium --nodes 1

FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')

kubectl label nodes ${FIRST_NODE_NAME} server-name=serverA

eksctl utils associate-iam-oidc-provider --region=eu-central-1 --cluster=$STAGING_CLUSTER_NAME --approve

# eksctl create iamserviceaccount \
#   --cluster=$STAGING_CLUSTER_NAME \
#   --namespace=kube-system \
#   --name=aws-load-balancer-controller \
#   --attach-policy-arn=arn:aws:iam::$OWNER_ID:policy/AWSLoadBalancerControllerIAMPolicy \
#   --override-existing-serviceaccounts \
#   --approve \
#   --region eu-central-1

kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

CLUSTER_VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-$STAGING_CLUSTER_NAME-cluster/VPC)

echo $CLUSTER_VPC | jq '.Vpcs[0] | {ParameterKey: "VpcId", ParameterValue: .VpcId}' > ./staging/aws_config/vpc.json

ROLE_ARN=$(eksctl get iamidentitymapping --cluster $STAGING_CLUSTER_NAME --region eu-central-1 -o json | jq -r '.[0].rolearn')

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

aws cloudformation deploy --template-file ./staging/aws_config/routing.yml --tags project=$PROJECT_NAME --stack-name "${PROJECT_NAME}-networking" --parameter-overrides file://staging/aws_config/routing.json