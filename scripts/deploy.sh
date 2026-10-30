#!/usr/bin/env bash
# Deploy the whole stack with one command.
# Usage: ./scripts/deploy.sh <key-pair-name> [region] [admin-cidr]
#   key-pair-name : an EXISTING EC2 key pair in that region (create it first - see docs)
#   region        : default ap-south-1 (Mumbai)
#   admin-cidr    : default = your current public IP /32 (only this IP may SSH in)
set -euo pipefail

KEY_NAME="${1:?Usage: ./scripts/deploy.sh <key-pair-name> [region] [admin-cidr]}"
REGION="${2:-ap-south-1}"
STACK="ec2-ha-web"
cd "$(dirname "$0")/.."

ADMIN_CIDR="${3:-}"
if [ -z "$ADMIN_CIDR" ]; then
  MY_IP=$(curl -s --max-time 5 https://checkip.amazonaws.com | tr -d '[:space:]' || true)
  [ -n "$MY_IP" ] || { echo "Could not detect your IP. Pass it as the 3rd argument, e.g. 203.0.113.10/32"; exit 1; }
  ADMIN_CIDR="$MY_IP/32"
fi
echo ">> SSH will be allowed only from $ADMIN_CIDR"

echo ">> Generating template from base + bootstrap script"
python3 infrastructure/build_template.py

echo ">> Looking up the default VPC and subnets in $REGION"
VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" --output text)
[ "$VPC_ID" != "None" ] || { echo "No default VPC found in $REGION. Create one or pass your own IDs."; exit 1; }
SUBNETS=$(aws ec2 describe-subnets --region "$REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" Name=default-for-az,Values=true \
  --query "Subnets[].SubnetId" --output text | tr '\t' ',')
[ "$(echo "$SUBNETS" | tr ',' '\n' | wc -l)" -ge 2 ] || { echo "Need at least 2 subnets in different AZs."; exit 1; }

echo ">> Deploying stack '$STACK' (takes ~4-6 minutes)"
aws cloudformation deploy \
  --region "$REGION" \
  --stack-name "$STACK" \
  --template-file infrastructure/template.yaml \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
      KeyName="$KEY_NAME" VpcId="$VPC_ID" SubnetIds="$SUBNETS" AdminCidr="$ADMIN_CIDR"

echo ""
aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
echo ""
echo "Wait ~2 minutes for the servers to finish bootstrapping and pass health checks,"
echo "then open the WebsiteUrl above and refresh several times."
