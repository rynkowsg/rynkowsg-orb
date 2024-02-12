#!/bin/bash

###
# Script installs yq.
#
# Example with defaults:
#
#   ./projects/ci/scripts/install_yq.bash
#
# Example with params specified:
#
#  YQ_VERSION=4.35.2 YQ_INSTALL_DIR=~/bin ./projects/ci/scripts/install_yq.bash
#
###

set -euo pipefail

DEBUG=${DEBUG:-false}

GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

path_in_path() {
  local dir="$1"
  if echo "$PATH" | tr ':' '\n' | grep -qx "$dir"; then
      return 0 # true
  else
      return 1 # false
  fi
}

# $1 - install directory
yq_install() {
  printf "${GREEN}%s${NC}\n" "Installation started."
  local version=${1}
  local install_dir=${2:-"$(mktemp -d)"}
  # eval to resolve ~ in the path
  eval install_dir="${install_dir}"
  # install yq
  mkdir -p "${install_dir}"
  curl -L -o "${install_dir}/yq" "https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_386"
  chmod +x "${install_dir}/yq"
  ls -al
  ls -al "${install_dir}"
  printf "${GREEN}%s${NC}\n" "yq installed in ${install_dir}."
  # update PATH (if needed)
  if ! path_in_path "${install_dir}"; then
    export PATH="${install_dir}:${PATH}"
    printf "${GREEN}%s${NC}\n" "Updated PATH with ${install_dir}."
  fi
}

yq_is_installed() {
  if command -v yq > /dev/null; then
    return 0 # true
  else
    return 1 # false
  fi
}

yq_version() {
  # example versions:
  # yq (https://github.com/mikefarah/yq/) version 4.23.1
  # yq (https://github.com/mikefarah/yq/) version v4.35.2
  yq --version | sed -n 's/.*version v\?\([0-9.]*\).*/\1/p'
}

# $1 - expected version
yq_is_version() {
  local expected_ver="$1"
  if [ "$(yq_version)" = "${expected_ver}" ]; then
    return 0; # true
  else
    return 1; # false
  fi
}

#################################################
#                     MAIN
#################################################
#
# Expects environment variables below:
# - YQ_INSTALL_DIR - installation directory
# - YQ_VERSION - required version
#
# Otherwise, defaults are taken:

DEFAULT_YQ_INSTALL_DIR=~/bin
DEFAULT_YQ_VERSION="4.40.5"
# https://github.com/mikefarah/yq/releases/

detect_required_version() {
  # if version required specified take it
  # otherwise try parse from .tool-versions
  # or try default
  local version
  if [ -n "${YQ_VERSION+x}" ] && [ -n "${YQ_VERSION}" ] ; then
    version="${YQ_VERSION}"
  elif [ -f .tool-versions ]; then
    version=$(grep -m1 "^yq " .tool-versions | awk '{print $2}')
  else
    version="${DEFAULT_YQ_VERSION}"
  fi
  echo "${version}"
}

detect_install_dir() {
  local install_dir
  if [ -n "${YQ_INSTALL_DIR}" ] ; then
    install_dir="${YQ_INSTALL_DIR}"
  else
    install_dir="${DEFAULT_YQ_INSTALL_DIR}"
  fi
  echo "${install_dir}"
}

function main {
  if [ "$DEBUG" = "true" ]; then
    set -x
  fi
  local version install_dir
  version="$(detect_required_version)"
  install_dir="$(detect_install_dir)"
  if ! yq_is_installed; then
    printf "${YELLOW}%s${NC}\n" "yq is not yet installed."
    yq_install "${version}" "${install_dir}"
  elif ! yq_is_version "${version}"; then
    printf "${YELLOW}%s${NC}\n" "The installed version of yq ($(yq_version)) is different then expected (${version})."
    yq_install "${version}" "${install_dir}"
  else
    printf "${YELLOW}%s${NC}\n" "yq is already installed in $(which yq)."
  fi
}

main "$@"
