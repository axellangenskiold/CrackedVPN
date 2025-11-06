#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR PROJECT_ROOT

usage() {
  cat <<'EOF'
Usage: start.sh [--country <name>] [--dry-run]

Bootstrap the runtime WireGuard + Tor stack:
  * Load the target template selected via setcountry.sh
  * Generate an ephemeral WireGuard client keypair
  * Materialise a transient wg0.conf and bring up the interface
  * Configure Tor-aware routing for all traffic

Flags:
  --country <name>  Override the currently selected country (optional)
  --dry-run         Print the steps without executing them (scaffold only)
  -h, --help        Show this help
EOF
}

country_override=""
dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --country)
      country_override="${2-}"
      if [[ -z "${country_override}" ]]; then
        echo "error: --country requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
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
  echo "[todo] Validate dependencies (wg, wg-quick, torsocks)"
  echo "[todo] Resolve active country selection or apply override: ${country_override:-<unset>}"
  echo "[todo] Generate keypair with wg and build wg0.conf in memory"
  echo "[todo] Call wg-quick up on the transient config"
  echo "[todo] Bootstrap Tor routing and confirm connectivity"
  if [[ "${dry_run}" == "true" ]]; then
    echo "Dry run mode: no actions executed."
  fi
}

main "$@"
