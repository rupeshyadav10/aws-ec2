# Learning Map — Day 1 to Day 6

How each training topic is used in this project, and the exact lab to practise it.

## Day 1 — AWS, Linux, EC2, S3

| Concept | In this project | Try it |
|---|---|---|
| Regions & Availability Zones | Servers placed in two AZs of `ap-south-1` | Console guide, Lab 1 |
| EC2 basics | 2 web servers + 1 admin server | Console guide, Lab 3 |
| Linux basics | Everything runs on Amazon Linux 2023 | [Linux cheat sheet](linux-commands-cheatsheet.md) |
| S3 | Private bucket receives Apache logs | Console guide, Lab 8 |
| IAM role | Server uploads to S3 without keys | `WebInstanceRole` in the template |

## Day 2 — EC2 practical, Windows & Linux, AMI

| Concept | In this project | Try it |
|---|---|---|
| Launch Linux vs Windows | Linux via template; Windows as a manual lab | [Windows RDP guide](windows-ec2-rdp.md) |
| AMI | Golden image of web server 1 → new server | `scripts/create-ami-and-scale.sh` |
| Instance types | `InstanceType` parameter | Change it in `deploy.sh` parameters |

## Day 3 — EC2 Linux launch & deploy, SSH with PuTTY, key pair, security groups

| Concept | In this project | Try it |
|---|---|---|
| Key pair | `KeyName` parameter, used for SSH | Console guide, Lab 2 |
| SSH / PuTTY | Connect to the admin Elastic IP | [PuTTY guide](putty-ssh-guide.md) |
| Security groups | `AlbSecurityGroup`, `WebSecurityGroup`, `AdminSecurityGroup` | Console guide, Lab 2 |

## Day 4 — EC2 web server: Apache + bootstrap script

| Concept | In this project | Try it |
|---|---|---|
| Install Apache | `dnf install -y httpd` in User Data | `scripts/bootstrap-userdata.sh` |
| Bootstrap / User Data | Runs once at first boot | `cat /var/log/user-data.log` on a server |
| Instance metadata | Page shows instance ID, AZ, IP (IMDSv2) | `curl` the metadata service from SSH |

## Day 5 — Elastic IP (public IP vs static IP)

| Concept | In this project | Try it |
|---|---|---|
| Public IP changes on stop/start | Web servers use normal public IPs | Stop/start a web server and compare its IP |
| Elastic IP stays | `AdminElasticIp` attached to admin server | Stop/start the admin server: IP unchanged |

## Day 6 — Load balancer, ELB, health checks

| Concept | In this project | Try it |
|---|---|---|
| Distribute traffic | Application Load Balancer + listener on port 80 | `scripts/test-load-balancing.sh` |
| Health checks | Target group checks `/health.html` every 15 s | Stop Apache on one server and watch it go unhealthy |
| Fault tolerance | Traffic continues on the healthy server | Refresh the site during the failure |

> **Classic vs Application Load Balancer:** your training uses the *Classic Load Balancer*. It still works, but AWS recommends the Application Load Balancer (ALB) for HTTP/HTTPS, so the code uses an ALB. The ideas (listener, health check, registered instances, DNS name) are identical, and the console guide shows both.
