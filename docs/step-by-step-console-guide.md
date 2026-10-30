# Step-by-Step Console Guide (Build It by Hand)

Learn each service by clicking through the console. Prefer automation? Use `scripts/deploy.sh`.
Use region **Asia Pacific (Mumbai) `ap-south-1`**. Take a screenshot at every ✅ (file names are in `screenshots/README.md`).

> ⚠️ Delete everything when finished (see `cost-and-cleanup.md`). Load balancers and public IPs are billed while they exist.

---

## Lab 0 — Account safety (Day 1)

1. Enable **MFA** on the root user; create an IAM user for daily work.
2. **Billing → Budgets → Create budget** with an email alert.

## Lab 1 — Explore regions & AZs (Day 1)

1. Top-right region selector → choose **Mumbai (ap-south-1)**.
2. EC2 → **Dashboard** and note the Availability Zones (`ap-south-1a`, `1b`, `1c`).

## Lab 2 — Key pair and security groups (Day 3)

**Key pair**
1. EC2 → **Key Pairs → Create key pair** → name `internship-key` → type RSA → format **.pem** (OpenSSH/Linux/Mac) or **.ppk** (PuTTY on Windows) → Create. The file downloads **once** - keep it safe. ✅ screenshot of the key pair list.

**Security groups** (EC2 → Security Groups → Create)
1. `alb-sg`: inbound **HTTP 80** from `0.0.0.0/0`.
2. `web-sg`: inbound **HTTP 80** with source = **alb-sg** (choose the group, not an IP), and **SSH 22** from **My IP**.
3. `admin-sg`: inbound **SSH 22** from **My IP**. ✅ screenshot of web-sg inbound rules.

## Lab 3 — Launch a Linux EC2 instance (Days 1-3)

1. EC2 → **Launch instance** → Name `web-1`.
2. AMI: **Amazon Linux 2023**. Type: **t3.micro** (or free-tier-eligible type shown).
3. Key pair: `internship-key`. Network: default VPC, **subnet in ap-south-1a**, auto-assign public IP **Enable**. Security group: `web-sg`.
4. Don't launch yet — continue to Lab 4 to add User Data.

## Lab 4 — Bootstrap Apache with User Data (Day 4)

1. In the launch wizard open **Advanced details → User data**.
2. Paste the contents of `scripts/bootstrap-userdata.sh` (leave `__BUCKET__` as is for now; the backup step then skips itself).
3. **Launch**. Wait for *2/2 checks passed*. ✅ screenshot of running instances.
4. Open `http://<public-ip>` — you should see the demo page. If not, see `troubleshooting.md`.
5. Repeat for `web-2` in **ap-south-1b**.

## Lab 5 — Connect with SSH / PuTTY (Day 3)

Follow `putty-ssh-guide.md`. Then run:

```bash
sudo systemctl status httpd      # ✅ screenshot: "active (running)"
cat /var/log/user-data.log | tail
curl -s localhost/health.html    # OK
```

## Lab 6 — Elastic IP (Day 5)

1. Launch a third small instance `admin` with `admin-sg`.
2. Note its **public IP**, then **Stop** and **Start** it — the public IP **changes**.
3. EC2 → **Elastic IPs → Allocate Elastic IP address → Allocate**.
4. Select it → **Actions → Associate Elastic IP address** → instance `admin`.
5. Stop/Start again — the IP **stays the same**. ✅ screenshot of the Elastic IP page.
6. Remember: **release** the Elastic IP when done.

## Lab 7 — Create an AMI (Day 2)

1. Select `web-1` → **Actions → Image and templates → Create image** → name `web-golden-image`.
2. EC2 → **AMIs**, wait for status **Available**. ✅ screenshot.
3. Launch a new instance from **My AMIs** (`web-3`, `web-sg`). It boots with Apache already installed — no User Data needed.

## Lab 8 — S3 bucket + IAM role (Day 1)

1. S3 → Create bucket (unique name, **Block all public access ON**).
2. IAM → Roles → Create role → trusted entity **EC2** → create inline policy allowing `s3:PutObject` on `arn:aws:s3:::<bucket>/logs/*` → name `web-s3-logs-role`.
3. EC2 → select `web-1` → **Actions → Security → Modify IAM role** → attach it.
4. SSH in and test: `echo hello > t.txt && aws s3 cp t.txt s3://<bucket>/logs/t.txt` ✅ screenshot of the object in S3.

## Lab 9 — Load balancer & health checks (Day 6)

### Option A: Application Load Balancer (used by the code)

1. EC2 → **Target Groups → Create** → type *Instances*, HTTP 80, **health check path `/health.html`**, interval 15 s, healthy 2, unhealthy 2 → register `web-1` and `web-2`.
2. EC2 → **Load Balancers → Create → Application Load Balancer** → internet-facing, select **2 AZs**, security group `alb-sg`, listener HTTP 80 → forward to the target group.
3. Wait until the targets show **healthy**. ✅ screenshot of the target group.
4. Open the **DNS name** in the browser and refresh — the instance ID/colour changes. ✅ screenshot.

### Option B: Classic Load Balancer (as in the course)

1. Load Balancers → Create → **Classic Load Balancer** → listener HTTP 80 → instance HTTP 80.
2. Health check: protocol HTTP, path `/health.html`, interval 15, healthy 2, unhealthy 2.
3. Add instances `web-1`, `web-2` and security group `alb-sg`.
4. Open the DNS name and refresh. (Classic LB is a legacy product — prefer ALB for new projects.)

### Test failover

```bash
sudo systemctl stop httpd     # on web-1
```
Wait ~30 s: web-1 turns **unhealthy** and every refresh now shows web-2. Start it again with `sudo systemctl start httpd`.

## Lab 10 — Windows instance (Day 2, optional)

See `windows-ec2-rdp.md`.

## Lab 11 — Clean up

Order: Load balancer → Target group → Instances (terminate) → Elastic IP (**release**) → AMI (deregister) + snapshots (delete) → S3 bucket (empty then delete) → IAM role → security groups → key pair (optional).
