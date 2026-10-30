# Interview Prep — Questions About This Project

**1. What is EC2?**
Virtual servers in the cloud. You choose the OS (AMI), size (instance type), network and storage, and pay while it runs.

**2. What is an AMI and why create one?**
A template (OS + software + settings) used to launch instances. A custom "golden" AMI lets you launch identical, already-configured servers fast — the basis for scaling.

**3. What is a key pair?**
A public/private key pair. AWS stores the public key on the instance; you keep the private key (`.pem`/`.ppk`) to log in over SSH, or to decrypt a Windows password.

**4. What is a security group? Stateful or stateless?**
A virtual firewall attached to instances with allow-rules only. It is **stateful**: return traffic is automatically allowed. (Network ACLs are stateless.)

**5. Why does `web-sg` allow port 80 from `alb-sg` instead of `0.0.0.0/0`?**
Users can only reach servers through the load balancer; direct access is blocked. It also stays correct when the ALB's IP addresses change.

**6. What is User Data?**
A script that runs once, as root, at first boot. Here it installs Apache, writes the web page and sets up the S3 backup — so every server configures itself identically.

**7. Public IP vs Elastic IP?**
A normal public IP is released when the instance stops and a new one is assigned on start. An Elastic IP is a static address owned by your account until you release it. Unattached or extra public IPv4 addresses are billed.

**8. How does a load balancer decide where to send traffic?**
It forwards each request to a healthy registered target (ALB: round-robin by default). Health checks remove failing targets and add them back when they recover.

**9. Classic Load Balancer vs Application Load Balancer?**
Classic is the legacy generation (basic Layer 4/7). ALB is the current choice for HTTP/HTTPS: path/host routing, target groups, better metrics.

**10. How does the project survive one server failing?**
Servers sit in different AZs behind the load balancer. When health checks fail for one, traffic goes only to the other.

**11. Why use an IAM role for S3 instead of access keys?**
Roles provide temporary credentials delivered via the metadata service. Nothing secret is stored on the server, and permissions are limited to `s3:PutObject` on `logs/*`.

**12. What is IMDSv2 and why enforce it?**
A session-token based version of the instance metadata service. It protects against SSRF attacks stealing role credentials.

**13. What is the weakness of this design and how would you improve it?**
Fixed instance count and servers in public subnets. Improve with an Auto Scaling Group, private subnets + NAT/bastion, HTTPS with ACM and Route 53.

**14. A server shows "unhealthy" — how do you debug?**
Check the target group's health status reason, SSH in, verify `systemctl status httpd` and `curl localhost/health.html`, then confirm the security group allows the ALB.

**15. Why infrastructure as code?**
Repeatable, reviewable in Git, easy to delete completely, and avoids manual mistakes.
