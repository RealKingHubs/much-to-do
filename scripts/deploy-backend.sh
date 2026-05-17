#!/bin/bash

IMAGE=$1

INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-backend*" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

aws ssm send-command \
  --instance-ids $INSTANCE_IDS \
  --document-name "AWS-RunShellScript" \
  --parameters commands="
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 093796422475.dkr.ecr.us-east-1.amazonaws.com

    docker pull $IMAGE

    docker stop backend || true
    docker rm backend || true

    docker run -d \
      --name backend \
      -p 8080:8080 \
      -e PORT=8080 \
      -e MONGO_URI='YOUR_MONGO_URI' \
      -e DB_NAME='much_todo_db' \
      -e JWT_SECRET_KEY='YOUR_SECRET' \
      $IMAGE
  " \
  --region us-east-1