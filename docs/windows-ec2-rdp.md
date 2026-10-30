# Windows EC2 Lab (Day 2 — Optional, Manual)

Windows instances cost more than Linux and take longer to boot, so this lab is manual and short. **Terminate the instance when finished.**

## Launch

1. EC2 → **Launch instance** → name `win-demo`.
2. AMI: **Microsoft Windows Server 2022 Base** (Quick Start).
3. Type: the free-tier-eligible or smallest type that meets Windows requirements (Windows needs more memory than Linux; very small types can be slow).
4. Key pair: `internship-key` (needed to decrypt the Administrator password).
5. Security group: create `win-sg` with **RDP 3389 from My IP only** — never `0.0.0.0/0`.
6. Launch and wait for *2/2 checks passed* (5–10 minutes).

## Connect with Remote Desktop (RDP)

1. Select the instance → **Connect → RDP client → Get password**.
2. Upload your `.pem` key → **Decrypt password** → copy it.
3. Windows: open **Remote Desktop Connection**; macOS: *Windows App / Microsoft Remote Desktop*.
4. Computer = the public IP; user = `Administrator`; password = the decrypted one. ✅ screenshot of the desktop.

## Optional: install a web server (IIS)

In PowerShell as Administrator:

```powershell
Install-WindowsFeature -name Web-Server -IncludeManagementTools
```

Add an inbound **HTTP 80** rule to `win-sg`, then browse to `http://<public-ip>`.

## Linux vs Windows on EC2

| | Linux | Windows |
|---|---|---|
| Remote access | SSH (port 22) | RDP (port 3389) |
| Login | Key pair file | Password decrypted with key pair |
| Web server | Apache / Nginx | IIS |
| Bootstrap | User Data shell script | User Data PowerShell (`<powershell>...</powershell>`) |
| Cost | Lower | Higher (includes Windows licence) |

## Clean up

**Terminate** the instance and delete `win-sg`.
