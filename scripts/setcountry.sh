#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${PROJECT_ROOT}/templates"
STATE_DIR="${PROJECT_ROOT}/.runtime"
readonly SCRIPT_DIR PROJECT_ROOT TEMPLATE_DIR STATE_DIR

usage() {
  cat <<'EOF'
Usage: setcountry.sh <country>

Select the WireGuard template that should be expanded by start.sh.
Templates live under templates/ and contain server-side stubs only.

Arguments:
  <country>  Country key (e.g. local, us) matching templates/wg0_<country>.conf
EOF
}

ensure_runtime_dir() {
  mkdir -p "${STATE_DIR}"
  chmod 700 "${STATE_DIR}"
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

country="$1"
template_path="${TEMPLATE_DIR}/wg0_${country}.conf"
selection_file="${STATE_DIR}/country"

main() {
  ensure_runtime_dir

  if [[ ! -f "${template_path}" ]]; then
    echo "error: template ${template_path} not found" >&2
    exit 1
  fi

  echo "[todo] Validate template contents before selection"
  echo "[todo] Record active template for start.sh to consume"
  echo "[todo] Optionally render preview of server stub for debugging"

  printf '%s\n' "${country}" > "${selection_file}"
  chmod 600 "${selection_file}"
  echo "Selected country '${country}'."
}

main "$@"
