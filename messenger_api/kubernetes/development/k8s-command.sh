#!/bin/bash

# aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 371713243830.dkr.ecr.us-east-1.amazonaws.com
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 371713243830.dkr.ecr.us-east-1.amazonaws.com/django-app


# kubectl create secret generic secret-registry \
#   --from-file=.dockerconfigjson=~/.docker/config.json \
#   --type=kubernetes.io/dockerconfigjson


kubectl create secret docker-registry secret-registry \
  --docker-server=371713243830.dkr.ecr.us-east-1.amazonaws.com/django-app \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)


kubectl apply -f messenger-secrets.yaml
kubectl apply -f docker-secrets.yaml
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
kubectl apply -f messenger-configmap.yaml 
kubectl apply -f django.yaml

# kubectl delete -f messenger-secrets.yaml
# kubectl delete -f docker-secrets.yaml
# kubectl delete -f postgres.yaml
# kubectl delete -f redis.yaml
# kubectl delete -f messenger-configmap.yaml
# kubectl delete -f django.yaml

# kubectl get pod
# kubectl get pod --watch
# kubectl get pod -o wide
# kubectl get service
# kubectl get secret
# kubectl get all | grep mongodb.