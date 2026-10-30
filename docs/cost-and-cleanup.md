# Cost & Cleanup

## What costs money in this project

| Resource | Billed while it exists? | Notes |
|---|---|---|
| EC2 instances (3, plus the optional AMI server and Windows lab) | Yes, per second while running | Stopped instances don't pay for compute, but still pay for their disks |
| Application Load Balancer | Yes, hourly + usage | Usually the biggest surprise on a small project |
| Public IPv4 addresses, **including Elastic IPs** | Yes, hourly | Every public IPv4 address is billed; an unattached Elastic IP is billed too |
| EBS volumes & AMI snapshots | Yes, per GB-month | Delete snapshots when you deregister AMIs |
| S3 | Pay per GB and request | Tiny here; logs expire after 30 days |
| CloudWatch alarm | Small fixed amount | |
| Data transfer out | Pay per GB | Negligible for a demo |

> Prices and free-tier terms change and depend on when your account was created. Check the [AWS pricing pages](https://aws.amazon.com/pricing/) and **Billing → Free Tier** for current numbers. Don't rely on this table for amounts.

## Protect yourself

1. Create a **budget alert** before deploying.
2. Deploy, demo, **clean up the same day**.
3. Never commit `.pem` / `.ppk` files or credentials (`.gitignore` blocks them).
4. Security group SSH = **your IP only**.

## Cleanup

Automated (stack, extra servers, AMIs, snapshots, bucket contents):

```bash
./scripts/cleanup.sh ap-south-1
```

Then verify in the console, **in every region you used**:

- [ ] EC2 → Instances: none running
- [ ] EC2 → Elastic IPs: none allocated
- [ ] EC2 → Load Balancers & Target Groups: none
- [ ] EC2 → AMIs and Snapshots: none you created
- [ ] S3: bucket gone
- [ ] Billing → Bills: check again next day

If you built it by hand, delete in this order: Load balancer → Target group → Instances → Elastic IP (release) → AMI + Snapshots → S3 bucket → IAM role → Security groups → Key pair.
