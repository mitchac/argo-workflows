echo $1
echo $2
STACK_NAME=$(eksctl get nodegroup --region us-east-2 --cluster $1 -o json | jq -r --arg nodegroup $2 '.[]|select(.Name==$nodegroup) | .StackName')
echo $STACK_NAME
ROLE_NAME=$(aws cloudformation describe-stack-resources --region us-east-2 --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')
aws iam put-role-policy --role-name $ROLE_NAME --policy-name S3-Policy-For-Worker --policy-document file://k8s-s3-policy.json
aws iam get-role-policy --role-name $ROLE_NAME --policy-name S3-Policy-For-Worker

