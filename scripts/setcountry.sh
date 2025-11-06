#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${PROJECT_ROOT}/templates"
STATE_DIR="${PROJECT_ROOT}/.runtime"
SELECTION_FILE="${STATE_DIR}/country"
readonly SCRIPT_DIR PROJECT_ROOT TEMPLATE_DIR STATE_DIR SELECTION_FILE

usage() {
  cat <<'EOF'
Usage: setcountry.sh <country>

Select the WireGuard/Tor exit template that start.sh should consume.
Templates live under templates/ and follow the KEY=VALUE schema.

Arguments:
  <country>  Country key (e.g. local, us) matching templates/wg0_<country>.conf
EOF
}

ensure_runtime_dir() {
  mkdir -p "${STATE_DIR}"
  chmod 700 "${STATE_DIR}"
}

validate_template() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "error: template ${path} not found" >&2
    exit 1
  fi

  local missing=()
  for key in SERVER_PUBLIC_KEY SERVER_ENDPOINT ALLOWED_IPS CLIENT_ADDRESS; do
    if ! grep -Eq "^[[:space:]]*${key}=" "${path}"; then
      missing+=("${key}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    echo "error: template ${path} missing keys: ${missing[*]}" >&2
    exit 1
  fi
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

country="$1"
template_path="${TEMPLATE_DIR}/wg0_${country}.conf"

ensure_runtime_dir
validate_template "${template_path}"

printf '%s\n' "${country}" >"${SELECTION_FILE}"
chmod 600 "${SELECTION_FILE}"

echo "Selected country '${country}'. Template: ${template_path}"
