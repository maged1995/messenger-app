#!/bin/bash 

# kubectl config (kubectl config get-clusters | grep $TARGET_CLUSTER)

DB_NAME=${DB_NAME} DB_USER=${DB_USER} DB_PASS=${DB_PASS} \
yq -i '
  .stringData.postgres-db = strenv(DB_NAME) |
  .stringData.postgres-user = strenv(DB_USER) |
  .stringData.postgres-pass = strenv(DB_PASS)
  ' ./digital_ocean/kube/kube-settings/messenger-secrets.yaml

if [ "$TARGET_CLUSTER" = "messenger-app-green" ]; then
  doctl kubernetes cluster update messenger-app-blue --tag "staging"
  doctl kubernetes cluster update messenger-app-green --tag "production"
else
  doctl kubernetes cluster update messenger-app-green --tag "staging"
  doctl kubernetes cluster update messenger-app-blue --tag "production"
fi

kubectl delete -f ./digital_ocean/kube
kubectl delete -f ./digital_ocean/kube/kube-settings
kubectl apply -f ./digital_ocean/kube/kube-settings
kubectl apply -f ./digital_ocean/kube

# while [ -z $ALB ]
# do
#   echo 'waiting for Application Load Balancer to be created'
#   sleep 30s
#   ALB=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .LoadBalancerName')
# done

# ALB_STATE=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .State.Code')

# while [ $ALB_STATE != "active" ]
# do
#   echo 'waiting for Application Load Balancer to be active'
#   sleep 30s
#   ALB_STATE=$(aws elbv2 describe-load-balancers | jq -r --arg VPC_ID "$VPC_ID" '.LoadBalancers[] | select(.VpcId == $VPC_ID) | .State.Code')
# done
