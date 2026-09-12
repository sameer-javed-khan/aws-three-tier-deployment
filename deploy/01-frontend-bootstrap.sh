#!/usr/bin/env bash
# Run only on lab-frontend. No NAT gateway or IP forwarding is used.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_instance 10.20.1.10
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx tinyproxy curl
systemctl stop tinyproxy
install -m 644 "$SCRIPT_DIR/tinyproxy.conf" /etc/tinyproxy/tinyproxy.conf
systemctl enable --now nginx
systemctl enable tinyproxy
systemctl restart tinyproxy
systemctl is-active --quiet tinyproxy
printf '\nFrontend prepared. Temporary package proxy listens only on 10.20.1.10:8888.\n'
