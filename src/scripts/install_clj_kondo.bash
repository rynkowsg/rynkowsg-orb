#!/bin/bash

###
# Script installs clj-kondo.
#
# Example with defaults:
#
#   ./src/scripts/install_clj-kondo.bash
#
# Example with params specified:
#
#  VERSION=2023.10.20 INSTALL_DIR=~/bin ./src/scripts/install_clj-kondo.bash
#
###

set -euo pipefail

DEBUG=${DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

NAME="clj-kondo"
ASDF_ENTRY_NAME="clj-kondo"
CMD_NAME="clj-kondo"

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
clj_kondo_install() {
  printf "${GREEN}%s${NC}\n" "Installation started."
  local version=${1}
  local install_dir=${2:-"$(mktemp -d)"}
  # eval to resolve ~ in the path
  eval install_dir="${install_dir}"
  mkdir -p "${install_dir}"
  # install clj-kondo
  tmp_installer_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf \"${tmp_installer_dir}\"" EXIT
  local installer="${tmp_installer_dir}/install"
  curl -sL https://raw.githubusercontent.com/clj-kondo/clj-kondo/master/script/install-clj-kondo -o "${installer}"
  chmod +x "${installer}"
  if [ -n "${version}" ]; then
    "${installer}" --dir "${install_dir}" --version "${version}"
  else
    bash "${installer}" --dir "${install_dir}"
  fi
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

clj_kondo_version() {
  # example version:
  # clj-kondo v2023.12.15
  $CMD_NAME --version | sed -n 's/clj-kondo v\?\([0-9.]*\).*/\1/p'
}

# $1 - expected version
clj_kondo_is_version() {
  local expected_ver="$1"
  if [ "$(clj_kondo_version)" = "${expected_ver}" ]; then
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
DEFAULT_VERSION="2023.10.20"
# https://github.com/clj-kondo/clj-kondo/releases

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
    clj_kondo_install "${version}" "${install_dir}"
  elif ! clj_kondo_is_version "${version}"; then
    printf "${YELLOW}%s${NC}\n" "The installed version of ${NAME} ($(clj_kondo_version)) is different then expected (${version})."
    clj_kondo_install "${install_dir}"
  else
    printf "${YELLOW}%s${NC}\n" "${NAME} is already installed in $(which ${CMD_NAME})."
  fi
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@]
# It is not a problem. This part pf condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
