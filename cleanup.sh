#!/bin/bash
set -eo pipefail
STACK=java-events
REGION=us-east-1
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
else
     echo "Not enough arguments supplied"
     echo "Usage: cleanup.sh <Stack name>"
     exit 1
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id ProcessMSKfunction --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."
if [ -f /tmp/bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat /tmp/bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm /tmp/bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi
while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done