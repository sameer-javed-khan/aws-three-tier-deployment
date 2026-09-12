# Validation and remaining deployment checks

Prepared 10 September 2026.

## Passed locally

- React dependency installation and Vite production build using Node 24.18.0.
- Frontend dependency audit: zero reported vulnerabilities at installation time. This is a point-in-time dependency check, not a security certification.
- Syntax checks for each supplied shell setup script.
- Python API checks: blank/oversized text rejected, invalid retrieval limits rejected, extra client-supplied timestamps rejected, whitespace trimmed, timestamp generated in Python as UTC, SQL parameters passed separately, successful response shape, no-cache response policy, and safe HTTP 503 database errors. These API checks used a mocked database connection.
- SQL checks using the PGlite PostgreSQL engine: supplied schema creation, restricted application-role insert/read, ID and timestamp round trip, SQL-like input stored literally, DELETE denied, and database constraints rejecting blank/oversized text.

## Not yet verified

- A native PostgreSQL 16 process could not initialize because this execution environment denied a shared-memory system operation. PGlite was used only for independent SQL checks; it is not included in the application or the EC2 deployment.
- The frontend, Python and native PostgreSQL have not been tested together end to end in this environment. No browser interaction/screenshot test is claimed.
- Docker was not installed in this execution environment, so the optional Compose rehearsal has not been run here.
- The Ubuntu setup scripts, actual AWS routes/security groups, native systemd/Nginx/PostgreSQL services, and public-IP access require testing on your EC2 instances. Follow the health checks and demonstration steps in the beginner guide.
- No AWS resources were created, no live AWS URL was issued, and no GitHub repository was published during preparation. Those are account-specific steps in the guide.

The supplied PostgreSQL schema and Python connection code target native PostgreSQL on EC2. The embedded test database is not a replacement for the assignment's third EC2 instance.
