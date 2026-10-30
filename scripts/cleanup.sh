#!/usr/bin/env bash
# Delete EVERYTHING this project created so you are not billed.
# Usage: ./scripts/cleanup.sh [region]
set -euo pipefail

REGION="${1:-ap-south-1}"
STACK="ec2-ha-web"

echo ">> Terminating extra servers launched from the custom AMI (if any)"
IDS=$(aws ec2 describe-instances --region "$REGION" \
  --filters Name=tag:Project,Values=ec2-ha-web Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query "Reservations[].Instances[].InstanceId" --output text)
if [ -n "$IDS" ]; then
  aws elbv2 deregister-targets --region "$REGION" \
    --target-group-arn "$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
      --query "Stacks[0].Outputs[?OutputKey=='TargetGroupArn'].OutputValue" --output text)" \
    --targets $(for i in $IDS; do printf 'Id=%s ' "$i"; done) || true
  aws ec2 terminate-instances --region "$REGION" --instance-ids $IDS >/dev/null
  aws ec2 wait instance-terminated --region "$REGION" --instance-ids $IDS
fi

echo ">> Deregistering custom AMIs and deleting their snapshots (if any)"
for AMI in $(aws ec2 describe-images --region "$REGION" --owners self \
    --filters Name=tag:Project,Values=ec2-ha-web --query "Images[].ImageId" --output text); do
  SNAPS=$(aws ec2 describe-images --region "$REGION" --image-ids "$AMI" \
    --query "Images[0].BlockDeviceMappings[].Ebs.SnapshotId" --output text)
  aws ec2 deregister-image --region "$REGION" --image-id "$AMI"
  for S in $SNAPS; do aws ec2 delete-snapshot --region "$REGION" --snapshot-id "$S"; done
done

echo ">> Emptying the S3 bucket"
BUCKET=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='BackupBucketName'].OutputValue" --output text)
aws s3 rm "s3://$BUCKET" --recursive --region "$REGION" || true

echo ">> Deleting the CloudFormation stack (servers, load balancer, Elastic IP, ...)"
aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --region "$REGION" --stack-name "$STACK"
echo "Everything deleted. Your key pair is NOT deleted (delete it in EC2 > Key Pairs if you want)."
