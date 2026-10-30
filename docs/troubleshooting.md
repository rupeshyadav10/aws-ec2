# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Browser can't open the load balancer URL right after deploy | Servers still bootstrapping (~2 min) or targets not yet healthy | Wait; check EC2 → Target Groups → Targets |
| Targets **unhealthy** | Apache not running, `/health.html` missing, or web-sg doesn't allow the ALB | SSH in: `sudo systemctl status httpd`, `curl localhost/health.html`; confirm web-sg port 80 source = alb-sg |
| `503 Service Temporarily Unavailable` | No healthy targets | Fix the unhealthy targets above |
| `502 Bad Gateway` | Server closed the connection / crashed | Check `/var/log/httpd/error_log` |
| Page opens on public IP but not through ALB | ALB subnets/AZs differ from instances' AZs, or targets not registered | Enable the ALB in the same AZs as the instances; check registration |
| SSH timeout | Your IP changed or SSH rule missing | Security group → SSH → *My IP* |
| `Permission denied (publickey)` | Wrong key/username | Use `ec2-user` and the launch key pair |
| Apache not installed / page missing | User Data failed | `sudo cat /var/log/user-data.log`; User Data runs **only at first boot** — terminate and relaunch, or run the commands manually |
| User Data change has no effect | Edited on an already-launched instance | Relaunch, or run the script manually with `sudo bash` |
| **AMI shows old instance id** | The page was generated at boot of the *source* server and baked into the image | Expected. Real fix: generate the page at every boot (systemd service/`@reboot`) or serve it from a script |
| `aws s3 cp` AccessDenied on server | IAM role missing or policy scoped to another bucket/prefix | Check the instance's role; upload path must start with `logs/` |
| `cloudformation deploy` fails: key pair not found | Key pair is in another region | Create it in the same region you deploy to |
| `cloudformation deploy` fails on subnets | Fewer than 2 default subnets | Create a default VPC or pass your own subnet IDs |
| Stack delete fails: bucket not empty | Logs inside the bucket | `./scripts/cleanup.sh` empties it first |
| Still being billed after cleanup | Elastic IP not released, extra AMI/snapshots, instances in other regions | Check EC2 → Elastic IPs, AMIs, Snapshots, and the Billing dashboard |
