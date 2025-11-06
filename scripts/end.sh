#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR PROJECT_ROOT

usage() {
  cat <<'EOF'
Usage: end.sh [--dry-run]

Tear down the active CrackedVPN session:
  * Bring down the wg0 interface
  * Securely remove transient configuration and keys
  * Reset Tor/TUN route adjustments

Flags:
  --dry-run   Print the planned steps without executing them
  -h, --help  Show this help
EOF
}

dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown flag $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

main() {
  echo "[todo] Detect running wg interface name (default wg0)"
  echo "[todo] Execute wg-quick down for the interface"
  echo "[todo] Delete transient WireGuard config and key files"
  echo "[todo] Flush routing changes applied during start"
  if [[ "${dry_run}" == "true" ]]; then
    echo "Dry run mode: no actions executed."
  fi
}

main "$@"
