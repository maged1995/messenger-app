eksctl create cluster --name testCluster --region eu-central-1 --nodegroup-name linux-nodes --node-type t2.large --nodes 1

export FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')

kubectl label nodes ${FIRST_NODE_NAME} server-name=serverA

eksctl create iamserviceaccount \
  --cluster=testCluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::371713243830:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve \
  --region eu-central-1

kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml