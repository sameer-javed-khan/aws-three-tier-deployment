FROM postgres:16-bookworm

# Store setup files inside the Linux image instead of executing a Mac bind mount.
# A non-executable .sh is sourced by the official PostgreSQL entrypoint.
COPY --chmod=0644 local-init.sh /docker-entrypoint-initdb.d/01-init.sh
COPY --chmod=0644 schema.sql /schema.sql
