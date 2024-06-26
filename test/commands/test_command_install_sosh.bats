#!/usr/bin/env bats

###
# Bats script validating orb command install_babashka.
#
#  INSTALL_DIR=~/bin ./test/command/test_command_install_sosh.bash
###

# detect ROOT_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
ROOT_DIR="$(cd "${TEST_DIR}/../.." || exit 1; pwd -P)"
# detect ROOT_DIR - end

setup() {
  source "${ROOT_DIR}/src/scripts/install_sosh.bash" # CMD_NAME
}

@test "Can be found in PATH and run" {
  $CMD_NAME
}

@test "File exists in INSTALL_DIR" {
  if [[ -v INSTALL_DIR && -z $INSTALL_DIR ]]; then
    echo "skip this test"
    echo "when user sets INSTALL_DIR= the script takes temp directory for installation"
  else
    find "${INSTALL_DIR}" -type f -name "${CMD_NAME}" -print -quit | grep -q .
  fi
}
