#!/usr/bin/env bash

# set +e # Do not exit on error
set -e # Exit on error
set +u # Allow unset variables
# set -u # Exit on unset variable
# set +o pipefail # Disable pipefail
set -o pipefail # Enable pipefail

nc="\e[0m" # Unset styles
red="\e[31m" # Red foreground

error() {
  >&2 echo -e " ${red}×${nc} ${*}"
}

# shellcheck disable=SC2120
die() {
  if [ "${#}" -gt 0 ]; then
    error "${*}"
  fi

  exit 1
}

main() {
  echo "This is a template."
}

main "$@"
