#!/bin/bash
# EC2 bootstrap script (User Data) - Apache web server + hourly log backup to S3
# Author: Rupesh Kumar Yadav
#
# Runs once as root on first boot of an Amazon Linux 2023 instance.
#   * CloudFormation: infrastructure/build_template.py injects this file into the
#     template and replaces __BUCKET__ with the real S3 bucket automatically.
#   * Console labs (Day 4): paste this into "Advanced details > User data" and
#     replace __BUCKET__ with your bucket name (or leave it - the backup step is skipped).
#
# NOTE: only plain $VAR style variables are used (never the curly-brace form) so the
# script can live inside a CloudFormation Fn::Sub block without escaping.
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

BUCKET="__BUCKET__"

# ---- 1. Install and start Apache (httpd) + cron ------------------------------
dnf update -y
dnf install -y httpd cronie
systemctl enable --now httpd
systemctl enable --now crond

# ---- 2. Read instance details from the metadata service (IMDSv2) --------------
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
meta() { curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }
INSTANCE_ID=$(meta instance-id)
AZ=$(meta placement/availability-zone)
PRIVATE_IP=$(meta local-ipv4)
INSTANCE_TYPE=$(meta instance-type)
# A colour derived from the instance id, so each server looks different in the browser
HUE=$(( $(echo -n "$INSTANCE_ID" | cksum | cut -d' ' -f1) % 360 ))

# ---- 3. Health-check page (used by the load balancer) and the web page --------
echo "OK" > /var/www/html/health.html

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>EC2 High Availability Demo</title>
  <style>
    body { margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center;
           font-family:system-ui,Segoe UI,Arial,sans-serif; color:#fff;
           background:linear-gradient(135deg, hsl($HUE,70%,32%), hsl($HUE,60%,18%)); }
    .card { background:rgba(255,255,255,.12); padding:2.2rem 2.8rem; border-radius:16px; max-width:560px; }
    h1 { margin:0 0 .3rem; font-size:1.7rem; }
    .sub { opacity:.85; margin-bottom:1.4rem; }
    .id { font-size:2rem; font-weight:700; color:#ffb84d; word-break:break-all; }
    table { margin-top:1rem; border-collapse:collapse; width:100%; }
    td { padding:.35rem 0; border-bottom:1px solid rgba(255,255,255,.2); }
    td:first-child { opacity:.75; width:45%; }
    footer { margin-top:1.4rem; font-size:.85rem; opacity:.8; }
  </style>
</head>
<body>
  <div class="card">
    <h1>AWS EC2 High Availability Demo</h1>
    <div class="sub">Apache web server bootstrapped with EC2 User Data</div>
    <div>This page was served by instance</div>
    <div class="id">$INSTANCE_ID</div>
    <table>
      <tr><td>Availability Zone</td><td>$AZ</td></tr>
      <tr><td>Private IP</td><td>$PRIVATE_IP</td></tr>
      <tr><td>Instance type</td><td>$INSTANCE_TYPE</td></tr>
      <tr><td>Web server</td><td>Apache httpd on Amazon Linux 2023</td></tr>
    </table>
    <footer>Refresh the page: the load balancer may send you to another server.<br>
    Built by Rupesh Kumar Yadav - AWS Cloud Computing Internship Project</footer>
  </div>
</body>
</html>
EOF

# ---- 4. Hourly backup of Apache access logs to S3 (uses the instance IAM role) -
echo "BUCKET=$BUCKET" > /etc/web-backup.conf

cat > /usr/local/bin/backup-logs.sh <<'SCRIPT'
#!/bin/bash
# Copies the Apache access log to S3. Triggered hourly by /etc/cron.d/backup-logs
set -euo pipefail
source /etc/web-backup.conf
if [ -z "$BUCKET" ] || [ "$BUCKET" = "__BUCKET__" ]; then
  echo "No bucket configured - skipping backup"; exit 0
fi
[ -f /var/log/httpd/access_log ] || exit 0
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
aws s3 cp /var/log/httpd/access_log "s3://$BUCKET/logs/$ID/access-$(date +%Y%m%d-%H%M).log"
SCRIPT
chmod +x /usr/local/bin/backup-logs.sh

echo "0 * * * * root /usr/local/bin/backup-logs.sh >> /var/log/backup-logs.log 2>&1" > /etc/cron.d/backup-logs
chmod 644 /etc/cron.d/backup-logs

echo "Bootstrap finished for $INSTANCE_ID"
