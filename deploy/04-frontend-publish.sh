#!/usr/bin/env bash
# Run on lab-frontend after copying the Mac-built dist folder to ~/lab-dist.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_instance 10.20.1.10
if [[ ! -f /home/ubuntu/lab-dist/index.html ]]; then
  printf 'Missing /home/ubuntu/lab-dist/index.html. Complete the Mac build/upload step first.\n' >&2
  exit 1
fi
install -d -m 755 /var/www/timestamp-notebook
cp -a /home/ubuntu/lab-dist/. /var/www/timestamp-notebook/
chown -R root:root /var/www/timestamp-notebook
find /var/www/timestamp-notebook -type d -exec chmod 755 {} +
find /var/www/timestamp-notebook -type f -exec chmod 644 {} +
install -m 644 "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/timestamp-notebook
ln -sfn /etc/nginx/sites-available/timestamp-notebook /etc/nginx/sites-enabled/timestamp-notebook
# Only disable Ubuntu's initial welcome site. Preserve it for recovery.
if [[ -L /etc/nginx/sites-enabled/default ]]; then
  mv /etc/nginx/sites-enabled/default /etc/nginx/default-site.saved
fi
nginx -t
systemctl reload nginx
curl --fail --silent --show-error http://127.0.0.1/api/health
printf '\nFrontend published. Open http://YOUR_FRONTEND_PUBLIC_IP in your browser.\n'
