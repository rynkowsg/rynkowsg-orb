#!/bin/bash

GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
NC=$(printf '\033[0m')

# by default show DEBUG messages
DEBUG="${DEBUG-"true"}"

# $1 - version
function main {
  # debug messages
  if [ "${DEBUG}" = "true" ]; then
    set -x
    whereis yq
    which yq
    echo "${PATH}"
  fi
  # load version required
  local version=${1-"unset"}
  if [ "${version}" = "unset" ]; then
    printf "${RED}%s${NC}\n" "Expected version not set. The test can not be run."
    exit 1
  fi
  # do checks
  if yq --version 2>&1 | grep -q "${version}"; then
    printf "${GREEN}%s${NC}\n" "Expected version detected."
  else
    printf "${RED}%s${NC}\n" "Expected version not found."
    exit 1
  fi
}

main "$@"
