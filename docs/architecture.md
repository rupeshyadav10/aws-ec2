# Architecture

![Architecture](../screenshots/architecture.png)

## Traffic flow

1. A visitor opens the **load balancer DNS name** (`WebsiteUrl`).
2. The **ALB** accepts HTTP on port 80 and forwards to a **healthy** web server in the target group.
3. The web server (**Apache on EC2**) returns the page showing its own instance ID and AZ.
4. Every 15 seconds the ALB requests `/health.html`; two failures mark a server unhealthy and traffic stops going to it.
5. Every hour a cron job on each server uploads the Apache access log to **S3** using its **IAM role**.
6. The administrator connects over **SSH** to the **Elastic IP** of the admin server (only from their own IP).

## Security groups

| Group | Inbound | Why |
|---|---|---|
| `alb-sg` | TCP 80 from `0.0.0.0/0` | Public entry point |
| `web-sg` | TCP 80 from **alb-sg** · TCP 22 from your IP | Servers cannot be reached directly over HTTP |
| `admin-sg` | TCP 22 from your IP | Management access |

Security groups are **stateful**: reply traffic is allowed automatically, so only inbound rules are needed.

## Design decisions

| Decision | Reason |
|---|---|
| Two instances in two AZs | Survive the failure of one AZ or one server |
| User Data bootstrap | Servers configure themselves; no manual SSH setup, identical every time |
| Launch template | One definition shared by both web servers (and a base for Auto Scaling later) |
| Health check on a static file | Cheap, fast, independent of the page content |
| Elastic IP on the admin server only | Fixed address where it matters; web traffic uses the load balancer's DNS name |
| ALB instead of Classic LB | Current AWS recommendation for HTTP; same concepts as the course |
| IAM role instead of access keys | Credentials are temporary and never stored on disk |
| Instances in default-VPC public subnets | Beginner-friendly. Production would use private subnets (see Future Improvements) |
| `deploy.sh` builds the template | Bootstrap script stays the single source of truth |

## Resource list (created by the template)

S3 bucket · 3 security groups · IAM role + instance profile · launch template · 2 web EC2 instances · 1 admin EC2 instance · Elastic IP + association · Application Load Balancer · target group · listener · CloudWatch alarm.
