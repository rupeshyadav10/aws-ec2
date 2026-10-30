# Linux Commands Cheat Sheet (Amazon Linux 2023)

## Navigation & files
```bash
pwd                         # where am I
ls -la                      # list files with details
cd /var/www/html            # change directory
cat file.txt                # show a file
less file.txt               # scroll through a file (q to quit)
tail -f /var/log/httpd/access_log   # follow a log live (Ctrl+C to stop)
cp a.txt b.txt && mv b.txt c.txt && rm c.txt
mkdir demo && rmdir demo
nano file.txt               # simple editor (Ctrl+O save, Ctrl+X exit)
```

## Permissions & users
```bash
whoami
sudo <command>              # run as administrator
chmod 400 key.pem           # owner read-only
chmod 644 file              # owner rw, others r
chown ec2-user:ec2-user file
```

## Packages & services
```bash
sudo dnf update -y
sudo dnf install -y httpd
sudo systemctl status httpd
sudo systemctl start|stop|restart httpd
sudo systemctl enable httpd          # start on boot
journalctl -u httpd --no-pager | tail
```

## Networking & troubleshooting
```bash
curl -I http://localhost             # HTTP headers of local site
curl -s localhost/health.html
ss -tulpn | grep :80                 # who listens on port 80
ip addr                              # private IP
ping -c 3 8.8.8.8
```

## EC2 specifics
```bash
# Instance metadata (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id

sudo cat /var/log/user-data.log      # output of the bootstrap script
aws s3 ls s3://<bucket>/logs/ --recursive
df -h && free -m && uptime           # disk, memory, load
```
