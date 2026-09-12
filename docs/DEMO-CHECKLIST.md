# Screenshots and a live demonstration for your team lead

## How to take screenshots on your Mac

- **Command + Shift + 4:** drag to capture a selected area.
- **Command + Shift + 5:** choose a window/full-screen capture or a screen recording.
- Use the screenshot toolbar's **Options → Save to** to choose a lab evidence folder.
- Name each capture clearly, such as `14-live-frontend.png`. Capture the actual deployment. A local preview is not evidence of an EC2 deployment.

Keep credentials, key files, password prompts with visible pasted text, account numbers, billing details, access tokens, and unrelated work out of screenshots. The frontend public IP belongs in the live-app evidence so the deployment can be identified.

## Evidence checklist

| Done | Suggested filename | Capture | What it proves |
|---|---|---|---|
| ☐ | `01-github.png` | Repository page, source folders and README | Versioned source is on GitHub |
| ☐ | `02-free-tier.png` | Sanitized plan/credit status | You checked the account's Free Tier/credit position |
| ☐ | `03-subnets.png` | Public/private subnets, CIDRs and VPC | Both network segments exist |
| ☐ | `04-public-routes.png` | Public route table and its subnet association | Public subnet has the Internet Gateway route |
| ☐ | `05-private-routes.png` | Private route table and its subnet association | Private subnet has only the VPC-local route |
| ☐ | `06-security-groups.png` | Inbound rules of all three groups; use multiple captures if needed | Only the intended tier-to-tier connections are allowed |
| ☐ | `07-three-instances.png` | Three instance names and running state | Exactly three EC2 machines implement the lab |
| ☐ | `08-frontend-network.png` | Frontend subnet/private IP/public IPv4 | Frontend is the publicly addressed instance |
| ☐ | `09-backend-network.png` | Backend private subnet and blank public IPv4 | Backend has no public address |
| ☐ | `10-database-network.png` | Database private subnet and blank public IPv4 | Database has no public address |
| ☐ | `11-private-ssh.png` | SSH through jump host, `hostname -I` on private instances | You can administer private machines without public IPs |
| ☐ | `12-postgresql.png` | `pg_lsclusters`, table definition and PostgreSQL listener | PostgreSQL runs on the EC2 operating system |
| ☐ | `13-python-service.png` | `systemctl status notebook` and backend health response | Python runs as a persistent service and reaches the DB |
| ☐ | `14-live-frontend.png` | Browser address bar with public IP, entered text and retrieved record | The live frontend inserts/retrieves records |
| ☐ | `15-nginx.png` | `nginx -t` and health through Nginx | Frontend reverse proxy reaches both private tiers |
| ☐ | `16-final-proxy-off.png` | No temporary 8888 rules, proxy inactive, app still works | Package-download access was removed after installation |
| ☐ | `17-matching-db-row.png` | SQL result with the same ID/text as the browser | The record is actually stored in PostgreSQL |

You can use fewer images if one legible capture proves several points. Do not squeeze unreadable text into one image. Keep a copy of evidence outside AWS before deleting the lab.

## Before the meeting

- [ ] All three EC2 instances are running and status checks pass.
- [ ] You checked the frontend's current public IP after any stop/start.
- [ ] You opened `http://FRONTEND_PUBLIC_IP` from your Mac and tested insert/retrieve.
- [ ] The team lead's current public IPv4 `/32` is allowed on frontend HTTP 80 if they will open it directly.
- [ ] Your private GitHub repo is accessible to your lead.
- [ ] You have tabs ready for GitHub, the app, EC2 instances, subnet routes and security groups.
- [ ] You have a database SSH terminal ready, without passwords on screen.
- [ ] The temporary package proxy is off and both 8888 rules are removed.
- [ ] You are using made-up demonstration text.

## A five-minute live walkthrough

**Minute 1 — show the source and architecture.** Open GitHub. Point to React in `frontend`, Python in `backend`, PostgreSQL schema in `database`, and the Nginx/systemd setup in `deploy`. Explain that there are three EC2 instances, one public subnet and one private subnet.

**Minute 2 — perform a fresh action.** Open the live frontend public IP. Ask your lead for a short phrase. Type it and select Insert, then Retrieve. Show the saved ID and timestamp. Refresh and Retrieve again to prove the result survives reloading the page.

**Minute 3 — prove storage.** On the database EC2, run:

```bash
sudo -u postgres psql -d notesdb -c "SET TIME ZONE 'UTC'; SELECT id, text, created_at FROM entries ORDER BY id DESC LIMIT 5;"
```

Match the ID/text with the browser. Explain that the browser displays local time and the SQL command displays UTC.

**Minute 4 — show network isolation.** Show both private servers' blank public-IP fields, the private route table with only its local route, backend TCP 8000 allowed only from the frontend group, and PostgreSQL TCP 5432 allowed only from the backend group. Show that frontend HTTP 80 is allowed for your evaluator's IP.

**Minute 5 — show operations.** Show that the backend is managed by systemd, Nginx serves the frontend, and the installation proxy has been disabled. Explain how to stop the lab and what remains chargeable while instances are stopped.

## What to say in your own words

“I deployed React behind Nginx on the public EC2 instance. Python and PostgreSQL run on separate EC2 instances in a private subnet, with no public IPs. The browser sends requests to the frontend IP. Nginx forwards API requests to Python over the VPC. Python adds a UTC timestamp and inserts the text using a parameterized SQL query. Retrieve reads the saved records from PostgreSQL and returns them through the same path. Security groups restrict access between the tiers. PostgreSQL is installed on the database machine; I did not use RDS.”

“I temporarily used a package proxy on the frontend to install software on the private machines. I then disabled it and removed those rules. I did not create a NAT gateway or a fourth EC2 instance.”

## Questions you should be ready to answer

| Question | Answer |
|---|---|
| Why doesn't React call the backend private IP directly? | React runs in the visitor's browser, which cannot route into the private VPC. Nginx makes that connection from EC2. |
| What makes the subnet private? | It has no direct Internet Gateway route. The private EC2 instances also have no public IPv4 addresses. |
| Why two different proxy roles? | Nginx is the app's reverse proxy for incoming requests. Tinyproxy was a temporary forward proxy for outgoing package downloads. |
| Where is the timestamp generated? | In Python, using a timezone-aware UTC datetime, before the SQL insert. |
| Where are the data stored? | PostgreSQL's data directory on the database EC2's EBS disk. |
| What happens when SSH closes? | Nginx, PostgreSQL and the systemd-managed Python service keep running. |
| What happens after an instance restart? | Enabled services start again. After a stop/start, check the frontend's public IP and allow startup time. |
| Why no CORS wildcard? | The browser calls the same frontend origin for both the page and `/api`; Nginx performs the private hop. |
| Can the frontend connect directly to PostgreSQL? | The database security group allows PostgreSQL only from the backend group, and its host rule allows the backend private IP. |
| Is this production-ready? | It meets a small lab's needs. Production would require HTTPS, authentication, backups and availability/failure planning. |
| Is it guaranteed to cost nothing? | No blanket guarantee. Current eligible Free plan usage consumes credits; I check plan limits/balance and clean up after the lab. |

## Submission notes to fill in

```text
Lab title: React / Python / PostgreSQL on three EC2 instances
GitHub repository:
Deployed commit:
Live URL: http://
Demo date and availability window:
AWS region / Availability Zone:
Frontend instance ID / private IP / public IP:
Backend instance ID / private IP:
Database instance ID / private IP:
Screenshots folder or approved shared location:
Cleanup completed at:
```

Share only the live URL, repository and sanitized evidence your lead needs. A team lead does not need your private SSH key or database password to evaluate the app.
