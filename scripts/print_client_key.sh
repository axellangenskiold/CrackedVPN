#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.runtime"
CONFIG_FILE="${STATE_DIR}/wg0-client.conf"
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "No client config found; run 'cracked start --dry-run' first." >&2
  exit 1
fi
awk '/^\[Interface\]/ {in_if=1; next} /^\[/ {in_if=0} in_if && /^PrivateKey/ {print $0}' "${CONFIG_FILE}"
