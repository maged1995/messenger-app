aws ec2 describe-subnets --filters \
  Name=tag:kubernetes.io/role/elb,Values=1 \
  Name=vpc-id,Values=$(echo $CLUSTER_VPC | jq -r '.Vpcs[0].VpcId') | jq -r '.Subnets[0] | {ParameterKey: "SubnetId", ParameterValue: .SubnetId}' > ./staging/aws_config/subnet.json


