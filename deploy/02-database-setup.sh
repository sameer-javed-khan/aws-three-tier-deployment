#!/usr/bin/env bash
# Run only on lab-database. This intentionally prompts for the app password.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_instance 10.20.2.20
use_package_proxy
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client
systemctl enable --now postgresql

if [[ "$(sudo -u postgres psql -Atc "SELECT 1 FROM pg_roles WHERE rolname='record_app'")" != 1 ]]; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c 'CREATE ROLE record_app LOGIN'
fi
if [[ "$(sudo -u postgres psql -Atc "SELECT 1 FROM pg_database WHERE datname='notesdb'")" != 1 ]]; then
  sudo -u postgres createdb notesdb
fi
printf '\nPaste the generated database password at both prompts. Input will be hidden.\n'
sudo -u postgres psql -v ON_ERROR_STOP=1 -c '\password record_app'
sudo -u postgres psql -v ON_ERROR_STOP=1 -d notesdb < "$SCRIPT_DIR/../database/schema.sql"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER SYSTEM SET listen_addresses = '127.0.0.1,10.20.2.20'"
HBA_FILE="$(sudo -u postgres psql -Atc 'SHOW hba_file')"
HBA_RULE='host notesdb record_app 10.20.2.10/32 scram-sha-256'
if ! grep -Fxq "$HBA_RULE" "$HBA_FILE"; then
  printf '\n# Timestamp Notebook: only the backend may log in remotely.\n%s\n' "$HBA_RULE" >> "$HBA_FILE"
fi
systemctl restart postgresql
pg_isready -h 10.20.2.20 -p 5432
printf '\nPostgreSQL configured. Keep the password for the backend setup.\n'
