#!/bin/bash

STAGING_CLUSTER_NAME=$(aws eks list-clusters | jq -r '.clusters[0]')
OWNER_ID=371713243830

ROLE_ARN=$(eksctl get iamidentitymapping --cluster $STAGING_CLUSTER_NAME --region us-east-1 -o json | jq -r '.[0].rolearn')

aws iam detach-role-policy \
  --role-name ${ROLE_ARN:31} \
  --policy-arn arn:aws:iam::$OWNER_ID:policy/AWSLoadBalancerControllerIAMPolicy

LB_ARN=$(aws elbv2 describe-load-balancers --query 'sort_by(LoadBalancers, &CreatedTime)' | jq -r '.[0].LoadBalancerArn')

# aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN

eksctl delete nodegroup --cluster $STAGING_CLUSTER_NAME --name linux-nodes --region us-east-1

# aws cloudformation delete-stack --stack-name "eksctl-${STAGING_CLUSTER_NAME}-nodegroup-linux-nodes"

eksctl delete cluster --name $STAGING_CLUSTER_NAME --region us-east-1

# aws cloudformation delete-stack --stack-name "eksctl-${STAGING_CLUSTER_NAME}-cluster"

# aws ec2 describe-subnets --filters \
#   Name=tag:kubernetes.io/role/elb,Values=1 \
#   Name=vpc-id,Values=$(echo $CLUSTER_VPC | jq -r '.Vpcs[0].VpcId') | jq -r '.Subnets[0] | {ParameterKey: "SubnetId", ParameterValue: .SubnetId}' > ./staging/aws_config/subnet.json
