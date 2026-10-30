# Connecting to EC2 over SSH (Windows PuTTY, Mac/Linux, Session Manager)

## Option 1 — PuTTY on Windows

1. Install **PuTTY** (includes PuTTYgen).
2. If you downloaded a `.pem` key, convert it: open **PuTTYgen → Load** (show *All files*) → select the `.pem` → **Save private key** → `internship-key.ppk`. (Or download the key as `.ppk` directly when creating the key pair.)
3. Open **PuTTY**:
   - **Host Name:** `ec2-user@<public-ip-or-elastic-ip>`
   - **Connection → SSH → Auth → Credentials → Private key file:** browse to the `.ppk`
   - (Optional) Session → name it and **Save**
4. Click **Open** → accept the host key prompt. You should see the Amazon Linux banner. ✅ screenshot.

Default usernames: Amazon Linux = `ec2-user`, Ubuntu = `ubuntu`, Windows = RDP (no SSH).

## Option 2 — Windows 10/11 PowerShell, macOS, Linux

```bash
chmod 400 internship-key.pem            # (macOS/Linux) key must not be world-readable
ssh -i internship-key.pem ec2-user@<public-ip>
```

On Windows PowerShell, restrict the key file to your user (right-click → Properties → Security) or use PuTTY instead.

## Option 3 — Session Manager (no SSH port, no key)

The web servers have the `AmazonSSMManagedInstanceCore` policy. In the console: EC2 → select instance → **Connect → Session Manager → Connect**.

## Common problems

| Message | Cause | Fix |
|---|---|---|
| `Connection timed out` | Security group has no SSH rule for **your current IP** (home IPs change) | Edit the rule → *My IP* |
| `Permission denied (publickey)` | Wrong key or wrong username | Use the key pair chosen at launch and `ec2-user` |
| `UNPROTECTED PRIVATE KEY FILE` | `.pem` permissions too open | `chmod 400 key.pem` |
| PuTTY "No supported authentication methods" | Key not loaded or wrong user name | Set Auth → private key `.ppk`; user `ec2-user` |
| Works, then stops after stop/start | Public IP changed | Use the Elastic IP or the new public IP |
