#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/.runtime"
DEFAULT_COUNTRY="local"
CONFIG_FILENAME="wg0-client.conf"
CONFIG_FILE="${STATE_DIR}/${CONFIG_FILENAME}"
INTERFACE_NAME="${CONFIG_FILENAME%.conf}"
SESSION_FILE="${STATE_DIR}/session.env"
LOG_FILE="${STATE_DIR}/start.log"
readonly SCRIPT_DIR PROJECT_ROOT STATE_DIR DEFAULT_COUNTRY CONFIG_FILENAME CONFIG_FILE INTERFACE_NAME SESSION_FILE LOG_FILE

request_privileged_access() {
  if [[ "${EUID}" -ne 0 ]]; then
    require_command sudo
    echo "Elevated privileges required to configure WireGuard. You'll be prompted for your password."
    sudo -v
  fi
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: required command '${cmd}' not found in PATH" >&2
    exit 1
  fi
}

usage() {
  cat <<'EOF'
Usage: start.sh [--country <name>] [--dry-run]

Initialize a WireGuard + Tor session using the selected exit node template.
The tunnel stays active after this command exits. Run `cracked end` to stop it.

Options:
  --country <name>  Override the currently selected country (default: selection or local)
  --dry-run         Print actions without executing WireGuard changes
  -h, --help        Show this help message
EOF
}

ensure_runtime() {
  mkdir -p "${STATE_DIR}"
  chmod 700 "${STATE_DIR}"
}

load_template() {
  local country="$1"
  local template_path="${PROJECT_ROOT}/templates/wg0_${country}.conf"

  if [[ ! -f "${template_path}" ]]; then
    echo "error: template ${template_path} not found" >&2
    exit 1
  fi

  declare -gA TEMPLATE_DATA=()
  while IFS= read -r line || [[ -n "${line}" ]]; do
    # Remove comments
    line="${line%%#*}"
    # Trim whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "${line}" ]]; then
      continue
    fi
    IFS='=' read -r raw_key raw_value <<<"${line}"
    # Strip whitespace and ignore comments/blank lines
    raw_key="$(echo -n "${raw_key}" | tr -d '[:space:]')"
    if [[ -z "${raw_key}" ]]; then
      continue
    fi
    # Preserve value spacing but trim surrounding quotes/newlines
    raw_value="${raw_value%"${raw_value##*[![:space:]]}"}"
    raw_value="${raw_value#"${raw_value%%[![:space:]]*}"}"
    raw_value="${raw_value%\"}"
    raw_value="${raw_value#\"}"
    TEMPLATE_DATA["${raw_key}"]="${raw_value}"
  done <"${template_path}"

  for required in SERVER_PUBLIC_KEY SERVER_ENDPOINT ALLOWED_IPS CLIENT_ADDRESS; do
    if [[ -z "${TEMPLATE_DATA[${required}]:-}" ]]; then
      echo "error: template ${template_path} missing required key ${required}" >&2
      exit 1
    fi
  done
}

read_current_country() {
  if [[ -f "${STATE_DIR}/country" ]]; then
    cat "${STATE_DIR}/country"
  else
    printf '%s\n' "${DEFAULT_COUNTRY}"
  fi
}

write_session_file() {
  local country="$1"
  local os_interface="$2"
  cat >"${SESSION_FILE}" <<EOF
COUNTRY=${country}
INTERFACE=${INTERFACE_NAME}
OS_INTERFACE=${os_interface}
CONFIG_PATH=${CONFIG_FILE}
TEMPLATE=wg0_${country}.conf
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  chmod 600 "${SESSION_FILE}"
}

generate_keys() {
  local private_key public_key
  private_key="$(wg genkey)"
  public_key="$(printf '%s' "${private_key}" | wg pubkey)"
  CLIENT_PRIVATE_KEY="${private_key}"
  CLIENT_PUBLIC_KEY="${public_key}"
  export CLIENT_PRIVATE_KEY CLIENT_PUBLIC_KEY
}

setup_client_keys() {
  require_command wg
  if [[ -n "${TEMPLATE_DATA[CLIENT_PRIVATE_KEY]:-}" ]]; then
    CLIENT_PRIVATE_KEY="$(echo -n "${TEMPLATE_DATA[CLIENT_PRIVATE_KEY]}" | tr -d '[:space:]')"
    if [[ -z "${CLIENT_PRIVATE_KEY}" ]]; then
      echo "error: CLIENT_PRIVATE_KEY provided but empty in template" >&2
      exit 1
    fi
    CLIENT_PUBLIC_KEY="$(printf '%s' "${CLIENT_PRIVATE_KEY}" | wg pubkey)"
    export CLIENT_PRIVATE_KEY CLIENT_PUBLIC_KEY
  else
    generate_keys
  fi
}

write_config() {
  {
    printf '[Interface]\n'
    printf 'PrivateKey = %s\n' "${CLIENT_PRIVATE_KEY}"
    printf 'Address = %s\n' "${TEMPLATE_DATA[CLIENT_ADDRESS]}"
    if [[ -n "${TEMPLATE_DATA[DNS]:-}" ]]; then
      printf 'DNS = %s\n' "${TEMPLATE_DATA[DNS]}"
    fi
    if [[ -n "${TEMPLATE_DATA[MTU]:-}" ]]; then
      printf 'MTU = %s\n' "${TEMPLATE_DATA[MTU]}"
    fi
    printf '\n[Peer]\n'
    printf 'PublicKey = %s\n' "${TEMPLATE_DATA[SERVER_PUBLIC_KEY]}"
    printf 'Endpoint = %s\n' "${TEMPLATE_DATA[SERVER_ENDPOINT]}"
    printf 'AllowedIPs = %s\n' "${TEMPLATE_DATA[ALLOWED_IPS]}"
    printf 'PersistentKeepalive = %s\n' "${TEMPLATE_DATA[PERSISTENT_KEEPALIVE]:-25}"
    if [[ -n "${TEMPLATE_DATA[PRESHARED_KEY]:-}" ]]; then
      printf 'PresharedKey = %s\n' "${TEMPLATE_DATA[PRESHARED_KEY]}"
    fi
    printf '\n'
  } >"${CONFIG_FILE}"

  chmod 600 "${CONFIG_FILE}"
}

ensure_no_active_session() {
  if [[ -f "${SESSION_FILE}" ]]; then
    if [[ -s "${SESSION_FILE}" ]]; then
      echo "error: existing session metadata found at ${SESSION_FILE}. Run 'cracked end' first." >&2
      exit 1
    fi
  fi
  if command -v wg >/dev/null 2>&1; then
    if wg show "${INTERFACE_NAME}" >/dev/null 2>&1; then
      echo "error: interface ${INTERFACE_NAME} already active. Run 'cracked end' before starting a new session." >&2
      exit 1
    fi
  fi
}

bring_interface_up() {
  local cmd=("wg-quick" "up" "${CONFIG_FILE}")
  if [[ "${EUID}" -ne 0 ]]; then
    cmd=("sudo" "wg-quick" "up" "${CONFIG_FILE}")
  fi

  "${cmd[@]}" | tee -a "${LOG_FILE}"
}

resolve_os_interface_name() {
  local name_file="/var/run/wireguard/${INTERFACE_NAME}.name"
  if [[ -f "${name_file}" ]]; then
    tr -d '[:space:]' < "${name_file}"
  else
    printf '%s\n' "${INTERFACE_NAME}"
  fi
}

main() {
  local country_override=""
  local dry_run="false"

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
        echo "error: unknown option $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  ensure_runtime
  ensure_no_active_session
  require_command wg-quick
  require_command torsocks
  require_command curl

  local selected_country
  selected_country="${country_override:-$(read_current_country)}"

  load_template "${selected_country}"
  setup_client_keys
  write_config

  if [[ "${dry_run}" == "true" ]]; then
    echo "Dry run: generated config at ${CONFIG_FILE}"
    cat "${CONFIG_FILE}"
    rm -f "${CONFIG_FILE}"
    exit 0
  fi

  request_privileged_access
  bring_interface_up
  local os_interface
  os_interface="$(resolve_os_interface_name)"
  write_session_file "${selected_country}" "${os_interface}"

  echo "CrackedVPN session started for country '${selected_country}'."
  echo "Use 'cracked status' to confirm connectivity and 'cracked end' to stop."
}

main "$@"
