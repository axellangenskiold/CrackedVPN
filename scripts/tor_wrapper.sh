#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/.runtime"
readonly SCRIPT_DIR PROJECT_ROOT STATE_DIR

usage() {
  cat <<'EOF'
Usage: tor_wrapper.sh <command> [args...]

Execute the provided command through torsocks, inheriting the current
CrackedVPN session environment (if any).
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

if ! command -v torsocks >/dev/null 2>&1; then
  echo "error: torsocks binary not found in PATH" >&2
  exit 1
fi

echo "Executing via Tor: $*"
exec torsocks "$@"
