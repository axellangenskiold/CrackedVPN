#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/.runtime"
SESSION_FILE="${STATE_DIR}/session.env"
readonly SCRIPT_DIR PROJECT_ROOT STATE_DIR SESSION_FILE

usage() {
  cat <<'EOF'
Usage: status.sh [--json]

Report the current state of the CrackedVPN stack:
  • WireGuard interface activity and latest handshake
  • External IP (direct) and Tor-reported IP (via torsocks)
  • Selected country template

Options:
  --json      Emit machine-readable JSON
  -h, --help  Show this help message
EOF
}

load_session_country() {
  if [[ -f "${STATE_DIR}/country" ]]; then
    cat "${STATE_DIR}/country"
  else
    printf 'local\n'
  fi
}

collect_wireguard() {
  if ! command -v wg >/dev/null 2>&1; then
    WG_ACTIVE="false"
    WG_INTERFACE=""
    WG_HANDSHAKE=""
    return
  fi

  if ! wg show wg0 >/dev/null 2>&1; then
    WG_ACTIVE="false"
    WG_INTERFACE=""
    WG_HANDSHAKE=""
    return
  fi

  WG_ACTIVE="true"
  WG_INTERFACE="wg0"
  WG_HANDSHAKE="$(wg show wg0 latest-handshakes 2>/dev/null | awk '{print $2}' | head -n1)"
}

fetch_external_ip() {
  if ! command -v curl >/dev/null 2>&1; then
    DIRECT_IP="(curl not found)"
    return
  fi
  DIRECT_IP="$(curl -fsS --max-time 5 https://ipinfo.io/ip 2>/dev/null || echo "unavailable")"
}

fetch_tor_ip() {
  if ! command -v torsocks >/dev/null 2>&1; then
    TOR_IP="(torsocks not found)"
    return
  fi
  if ! command -v curl >/dev/null 2>&1; then
    TOR_IP="(curl not found)"
    return
  fi
  TOR_IP="$(TORSOCKS_CONF_FILE="${TORSOCKS_CONF_FILE:-}" torsocks curl -fsS --max-time 10 https://check.torproject.org/api/ip 2>/dev/null || true)"
  if [[ -n "${TOR_IP}" ]]; then
    if [[ "${TOR_IP}" =~ \"IP\"\ *:\ *\"([^\"]+)\" ]]; then
      TOR_IP="${BASH_REMATCH[1]}"
    else
      TOR_IP="$(echo "${TOR_IP}" | tr -d '\n')"
    fi
  else
    TOR_IP="unavailable"
  fi
}

escape_json() {
  local raw="$1"
  raw="${raw//\\/\\\\}"
  raw="${raw//\"/\\\"}"
  raw="${raw//$'\n'/\\n}"
  printf '%s' "${raw}"
}

print_json() {
  printf '{'
  printf '"wireguard":{'
  printf '"active":%s,' "$( [[ "${WG_ACTIVE}" == "true" ]] && printf true || printf false )"
  printf '"interface":"%s",' "$(escape_json "${WG_INTERFACE}")"
  printf '"latest_handshake":"%s"' "$(escape_json "${WG_HANDSHAKE}")"
  printf '},'
  printf '"network":{'
  printf '"direct_ip":"%s",' "$(escape_json "${DIRECT_IP}")"
  printf '"tor_ip":"%s"' "$(escape_json "${TOR_IP}")"
  printf '},'
  printf '"country":"%s"' "$(escape_json "${COUNTRY}")"
  printf '}\n'
}

print_human() {
  echo "WireGuard active: ${WG_ACTIVE}"
  if [[ "${WG_ACTIVE}" == "true" ]]; then
    echo "Interface: ${WG_INTERFACE}"
    echo "Latest handshake (epoch): ${WG_HANDSHAKE}"
  fi
  echo "Direct IP: ${DIRECT_IP}"
  echo "Tor IP: ${TOR_IP}"
  echo "Selected country: ${COUNTRY}"
}

main() {
  local json_output="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        json_output="true"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "error: unknown option $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  COUNTRY="$(load_session_country)"
  collect_wireguard
  fetch_external_ip
  fetch_tor_ip

  if [[ "${json_output}" == "true" ]]; then
    print_json
  else
    print_human
  fi
}

main "$@"
