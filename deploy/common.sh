#!/usr/bin/env bash
# Shared checks for the fresh Ubuntu EC2 machines described in the guide.
set -euo pipefail

require_instance() {
  if [[ $EUID -ne 0 ]]; then
    printf 'Run this script with sudo on the specified EC2 instance.\n' >&2
    exit 1
  fi
  . /etc/os-release
  if [[ "$ID" != ubuntu || "$VERSION_ID" != 24.04 ]]; then
    printf 'These scripts require Ubuntu Server 24.04 LTS.\n' >&2
    exit 1
  fi
  if ! ip -4 address show | grep -Fq "inet $1/"; then
    printf 'Wrong machine: this script requires private IP %s.\n' "$1" >&2
    exit 1
  fi
}

use_package_proxy() {
  export http_proxy=http://10.20.1.10:8888
  export https_proxy=http://10.20.1.10:8888
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export no_proxy=localhost,127.0.0.1,10.20.1.10,10.20.2.10,10.20.2.20
  export NO_PROXY="$no_proxy"
}
