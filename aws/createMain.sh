CREATION_DATE=$(date +"%y%m%d%H%M%S")

jq -n --arg APPLICATION_NAME "${APPLICATION_NAME}" \
    --arg DB_USER "$DB_USER" \
    --arg DB_PASS "$DB_PASS" \
    --arg BUCKET_NAME "$CREATION_DATE-$APPLICATION_NAME" '[
    {ParameterKey: "ApplicationName", ParameterValue: $APPLICATION_NAME}, 
    {ParameterKey: "DBUsername", ParameterValue: $DB_USER}, 
    {ParameterKey: "DBPassword", ParameterValue: $DB_PASS},
    {ParameterKey: "BucketName", ParameterValue: $BUCKET_NAME}]' > ./staging/aws_config/main.json

aws cloudformation create-stack --stack-name ${APPLICATION_NAME}-main --template-body file://staging/aws_config/main.yml --parameters file://staging/aws_config/main.json --region=us-east-1

# wait for DB and S3 to create

STACK_STATE=$(aws cloudformation describe-stacks --region=us-east-1 | jq -r --arg APPLICATION_NAME "${APPLICATION_NAME}-main" '.Stacks[] | select(.StackName == $APPLICATION_NAME) | .StackStatus')

while [ $STACK_STATE == "CREATE_IN_PROGRESS" ]
do
  echo 'waiting for Stack to be created'
  sleep 30s
  STACK_STATE=$(aws cloudformation describe-stacks --region=us-east-1 | jq -r --arg APPLICATION_NAME "${APPLICATION_NAME}-main" '.Stacks[] | select(.StackName == $APPLICATION_NAME) | .StackStatus')
done

# check if creation is successful, else: delete it

 STACK_STATE=$(aws cloudformation describe-stacks --region=us-east-1 | jq -r --arg APPLICATION_NAME "${APPLICATION_NAME}-main" '.Stacks[] | select(.StackName == $APPLICATION_NAME) | .StackStatus')

if [ $STACK_STATE != "CREATE_COMPLETE" ]
then 
    aws cloudformation delete-stack --stack-name ${APPLICATION_NAME}-main --region=eu-central-1
fi

STACK_OUTPUT=$(aws cloudformation describe-stacks --region=us-east-1 | jq -r --arg APPLICATION_NAME "${APPLICATION_NAME}-main" '.Stacks[] | .Outputs[]')

DB_LINK=$(echo $STACK_OUTPUT | jq -r 'select(.OutputKey == "WebAppDatabaseEndpoint") | .OutputValue')

echo "POSTGRES_DB=${APPLICATION_NAME}" >> ./messenger_api/.env
echo "POSTGRES_USER=${DB_USER}" >> ./messenger_api/.env
echo "POSTGRES_PASSWORD=${DB_PASS}" >> ./messenger_api/.env
echo "PGDATABASE=${APPLICATION_NAME}" >> ./messenger_api/.env
echo "PGUSER=${DB_USER}" >> ./messenger_api/.env
echo "PGPASSWORD=${DB_PASS}" >> ./messenger_api/.env
echo "AWS_STORAGE_BUCKET_NAME=${CREATION_DATE}-${APPLICATION_NAME}-bucket" >> ./messenger_api/.env
echo "DB_HOST=${DB_LINK}" >> ./messenger_api/.env

