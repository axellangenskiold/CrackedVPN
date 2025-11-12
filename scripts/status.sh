#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/.runtime"
SESSION_FILE="${STATE_DIR}/session.env"
DEFAULT_COUNTRY="local"
DEFAULT_INTERFACE="wg0-client"
readonly SCRIPT_DIR PROJECT_ROOT STATE_DIR SESSION_FILE DEFAULT_COUNTRY DEFAULT_INTERFACE

run_wg() {
  if command -v wg >/dev/null 2>&1; then
    if [[ "${EUID}" -eq 0 ]]; then
      wg "$@"
    elif command -v sudo >/dev/null 2>&1; then
      sudo wg "$@"
    else
      wg "$@"
    fi
  else
    return 1
  fi
}

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

SESSION_COUNTRY="${DEFAULT_COUNTRY}"
SESSION_INTERFACE="${DEFAULT_INTERFACE}"
SESSION_OS_INTERFACE=""

load_session_metadata() {
  if [[ -f "${STATE_DIR}/country" ]]; then
    SESSION_COUNTRY="$(cat "${STATE_DIR}/country")"
  fi

  if [[ -f "${SESSION_FILE}" ]]; then
    declare -A SESSION=()
    while IFS='=' read -r key value; do
      key="${key%%#*}"
      key="$(echo -n "${key}" | tr -d '[:space:]')"
      if [[ -z "${key}" ]]; then
        continue
      fi
      value="${value%%#*}"
      value="${value%"${value##*[![:space:]]}"}"
      value="${value#"${value%%[![:space:]]*}"}"
      SESSION["${key}"]="${value}"
    done <"${SESSION_FILE}"

    SESSION_COUNTRY="${SESSION[COUNTRY]:-${SESSION_COUNTRY}}"
    SESSION_INTERFACE="${SESSION[INTERFACE]:-${SESSION_INTERFACE}}"
    SESSION_OS_INTERFACE="${SESSION[OS_INTERFACE]:-${SESSION_INTERFACE}}"
  fi

  if [[ -z "${SESSION_OS_INTERFACE}" ]]; then
    SESSION_OS_INTERFACE="${SESSION_INTERFACE}"
  fi
}

collect_wireguard() {
  if ! command -v wg >/dev/null 2>&1; then
    WG_ACTIVE="false"
    WG_INTERFACE=""
    WG_HANDSHAKE=""
    return
  fi

  if ! run_wg show "${SESSION_OS_INTERFACE}" >/dev/null 2>&1; then
    WG_ACTIVE="false"
    WG_INTERFACE=""
    WG_HANDSHAKE=""
    return
  fi

  WG_ACTIVE="true"
  WG_INTERFACE="${SESSION_OS_INTERFACE}"
  WG_HANDSHAKE="$(run_wg show "${SESSION_OS_INTERFACE}" latest-handshakes 2>/dev/null | awk '{print $2}' | head -n1)"
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
  printf '"country":"%s"' "$(escape_json "${SESSION_COUNTRY}")"
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
  echo "Selected country: ${SESSION_COUNTRY}"
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

  load_session_metadata
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
