#!/usr/bin/env bats

###
# Bats script validating orb command install_sosh.
#
# The orb command has to run first. These tests only check what it left behind.
# sosh does not report a version, so there is nothing here to compare VERSION to.
#
#  INSTALL_DIR=~/bin ./test/commands/test_command_install_sosh.bats
#
###

# detect ROOT_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
ROOT_DIR="$(cd "${TEST_DIR}/../.." || exit 1; pwd -P)"
# detect ROOT_DIR - end

setup() {
  source "${ROOT_DIR}/src/scripts/install_sosh.bash" # CMD_NAME
  # An empty INSTALL_DIR tells the script to install into a temp directory, and
  # the tests have no way to learn which one it picked.
  [ -n "${INSTALL_DIR-}" ] || skip "INSTALL_DIR is empty, so the script installed into a temp directory"
  INSTALLED="${INSTALL_DIR%/}/${CMD_NAME}"
}

@test "the orb left an executable in INSTALL_DIR" {
  [ -x "${INSTALLED}" ]
}

# sosh is a babashka script, so this also says that bb and the JVM it needs are
# in working order.
@test "the installed script runs" {
  run "${INSTALLED}"
  [ "${status}" -eq 0 ]
}

# Without this the test above could pass on a script that came from somewhere
# else on PATH, which is what any other installer on the machine gives you.
@test "the installed script is the one PATH resolves" {
  [ "$(command -v "${CMD_NAME}")" = "${INSTALLED}" ]
}
