#!/bin/bash

###
# Script installs yq.
#
# Example with defaults:
#
#   ./src/scripts/install_yq.bash
#
# Example with params specified:
#
#  VERSION=4.35.2 INSTALL_DIR=~/bin ./src/scripts/install_yq.bash
#
###

set -euo pipefail

DEBUG=${DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

NAME="yq"
ASDF_ENTRY_NAME="yq"
CMD_NAME="yq"

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
yq_install() {
  printf "${GREEN}%s${NC}\n" "Installation started."
  local version=${1}
  local install_dir=${2:-"$(mktemp -d)"}
  # eval to resolve ~ in the path
  eval install_dir="${install_dir}"
  mkdir -p "${install_dir}"
  # install yq
  mkdir -p "${install_dir}"
  curl -L -o "${install_dir}/yq" "https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_386"
  chmod +x "${install_dir}/yq"
  name=$([ "${NAME}" == "${CMD_NAME}" ] && echo "${NAME}" || echo "${NAME} (${CMD_NAME})")
  printf "${GREEN}%s${NC}\n" "${name} installed in ${install_dir}."
  # update PATH (if needed)
  if ! path_in_path "${install_dir}"; then
    export PATH="${install_dir}:${PATH}"
    printf "${GREEN}%s${NC}\n" "Updated PATH with ${install_dir}."
  fi
}

# $1 - command name
is_installed() {
  local command_name="$1"
  if command -v "${command_name}" >/dev/null; then
    return 0 # true
  else
    return 1 # false
  fi
}

yq_version() {
  # example versions:
  # yq (https://github.com/mikefarah/yq/) version 4.23.1
  # yq (https://github.com/mikefarah/yq/) version v4.35.2
  $CMD_NAME --version | sed -n 's/.*version v\?\([0-9.]*\).*/\1/p'
}

# $1 - expected version
yq_is_version() {
  local expected_ver="$1"
  if [ "$(yq_version)" = "${expected_ver}" ]; then
    return 0 # true
  else
    return 1 # false
  fi
}

#################################################
#                     MAIN
#################################################
#
# Expects environment variables below:
# - INSTALL_DIR - installation directory
# - VERSION - required version
#
# Otherwise, defaults are taken:

DEFAULT_INSTALL_DIR=~/bin
DEFAULT_VERSION="4.40.5"
# https://github.com/mikefarah/yq/releases/

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
  if ! is_installed "${CMD_NAME}"; then
    printf "${YELLOW}%s${NC}\n" "${NAME} is not yet installed."
    yq_install "${version}" "${install_dir}"
  elif ! yq_is_version "${version}"; then
    printf "${YELLOW}%s${NC}\n" "The installed version of ${NAME} ($(yq_version)) is different then expected (${version})."
    yq_install "${version}" "${install_dir}"
  else
    printf "${YELLOW}%s${NC}\n" "${NAME} is already installed in $(which yq)."
  fi
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@]
# It is not a problem. This part pf condition is only to prevent `unbound variable` error.if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
