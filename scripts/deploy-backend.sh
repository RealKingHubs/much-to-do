#!/bin/bash

set -e

IMAGE_URI=$1
AWS_REGION="us-east-1"

INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $AWS_REGION \
  --filters "Name=tag:Name,Values=dev-backend" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

for INSTANCE_ID in $INSTANCE_IDS
do
  echo "Deploying to $INSTANCE_ID"

  aws ssm send-command \
    --region $AWS_REGION \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters commands="
      docker stop backend || true
      docker rm backend || true
      aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $IMAGE_URI
      docker pull $IMAGE_URI
      docker run -d --name backend -p 8080:8080 $IMAGE_URI
    "
done