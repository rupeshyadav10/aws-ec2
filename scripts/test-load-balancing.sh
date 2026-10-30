#!/usr/bin/env bash
# Sends requests to the load balancer and counts which instance answered.
# Usage: ./scripts/test-load-balancing.sh [region] [requests]
set -euo pipefail

REGION="${1:-ap-south-1}"
N="${2:-20}"

URL=$(aws cloudformation describe-stacks --region "$REGION" --stack-name ec2-ha-web \
  --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text)
echo "Sending $N requests to $URL"
echo ""
for i in $(seq 1 "$N"); do
  curl -s --max-time 5 "$URL/" | grep -o 'i-[0-9a-f]\{8,17\}' | head -n 1
done | sort | uniq -c | sort -rn
echo ""
echo "Each line is: <number of responses> <instance id>. Roughly even counts = load is balanced."
echo "Tip: stop Apache on one server (sudo systemctl stop httpd) and re-run to see failover."
