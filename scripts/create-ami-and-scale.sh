#!/usr/bin/env bash
# Day 2 lab as code: create a custom AMI from a running web server, launch a NEW
# server from that AMI, and register it with the load balancer ("scale out").
# Usage: ./scripts/create-ami-and-scale.sh [region]
set -euo pipefail

REGION="${1:-ap-south-1}"
STACK="ec2-ha-web"
cd "$(dirname "$0")/.."

out() {
  aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}
param() {
  aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
    --query "Stacks[0].Parameters[?ParameterKey=='$1'].ParameterValue" --output text
}

SOURCE_ID=$(out WebServer1Id)
TG_ARN=$(out TargetGroupArn)
SG_ID=$(out WebSecurityGroupId)
PROFILE=$(out InstanceProfileName)
KEY_NAME=$(param KeyName)
INSTANCE_TYPE=$(param InstanceType)
# put the new server in the 2nd subnet (a different AZ from server 1 when possible)
SUBNET=$(param SubnetIds | tr ',' '\n' | sed -n '2p')

STAMP=$(date +%Y%m%d-%H%M)
echo ">> Creating AMI from $SOURCE_ID (no reboot)"
AMI_ID=$(aws ec2 create-image --region "$REGION" --instance-id "$SOURCE_ID" \
  --name "ec2-ha-web-golden-$STAMP" --description "Golden image of the Apache web server" \
  --no-reboot \
  --tag-specifications "ResourceType=image,Tags=[{Key=Project,Value=ec2-ha-web}]" \
  --query ImageId --output text)
echo "   AMI: $AMI_ID - waiting until it is available (a few minutes)"
aws ec2 wait image-available --region "$REGION" --image-ids "$AMI_ID"

echo ">> Launching a new server from the AMI"
NEW_ID=$(aws ec2 run-instances --region "$REGION" --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" \
  --subnet-id "$SUBNET" --security-group-ids "$SG_ID" \
  --iam-instance-profile Name="$PROFILE" \
  --metadata-options HttpTokens=required \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ec2-ha-web-ami-server},{Key=Project,Value=ec2-ha-web}]" \
  --query "Instances[0].InstanceId" --output text)
aws ec2 wait instance-running --region "$REGION" --instance-ids "$NEW_ID"

echo ">> Registering $NEW_ID with the target group"
aws elbv2 register-targets --region "$REGION" --target-group-arn "$TG_ARN" --targets Id="$NEW_ID"

echo ""
echo "Done. New server: $NEW_ID (from $AMI_ID)."
echo "Watch it become healthy in EC2 > Target Groups, then run ./scripts/test-load-balancing.sh"
echo "Note: the page on this server shows the SOURCE server's id (it was baked into the AMI)."
echo "      That is a great talking point - see docs/troubleshooting.md ('AMI shows old instance id')."
