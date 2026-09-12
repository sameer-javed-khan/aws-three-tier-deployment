#!/usr/bin/env bash
# Run only on lab-backend after configuring PostgreSQL.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_instance 10.20.2.10
use_package_proxy
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv curl
if ! id notebook >/dev/null 2>&1; then
  useradd --system --user-group --home-dir /opt/timestamp-notebook --shell /usr/sbin/nologin notebook
fi
install -d -m 755 /opt/timestamp-notebook
install -m 644 "$SCRIPT_DIR/../backend/main.py" /opt/timestamp-notebook/main.py
install -m 644 "$SCRIPT_DIR/../backend/requirements.txt" /opt/timestamp-notebook/requirements.txt
python3 -m venv /opt/timestamp-notebook/.venv
/opt/timestamp-notebook/.venv/bin/pip install --no-cache-dir -r /opt/timestamp-notebook/requirements.txt

read -r -s -p 'Paste the SAME generated database password (hidden): ' notebook_db_password
printf '\n'
if [[ ! "$notebook_db_password" =~ ^[a-fA-F0-9]{32,128}$ ]]; then
  printf 'Expected the hexadecimal password generated in the guide. Please rerun.\n' >&2
  exit 1
fi
umask 077
printf 'DB_HOST=10.20.2.20\nDB_PORT=5432\nDB_NAME=notesdb\nDB_USER=record_app\nDB_PASSWORD=%s\n' "$notebook_db_password" > /etc/timestamp-notebook.env
unset notebook_db_password
chmod 600 /etc/timestamp-notebook.env
install -m 644 "$SCRIPT_DIR/notebook.service" /etc/systemd/system/notebook.service
systemctl daemon-reload
systemctl enable notebook
systemctl restart notebook
curl --fail --silent --show-error --retry 6 --retry-delay 1 --retry-connrefused http://10.20.2.10:8000/api/health
printf '\nBackend installed as the notebook service.\n'
