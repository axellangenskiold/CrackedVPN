#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/.runtime"
SESSION_FILE="${STATE_DIR}/session.env"
LOG_FILE="${STATE_DIR}/end.log"
readonly SCRIPT_DIR PROJECT_ROOT STATE_DIR SESSION_FILE LOG_FILE

usage() {
  cat <<'EOF'
Usage: end.sh [--dry-run]

Tear down the active CrackedVPN WireGuard session.
The command looks for session metadata under .runtime/session.env.

Options:
  --dry-run   Show planned steps without running wg-quick
  -h, --help  Show this help message
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: required command '${cmd}' not found in PATH" >&2
    exit 1
  fi
}

load_session() {
  if [[ ! -f "${SESSION_FILE}" ]]; then
    echo "No active CrackedVPN session detected." >&2
    exit 1
  fi

  declare -gA SESSION=()
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

  if [[ -z "${SESSION[CONFIG_PATH]:-}" ]]; then
    echo "error: session metadata is missing CONFIG_PATH" >&2
    exit 1
  fi
}

bring_interface_down() {
  local config_path="${SESSION[CONFIG_PATH]}"
  local cmd=("wg-quick" "down" "${config_path}")
  if [[ "${EUID}" -ne 0 ]]; then
    require_command sudo
    cmd=("sudo" "-n" "wg-quick" "down" "${config_path}")
  fi
  "${cmd[@]}" | tee -a "${LOG_FILE}"
}

cleanup_files() {
  local config_path="${SESSION[CONFIG_PATH]}"
  rm -f "${config_path}"
  rm -f "${SESSION_FILE}"
}

main() {
  local dry_run="false"
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
        echo "error: unknown option $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  load_session
  require_command wg-quick

  if [[ "${dry_run}" == "true" ]]; then
    echo "Dry run: would run 'wg-quick down ${SESSION[CONFIG_PATH]}' and remove session files."
    exit 0
  fi

  bring_interface_down
  cleanup_files
  echo "CrackedVPN session ended."
}

main "$@"
