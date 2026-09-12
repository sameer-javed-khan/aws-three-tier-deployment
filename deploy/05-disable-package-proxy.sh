#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_instance 10.20.1.10
systemctl disable --now tinyproxy
printf 'Package proxy stopped. Delete BOTH temporary TCP 8888 inbound rules from sg-frontend.\n'
printf 'Nginx and the application keep running.\n'
