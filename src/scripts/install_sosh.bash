#!/bin/bash

###
# Script installs sosh.
#
# Example with defaults:
#
#   ./src/scripts/install_sosh.bash
#
# Examples with params specified:
#
#  VERSION=dev INSTALL_DIR=~/bin ./src/scripts/install_sosh.bash
#  VERSION=2469670269b79a4a47975fb8ae1ef68fc9dd09e0 INSTALL_DIR=~/bin ./src/scripts/install_sosh.bash
#
###

set -euo pipefail

DEBUG=${DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

NAME="sosh"
CMD_NAME="sosh"

# $1 - expected path
path_in_path() {
  local dir="$1"
  if echo "$PATH" | tr ':' '\n' | grep -qx "$dir"; then
    return 0 # true
  else
    return 1 # false
  fi
}

# $1 - version
# $2 - install directory (optional)
sosh_install() {
  printf "${GREEN}%s${NC}\n" "Installation started."
  local version=${1}
  local install_dir=${2:-"$(mktemp -d)"}
  # eval to resolve ~ in the path
  eval install_dir="${install_dir}"
  mkdir -p "${install_dir}"
  # install
  curl -s https://raw.githubusercontent.com/rynkowsg/sosh/${version}/main/src/pl/rynkowski/sosh.cljc -o "${install_dir}/${CMD_NAME}"
  chmod +x "${install_dir}/${CMD_NAME}"
  printf "${GREEN}%s${NC}\n" "${NAME} installed in ${install_dir}."
  # update PATH (if needed)
  if ! path_in_path "${install_dir}"; then
    export PATH="${install_dir}:${PATH}"
    printf "${GREEN}%s${NC}\n" "Updated PATH with ${install_dir}."
  fi
}

DEFAULT_INSTALL_DIR=~/bin
DEFAULT_VERSION="main"
# https://github.com/rynkowsg/sosh

detect_required_version() {
  # if version required specified take it
  # otherwise try parse from .tool-versions
  # or try default
  local version log_message
  if [ -n "${VERSION+x}" ] && [ -n "${VERSION}" ]; then
    version="${VERSION}"
    log_message="$(printf "%s\n" "detected the requested version specified: ${version}")"
  elif [ -f .tool-versions ]; then
    version=$(grep -m1 "^${ASDF_ENTRY_NAME} " .tool-versions | awk '{print $2}')
    log_message="$(printf "%s\n" "detected version defined in .tools-versions: ${version}")"
  else
    version="${DEFAULT_VERSION}"
    log_message="$(printf "${YELLOW}%s${NC}\n" "failed to detect desirable version, taking default: ${version}")"
  fi
  1>&2 printf "%s\n" "${log_message}"
  echo "${version}"
}

detect_install_dir() {
  local install_dir
  if [ -z "${INSTALL_DIR+x}" ]; then
    # INSTALL_DIR is not declared - take default value
    install_dir="${DEFAULT_INSTALL_DIR}"
  elif [ -z "${INSTALL_DIR}" ]; then
    # INSTALL_DIR is declared but empty" - use temporary directory
    install_dir="$(mktemp -d)}"
  else
    # INSTALL_DIR is declared and not empty - use the given value
    install_dir="${INSTALL_DIR}"
  fi
  echo "${install_dir}"
}

function main {
  local version install_dir
  version="$(detect_required_version)"
  install_dir="$(detect_install_dir)"
  sosh_install "${version}" "${install_dir}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@]
# It is not a problem. This part pf condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
