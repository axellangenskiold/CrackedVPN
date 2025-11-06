#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT

usage() {
  cat <<'EOF'
add_to_path.sh [--dry-run]

Append this repository to your shell PATH so the `cracked` CLI can be run
from any directory.

Options:
  --dry-run  Show the actions that would be taken without modifying files.
  -h,--help  Show this message.
EOF
}

detect_shell_profile() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  case "${shell_name}" in
    zsh)
      PROFILE_PATH="${HOME}/.zshrc"
      PROFILE_LINE="export PATH=\"${REPO_ROOT}:\$PATH\""
      ;;
    bash)
      if [[ -f "${HOME}/.bashrc" ]]; then
        PROFILE_PATH="${HOME}/.bashrc"
      elif [[ -f "${HOME}/.bash_profile" ]]; then
        PROFILE_PATH="${HOME}/.bash_profile"
      else
        PROFILE_PATH="${HOME}/.profile"
      fi
      PROFILE_LINE="export PATH=\"${REPO_ROOT}:\$PATH\""
      ;;
    fish)
      PROFILE_PATH="${HOME}/.config/fish/config.fish"
      PROFILE_LINE="set -Ua fish_user_paths \"${REPO_ROOT}\""
      mkdir -p "$(dirname "${PROFILE_PATH}")"
      ;;
    *)
      PROFILE_PATH="${HOME}/.profile"
      PROFILE_LINE="export PATH=\"${REPO_ROOT}:\$PATH\""
      ;;
  esac
}

append_line_if_missing() {
  local file="$1"
  local line="$2"

  if [[ ! -f "${file}" ]]; then
    touch "${file}"
  fi

  if grep -Fq "${REPO_ROOT}" "${file}"; then
    echo "Path already present in ${file}."
    return
  fi

  printf '\n%s\n' "${line}" >>"${file}"
  echo "Added PATH entry to ${file}."
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

  detect_shell_profile

  if [[ "${dry_run}" == "true" ]]; then
    echo "[dry-run] would append the following to ${PROFILE_PATH}:"
    echo "  ${PROFILE_LINE}"
    exit 0
  fi

  append_line_if_missing "${PROFILE_PATH}" "${PROFILE_LINE}"
  echo "Reload your shell (e.g., 'source ${PROFILE_PATH}') for the change to take effect."
}

main "$@"
