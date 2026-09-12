# Beginner walkthrough: Mac → GitHub → three EC2 instances

Prepared 10 September 2026. AWS Console labels can change; the network settings and verification checks below are the target. Use one AWS account and one region throughout.

## 1. Your first step: open the app project on your Mac

The app has already been created. Do not type the application source from scratch.

1. Open **Terminal** on your Mac: press **Command + Space**, type **Terminal**, press Return.
2. Open this project's folder. On the Mac where this project was created, run:

```bash
cd /Users/sameer/Documents/Codex/2026-09-10/ok/outputs/netsol-three-tier-lab
```

If you downloaded and extracted the ZIP elsewhere, type `cd ` (including a space), drag the extracted `netsol-three-tier-lab` folder from Finder into Terminal, and press Return. Run `pwd` to see your current folder. The project root is the folder containing `README.md`, `frontend`, `backend`, and `deploy`.

3. Check the tools:

```bash
node --version
npm --version
git --version
```

Use **Node.js 24 LTS**, or a compatible Node version at least 22.12. Download the macOS Apple Silicon/ARM64 installer from the [official Node.js download page](https://nodejs.org/en/download). If Git is unavailable, run `xcode-select --install` and complete Apple's Command Line Tools installation. Close and reopen Terminal after installing tools, then return to the project root.

Your M4 Mac can manage x86_64 Ubuntu EC2 servers through SSH. The Mac and EC2 CPU architectures do **not** need to match. We will build browser JavaScript on the Mac; we will install Python packages on the Linux backend itself.

4. Install and build the React app:

```bash
npm ci --prefix frontend
npm run build --prefix frontend
```

Expected: a successful build and a `frontend/dist` folder. Keep `package-lock.json`; it makes installations repeatable. Do not copy your Mac's Python virtual environment or `node_modules` to EC2.

5. See the interface:

```bash
npm run dev --prefix frontend
```

Open the local URL printed by the command, usually **http://127.0.0.1:5173**. Keep this Terminal running. Press **Control + C** when finished.

This command previews the React interface. Insert and Retrieve become functional when a backend is available. For a full local test, use section 2; you may also proceed directly to the AWS deployment after checking the interface.

## 2. Optional: run the complete application locally

This rehearsal is useful before AWS, but it does not replace the three EC2 instances required by the assignment.

Use your team's approved Docker installation. If using Docker Desktop, choose the **Mac with Apple silicon** download and check that your team's license permits its use. Start Docker Desktop and wait until the engine is ready. [Docker's Mac installation instructions](https://docs.docker.com/desktop/setup/install/mac-install/).

From the project root on your **Mac**:

```bash
cp .env.example .env
openssl rand -hex 32
openssl rand -hex 32
nano .env
```

Replace `LOCAL_ADMIN_PASSWORD` and `LOCAL_APP_PASSWORD` with the two different generated values. In nano, save with **Control + O**, press Return, and exit with **Control + X**. `.env` is ignored by Git. Do not photograph it.

```bash
docker compose up --build -d
docker compose ps
```

Wait for the backend and database to report healthy. Open **http://localhost:8080**. Type `My first DevOps lab`, select **Insert**, then **Retrieve**. Refresh the page and select Retrieve again; the record should still exist.

To inspect an issue:

```bash
docker compose logs --tail=60 backend database frontend
```

To stop local practice while preserving notes:

```bash
docker compose down
```

The named PostgreSQL volume holds the data. Changing `.env` after the first database initialization does not change the stored database password. Keep the original values, or deliberately reset the disposable rehearsal with `docker compose down -v`; that command **deletes all local rehearsal notes**. It does not touch AWS.

**Screenshot checkpoint:** an optional local screenshot is useful progress evidence. Label it “local rehearsal,” not “AWS deployment.”

## 3. Put the project on GitHub

Choose a repository name such as **netsol-three-tier-lab**. A private repository is fine; give your team lead access. If NETSOL requires its own organization or repository, use that destination.

### Beginner route: GitHub Desktop

1. Install [GitHub Desktop](https://desktop.github.com/) and sign in to your GitHub account.
2. From the project root in Mac Terminal, run `git init -b main`.
3. In GitHub Desktop choose **File → Add Local Repository** and select this project folder.
4. Review the changed files. Source, scripts, documentation, `.env.example`, and `package-lock.json` should be present. `.env`, `.pem` keys, `node_modules`, `dist`, and passwords must not appear.
5. Enter the commit summary **Build React, Python and PostgreSQL lab** and choose **Commit to main**.
6. Choose **Publish repository**, name it `netsol-three-tier-lab`, select the correct account/organization, and keep it private unless your team wants public source.
7. On GitHub, open the repository and confirm you can see the README, frontend, backend, database and deploy folders. For a private repository, use **Settings → Collaborators** to add your team lead as appropriate.

These steps follow GitHub's workflow for [adding locally hosted code](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github). GitHub stores your source; the live application in this lab is hosted on EC2, not GitHub Pages.

### Terminal alternative, if you already use Git

Create an **empty** repository on GitHub first, without initializing a README or `.gitignore`. Run from your project root and replace `YOUR_USERNAME`:

```bash
git init -b main
git add .
git status
git commit -m "Build React, Python and PostgreSQL lab"
git remote add origin https://github.com/YOUR_USERNAME/netsol-three-tier-lab.git
git push -u origin main
```

If Git asks for your name/email, configure your own identity locally for this repository. GitHub's normal account password does not authenticate Git pushes; use GitHub Desktop or an approved Git credential method. Never paste a token into your repository or remote URL.

Choose either publishing route, not both. If a repository/remote already exists, use it instead of repeating initialization.

**Screenshot 01:** GitHub repository page showing the project folders and README. Save its URL for your final submission.

## 4. Create/check your AWS Free Tier account before launching anything

Current AWS rules are different from older tutorials:

- Eligible new accounts receive **$100 in credits**, with activities offering up to **$100 more**. The Free plan lasts until six months or credit exhaustion, whichever comes first. Check the balance and expiry in your actual account. [AWS Free Tier](https://aws.amazon.com/free/).
- AWS distinguishes accounts created **before 15 July 2025** from newer accounts. The old twelve-month offer is not a fresh entitlement for an old account. Its window has already expired for pre-July-2025 accounts by this guide's date. [EC2 Free Tier rules](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html).
- Three running instances consume three instances' worth of compute. Also account for EBS storage, public IPv4, and applicable transfer. “Free tier eligible” does not mean unlimited usage.
- Public IPv4 has a listed charge of **$0.005 per address-hour**, before applicable credits/benefits. One address for ten hours is $0.05. NAT gateways add hourly and data-processing costs; this design does not create one. [VPC pricing](https://aws.amazon.com/vpc/pricing/).

1. Start at the official [AWS Free Tier page](https://aws.amazon.com/free/). For a new eligible personal lab account, select the **Free plan** and **Basic support** where offered. Complete AWS's identity/payment verification yourself.
2. Enable MFA on the root account. Use the day-to-day identity/role your team authorizes for the lab; keep root for account administration.
3. Open **Billing and Cost Management → Free Tier / Credits** and check your plan, remaining credits, and expiry. Do not upgrade to a paid plan just to follow this guide.
4. Set an email budget alert if available in your plan, for example a small monthly cost budget. Check credit consumption as well: credits can offset charges. Budget alerts are notifications, not a hard spending cap.
5. Choose one region. This guide uses **US East (N. Virginia), `us-east-1`** as an example. If your team specifies another region, use it for every resource. Availability Zone letters can differ between accounts.

If your plan does not allow three chosen instances, inspect the launch error and your account's limits with your team lead. A free account is not a promise of a particular quota. Do not solve it by selecting larger paid resources without checking the cost.

**Screenshot 02:** plan/credit status for your own evidence; hide account number, email, payment details and other sensitive billing information before sharing.

## 5. Understand the network you are creating

| Component | Name | IPv4/CIDR | Public IPv4? |
|---|---|---|---|
| VPC | `lab-vpc` | `10.20.0.0/16` | Not applicable |
| Public subnet | `lab-public` | `10.20.1.0/24` | Frontend only |
| Private subnet | `lab-private` | `10.20.2.0/24` | None |
| Frontend EC2 | `lab-frontend` | `10.20.1.10` | Yes, auto-assigned |
| Backend EC2 | `lab-backend` | `10.20.2.10` | No |
| Database EC2 | `lab-database` | `10.20.2.20` | No |

A **VPC** is your AWS network. A **subnet** is a smaller address range inside it. A **route table** decides where traffic can go. A **security group** is a stateful firewall attached to a server's network interface.

An **Internet Gateway** connects the VPC to the internet. A subnet is public because its route table points to that gateway; the name “public” alone does nothing. A server also needs a public address and appropriate security-group rules to receive internet traffic. [AWS VPC example](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-example-private-subnets-nat.html).

Both private servers use the same private subnet. Their separate security groups enforce frontend → backend → database access. The assignment does not require a different subnet for every server.

The app's request path is:

```text
Browser: http://FRONTEND_PUBLIC_IP
    ↓ HTTP 80
Frontend EC2: Nginx serves the React files
    ↓ /api/entries → 10.20.2.10:8000
Backend EC2: Python validates text and adds the UTC time
    ↓ SQL → 10.20.2.20:5432
Database EC2: PostgreSQL stores the record on its disk
    ↑ saved/read record returns along the same path
```

React executes in the visitor's browser after Nginx sends the files. Therefore React calls a relative address, `/api/entries`. It must not call `http://10.20.2.10:8000` directly: your team lead's browser cannot route to a private VPC address. Nginx makes that private connection on its behalf. Keeping the browser request on the same origin also avoids a cross-origin setup. [Nginx reverse proxy documentation](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/).

## 6. Create the VPC, two subnets, and route tables

All actions in this section happen in the **AWS Console**, not Terminal.

1. Open **VPC → Your VPCs → Create VPC**.
2. Choose **VPC only**. Name: `lab-vpc`. IPv4 CIDR: `10.20.0.0/16`. No IPv6. Tenancy: Default. Create.
3. Select the VPC, open **Actions → Edit VPC settings**, and enable DNS resolution and DNS hostnames if not already enabled.
4. Open **Subnets → Create subnet**, choose `lab-vpc`, and create `lab-public`, CIDR `10.20.1.0/24`.
5. Create `lab-private`, CIDR `10.20.2.0/24`, in the **same Availability Zone** as `lab-public`.
6. For `lab-public`, choose **Actions → Edit subnet settings** and enable auto-assign public IPv4. For `lab-private`, confirm auto-assign public IPv4 is disabled.
7. Open **Internet gateways → Create internet gateway**, name it `lab-igw`, then **Actions → Attach to VPC → lab-vpc**.
8. Open **Route tables → Create route table**. Create `lab-public-rt` in `lab-vpc`.
9. Select it, **Routes → Edit routes → Add route**: destination `0.0.0.0/0`, target **Internet Gateway → lab-igw**. Keep the automatic `10.20.0.0/16 → local` route.
10. **Subnet associations → Edit subnet associations**: select **only `lab-public`**.
11. Create `lab-private-rt` in `lab-vpc`. Its routes must contain **only `10.20.0.0/16 → local`**. Do not add an internet or NAT default route.
12. Explicitly associate **only `lab-private`** with `lab-private-rt`.

Leave the VPC's default network ACL unchanged for this beginner lab. Security groups will control access. Do not create a NAT gateway, load balancer, RDS database, VPC endpoint, extra bastion instance, or Elastic IP for this design.

**Screenshot 03:** both subnets and their CIDRs. **Screenshot 04:** public route table with the Internet Gateway route. **Screenshot 05:** private route table with only the local route; capture its subnet association too.

## 7. Create three security groups

Open **EC2 → Security Groups → Create security group**. Create all three groups in **`lab-vpc`** first so they are available when you add references. Names: `sg-frontend`, `sg-backend`, `sg-database`.

On your Mac, find the public IPv4 of the network from which you will connect:

```bash
curl -4 https://checkip.amazonaws.com
```

If it prints `203.0.113.25` as an example, your source entry is `203.0.113.25/32`. Use your **actual** result, not that example. AWS's **My IP** option can fill this in. Office and VPN policies can affect which address your traffic uses.

Add these **inbound** rules:

| Security group | Type / TCP port | Source | Why |
|---|---|---|---|
| `sg-frontend` | SSH / 22 | Your public IPv4 `/32` | Your Mac administers the lab |
| `sg-frontend` | HTTP / 80 | Your public IPv4 `/32` | Your browser opens the app |
| `sg-frontend` | HTTP / 80 | Team lead's public IPv4 `/32`, if different | Team lead opens the live IP |
| `sg-frontend` | Custom TCP / 8888 | **`sg-backend`** | Temporary package downloads |
| `sg-frontend` | Custom TCP / 8888 | **`sg-database`** | Temporary package downloads |
| `sg-backend` | SSH / 22 | **`sg-frontend`** | SSH jump connection |
| `sg-backend` | Custom TCP / 8000 | **`sg-frontend`** | Nginx reaches Python |
| `sg-database` | SSH / 22 | **`sg-frontend`** | SSH jump connection |
| `sg-database` | PostgreSQL / 5432 | **`sg-backend`** | Python reaches PostgreSQL |

For bold sources, select the actual security group ID from the source picker. Do not enter the group name as an IP, and do not attach all groups to every instance. A source group rule permits traffic originating from interfaces associated with that group. [AWS security-group rules](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html).

Keep default **outbound allow-all** rules for this lab. They do not give the private subnet an internet route. Responses to allowed connections are handled by stateful security groups.

If your evaluator explicitly needs access from arbitrary networks, you can temporarily allow HTTP 80 from `0.0.0.0/0` while using only made-up data. SSH 22, backend 8000, PostgreSQL 5432 and proxy 8888 must never be open to the whole internet.

**Screenshot 06:** all three groups' inbound rules. Take the final screenshot again after removing the two temporary 8888 rules.

## 8. Launch exactly three EC2 instances

Open **EC2 → Instances → Launch instances**. Launch them one at a time to avoid putting all three in the same subnet by mistake.

For **all three**:

- Choose the official **Ubuntu Server 24.04 LTS**, **64-bit x86 (x86_64)** image published by Canonical. Avoid Ubuntu Pro or Marketplace images with additional fees.
- Choose **t3.micro**, if marked eligible and allowed in your plan/region. If unavailable, check with your lead before selecting an alternative. The architecture and AMI must match.
- Create one **RSA `.pem` key pair**, name `netsol-lab-key`, and use it for these three lab machines. Save it on your Mac. AWS will not let you download the private key again.
- Set a small root disk, e.g. **8 GiB gp3**, with **Delete on termination** enabled. Three 8 GiB disks total 24 GiB of provisioned storage. Keep encryption enabled if already enabled.
- No IAM instance profile is needed by this app. Leave user data blank. Keep detailed monitoring off.
- Under **Advanced details**, require IMDSv2 where available, and use **Standard** T3 credit mode to avoid surplus-credit charges. You can also find credit settings under instance actions after launch. [T3 credit mode documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-how-to.html).

Under **Network settings → Edit**, apply:

| Name | VPC | Subnet | Auto-assign public IPv4 | Private IPv4 | Existing group |
|---|---|---|---|---|---|
| `lab-frontend` | `lab-vpc` | `lab-public` | Enable | `10.20.1.10` | `sg-frontend` only |
| `lab-backend` | `lab-vpc` | `lab-private` | Disable | `10.20.2.10` | `sg-backend` only |
| `lab-database` | `lab-vpc` | `lab-private` | Disable | `10.20.2.20` | `sg-database` only |

Expand **Advanced network configuration** if needed to enter the primary private IPv4 address. These exact addresses are used in the supplied scripts. Verify them before launching; do not proceed with different addresses without updating the configuration consistently.

Wait until all three are **Running** and all status checks pass. Copy the frontend's **Public IPv4 address** into your notes. Confirm the backend and database each show **no Public IPv4 address**.

An automatically assigned frontend public IP may change when you stop and start that instance. The chosen private IPs normally remain with the instance's network interface. After any stop/start, update the live URL and your SSH configuration with the current public IP. [EC2 instance IP addressing](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-instance-addressing.html).

**Screenshot 07:** the three named instances. **Screenshots 08–10:** each instance's networking details, including subnet, private IP, and public-IP field.

## 9. Configure SSH access from your Mac

SSH lets your Mac run commands on a server. The frontend also acts as a jump host for administration; there is no fourth machine. Your private key stays on your Mac. Do not copy it to EC2 or enable agent forwarding.

On your **Mac**:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
mv ~/Downloads/netsol-lab-key.pem ~/.ssh/netsol-lab-key.pem
chmod 400 ~/.ssh/netsol-lab-key.pem
nano ~/.ssh/config
```

If you saved the key somewhere else, adjust the `mv` source. If a key already exists at the destination, choose a different filename and use it below instead of overwriting it. Add these blocks to the end of the SSH config; preserve any existing content. Replace `FRONTEND_PUBLIC_IP` with the real public IPv4:

```sshconfig
Host netsol-frontend
    HostName FRONTEND_PUBLIC_IP
    User ubuntu
    IdentityFile ~/.ssh/netsol-lab-key.pem
    IdentitiesOnly yes

Host netsol-backend
    HostName 10.20.2.10
    User ubuntu
    IdentityFile ~/.ssh/netsol-lab-key.pem
    IdentitiesOnly yes
    ProxyJump netsol-frontend

Host netsol-database
    HostName 10.20.2.20
    User ubuntu
    IdentityFile ~/.ssh/netsol-lab-key.pem
    IdentitiesOnly yes
    ProxyJump netsol-frontend
```

Save, then run:

```bash
chmod 600 ~/.ssh/config
ssh netsol-frontend
```

On first connection, SSH displays the server's host fingerprint. Verify it against that instance's boot/system log in **EC2 → Actions → Monitor and troubleshoot → Get system log** where the SSH host fingerprints are reported, then accept it. Repeat for the private servers on first connection. Do not disable host-key checking.

You are now **on the frontend EC2**, not on your Mac. Run:

```bash
hostname -I
exit
```

Expected private address: `10.20.1.10`. `exit` brings you back to your Mac.

Test the two jump connections, returning to the Mac after each:

```bash
ssh netsol-backend
hostname -I
exit
ssh netsol-database
hostname -I
exit
```

Expected private addresses: `10.20.2.10` and `10.20.2.20` respectively. If SSH times out, fix the network/security-group issue before running setup scripts.

**Screenshot 11:** successful SSH to the two private instances showing their private addresses. Keep keys and secrets out of the image.

## 10. Copy the source from your Mac to the three instances

This method works even with a private GitHub repository and keeps GitHub credentials off the servers. Your GitHub commit is the source record; the files are transferred over SSH.

Return to the **project root on your Mac**, with the GitHub publishing step complete. Check that the working tree is clean; commit intended changes before copying:

```bash
git status --short
git rev-parse --short HEAD
```

Create the destination folders:

```bash
ssh netsol-frontend 'mkdir -p ~/lab-src'
ssh netsol-backend 'mkdir -p ~/lab-src'
ssh netsol-database 'mkdir -p ~/lab-src'
```

Copy only the source files each server needs:

```bash
scp -r deploy netsol-frontend:~/lab-src/
scp -r deploy netsol-backend:~/lab-src/
scp -r deploy database netsol-database:~/lab-src/
ssh netsol-backend 'mkdir -p ~/lab-src/backend'
scp backend/main.py backend/requirements.txt netsol-backend:~/lab-src/backend/
```

`scp` uses the SSH jump configuration automatically. The database server receives SQL; the backend receives Python; the frontend receives the built React files in section 14. No `.env` or `.pem` is uploaded.

## 11. Prepare the frontend and temporary package proxy

A private instance with no internet route cannot normally run `apt update` or download Python packages. We temporarily run an HTTP/HTTPS forward proxy on the frontend. The private machines connect to its **private** IP; it downloads packages using its internet access. This is distinct from Nginx forwarding incoming app requests. Tinyproxy's Allow/Listen settings restrict its clients. [Tinyproxy documentation](https://tinyproxy.github.io/).

From your **Mac**:

```bash
ssh netsol-frontend
```

Now on the **frontend EC2**:

```bash
sudo bash ~/lab-src/deploy/01-frontend-bootstrap.sh
sudo systemctl status tinyproxy --no-pager
exit
```

Expected: tinyproxy is **active (running)** and listening on `10.20.1.10:8888`. The two temporary frontend security-group rules from section 7 must exist. Leave EC2 source/destination checking enabled; this machine is not a NAT router.

## 12. Install PostgreSQL on the database EC2

First, generate a database password on your **Mac**:

```bash
openssl rand -hex 32
```

Save this 64-character hexadecimal value in your password manager for the duration of the lab. Use this same value for the database role and backend. Do not add it to GitHub or a screenshot.

Connect from your **Mac**:

```bash
ssh netsol-database
```

Now on the **database EC2**:

```bash
sudo bash ~/lab-src/deploy/02-database-setup.sh
```

The script installs PostgreSQL, creates `notesdb`, creates a limited login named `record_app`, and asks you to paste the generated password **twice**. No characters are displayed while typing/pasting a password; that is normal.

The table stores an ID, text, and timezone-aware timestamp. PostgreSQL listens on loopback and `10.20.2.20`. Its host authentication file allows the application login only from `10.20.2.10/32`, using SCRAM password authentication. Its security group separately allows TCP 5432 only from `sg-backend`.

Verify on the **database EC2**:

```bash
sudo pg_lsclusters
sudo -u postgres psql -d notesdb -c '\d entries'
sudo -u postgres psql -d notesdb -c '\du record_app'
sudo ss -lntp | grep 5432
exit
```

Expected: the cluster is **online**, the table exists, and `record_app` is not a superuser. A generic `postgresql.service` can say “active (exited)” because Ubuntu uses a wrapper service; `pg_lsclusters` shows the real cluster state.

**Screenshot 12:** table definition, online cluster, and listening private address. This shows PostgreSQL is installed on the EC2 machine, not RDS.

## 13. Install the Python backend as a service

From your **Mac**:

```bash
ssh netsol-backend
```

Now on the **backend EC2**:

```bash
sudo bash ~/lab-src/deploy/03-backend-setup.sh
```

Paste the **same generated database password** when asked. The script installs Python dependencies through the temporary proxy, creates a restricted service account, and starts the application using systemd. systemd restarts the service after failures and starts it when the instance boots. Closing SSH does not stop it.

The password is saved only on the backend in `/etc/timestamp-notebook.env`, readable by root. The service uses that environment to connect to PostgreSQL. Do not display this file in a screenshot.

Verify on the **backend EC2**:

```bash
sudo systemctl status notebook --no-pager
curl -sS http://10.20.2.10:8000/api/health
exit
```

Expected health result:

```json
{"status":"ok","database":"reachable"}
```

This check reads the real database table through the application account. It can succeed even while the table is empty.

**Screenshot 13:** `notebook` active and the successful health result.

## 14. Publish React through Nginx on the frontend

On your **Mac**, from the project root, build the final React files and copy them:

```bash
npm ci --prefix frontend
npm run build --prefix frontend
ssh netsol-frontend 'mkdir -p ~/lab-dist'
scp -r frontend/dist/. netsol-frontend:~/lab-dist/
ssh netsol-frontend
```

Now on the **frontend EC2**:

```bash
sudo bash ~/lab-src/deploy/04-frontend-publish.sh
sudo nginx -t
curl -sS http://127.0.0.1/api/health
exit
```

Expected: Nginx configuration test passes, and health says the database is reachable. This request passed from frontend Nginx to backend Python and then PostgreSQL.

Open in your Mac's browser:

```text
http://FRONTEND_PUBLIC_IP
```

Replace the placeholder. Type `http://` explicitly; this lab does not configure HTTPS or a domain. The browser may label HTTP “Not secure.” Use only made-up notes.

Type `NETSOL DevOps lab — live insert`, press **Insert**, then **Retrieve**. The second text box should show your text, an ID, and the date/time. Refresh the page and press Retrieve again. The record should remain because it is in PostgreSQL.

**Screenshot 14:** the live browser URL showing the frontend's public IP and your retrieved record. **Screenshot 15:** Nginx health/configuration checks.

## 15. Remove the temporary installation access

From your **Mac**:

```bash
ssh netsol-frontend
```

On the **frontend EC2**:

```bash
sudo bash ~/lab-src/deploy/05-disable-package-proxy.sh
systemctl is-active tinyproxy
sudo ss -lntp | grep ':8888' || true
curl -sS http://127.0.0.1/api/health
exit
```

Expected: tinyproxy is **inactive**, nothing listens on port 8888, and the app health check still succeeds. `systemctl is-active` returns a nonzero status for an inactive service; that is expected here.

In the **AWS Console**, delete **both** TCP 8888 inbound rules from `sg-frontend`. Leave HTTP 80 and SSH 22 scoped to the intended sources. Recheck that `lab-private-rt` still has only its local route.

Reload the live site and insert/retrieve once more. The application works without the download proxy. Private instances remain isolated from direct internet access throughout the lab.

For future OS/package updates, temporarily restore these two rules, start tinyproxy on the frontend, and run the needed private-instance package commands with the proxy settings from `deploy/common.sh`. Stop the proxy and remove the rules again afterward. Do not add a public IP or internet route to a private server to fix a package-download failure.

**Screenshot 16:** final frontend security group without 8888 and final successful app use.

## 16. Prove the record exists in PostgreSQL

Choose a unique new note in the live browser, for example `Team-lead demo 2026-09-10 15:30`, insert it, and retrieve it.

On your **Mac**:

```bash
ssh netsol-database
```

On the **database EC2**:

```bash
sudo -u postgres psql -d notesdb -c "SET TIME ZONE 'UTC'; SELECT id, text, created_at FROM entries ORDER BY id DESC LIMIT 5;"
exit
```

Match the ID and text to the browser. SQL is explicitly showing UTC; the browser displays its labeled local timezone. Different displayed hour values can represent the same instant.

**Screenshot 17:** SQL result with the same record. This is stronger evidence than a frontend screenshot alone.

## 17. Show your team lead the live deployment

Use [the demonstration checklist](DEMO-CHECKLIST.md). Keep all three EC2 instances running during the demo and verify the frontend's current public IP just before the meeting.

1. Share your GitHub repository URL. For a private repo, confirm your lead has access.
2. Share `http://FRONTEND_PUBLIC_IP`, and add their current public IPv4 `/32` to frontend HTTP 80 if needed. They do not need SSH access to use the app.
3. Screen-share the running application. Ask your lead for fresh text, enter it, insert, retrieve, and refresh/retrieve again.
4. Show the matching row in PostgreSQL, the three EC2 instances, private-IP/no-public-IP details, routes, and security groups.
5. Show `systemctl status notebook`, Nginx health, and the key source files. Explain how the request crosses each tier.

A public IP URL continues working while the servers, services and network rules remain available. It is not a permanent hosting promise: the IP can change after stop/start and credit expiry can stop your lab. Coordinate the demo time, then shut down according to section 19.

## 18. Troubleshooting: check one connection at a time

| Symptom | Check / fix |
|---|---|
| Mac npm cache permission error | From the project root try `npm ci --prefix frontend --cache .npm-cache`; that cache folder is ignored by Git. Do not use `sudo npm install`. |
| Docker command missing / engine unavailable | Start an approved Docker installation, or skip the optional rehearsal and proceed to AWS. |
| SSH “unprotected private key” | On Mac: `chmod 400 ~/.ssh/netsol-lab-key.pem`. |
| SSH permission denied | Ubuntu username is `ubuntu`; check the chosen key pair and `IdentityFile`. |
| SSH timeout to frontend | Confirm instance running, current public IP, public subnet IGW route, and port 22 source matching your current public IP. |
| SSH timeout to private machine | Confirm frontend SSH works, ProxyJump blocks exist, target private IP is correct, and target SSH source is `sg-frontend`. |
| Private machine package downloads time out | Confirm tinyproxy running, temporary source-group 8888 rules, and the setup script's proxy environment. No internet default route is expected. |
| `apt` lock message | Initial Ubuntu/cloud-init updates may still be running. Wait for them to finish; do not delete lock files. Retry the setup afterward. |
| Frontend Nginx welcome page | Run section 14, verify `lab-dist/index.html`, and inspect `sudo nginx -t`. |
| Browser cannot open app | Use explicit `http://`, current public IP, port 80 inbound rule, and check Nginx. Your office may block outbound HTTP; check with your team if so. |
| HTTP 502 | Nginx cannot reach Python. On frontend run `curl -v http://10.20.2.10:8000/api/health`; check backend SG 8000 from frontend and `notebook` service. |
| HTTP 503 / database unavailable | On backend inspect `sudo journalctl -u notebook -n 60 --no-pager`. Check DB service, DB SG 5432 from backend, `pg_hba.conf`, listen address, database/table, and matching password. |
| HTTP 422 | Text must be nonblank and at most 2000 characters. A client-supplied timestamp is not accepted. |
| HTTP 429 | Nginx limits API request rate. Wait briefly and retry normal manual actions. |
| Insert request times out | First press Retrieve to see whether the server already saved it. Repeating a POST can create a duplicate note. |
| Empty output after insert | Insert confirms saving; press Retrieve to reload the second box. It shows only the latest 100 records. |
| Date appears offset | Database/API timestamps are UTC. The browser displays local time with a timezone label. |
| SSH host-key warning after changing servers | Verify the replacement instance's fingerprint and update the one matching known-host entry. Do not disable host-key checking globally. |
| Works before closing SSH but stops afterward | Use the supplied systemd service and Nginx; do not leave a development server running manually as the deployed backend. |

Useful commands **on the frontend EC2**:

```bash
sudo systemctl status nginx --no-pager
sudo tail -n 50 /var/log/nginx/error.log
curl -v http://10.20.2.10:8000/api/health
```

Useful commands **on the backend EC2**:

```bash
sudo systemctl status notebook --no-pager
sudo journalctl -u notebook -n 60 --no-pager
curl -v http://10.20.2.10:8000/api/health
```

Useful commands **on the database EC2**:

```bash
sudo pg_lsclusters
sudo ss -lntp | grep 5432
sudo -u postgres psql -d notesdb -c 'SELECT count(*) FROM entries;'
```

Never post the contents of `/etc/timestamp-notebook.env`, private keys, credentials, or unrelated logs when asking for help.

## 19. Stop or clean up after the demonstration

**Pause for another session:** in EC2, select the three named lab instances and choose **Instance state → Stop instance**. Compute stops, but attached EBS disks can still consume credits/incur storage charges. On the next session start the database, backend, then frontend, wait for status checks, and update your SSH config/browser with the frontend's current public IP.

**Finish the lab:** save your code, evidence and any notes you want to keep first. An optional database backup can be pulled from your **Mac**:

```bash
ssh netsol-database 'sudo -u postgres pg_dump notesdb' > lab-backup.sql
```

The backup stays on your Mac and is ignored by Git. If the SSH command fails, do not assume the backup is complete; check that it contains the expected dump before deleting AWS resources.

Then in the AWS Console:

1. Confirm the exact three **lab** instances by name, subnet and ID. Terminate only those instances. Termination is permanent, and Delete on termination removes their root disks and PostgreSQL data.
2. Check **EC2 → Volumes** for any surviving lab disks, and remove them only after confirming you no longer need their data. Delete unwanted lab snapshots if you created any.
3. Check for unintended Elastic IPs, NAT gateways or other chargeable lab resources; release/delete only confirmed lab resources you created. This guide intentionally creates none of those.
4. Once the instances/network interfaces have disappeared, remove the lab's custom security groups, subnet associations/subnets, custom route tables, detach/delete `lab-igw`, and delete `lab-vpc` as dependencies permit. You can use the VPC deletion summary to review dependent lab networking resources before confirming. Preserve every unrelated resource.
5. Recheck Billing/Free Tier usage; billing data can lag. Keep GitHub source and your screenshots for assessment.

Stopping is reversible. Terminating instances and deleting their disks is not a way to pause.
