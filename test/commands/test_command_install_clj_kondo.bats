#!/usr/bin/env bats

###
# Bats script validating orb command install_clj_kondo.
#
# The orb command has to run first. These tests only check what it left behind.
#
#  VERSION=2026.08.04 INSTALL_DIR=~/bin ./test/commands/test_command_install_clj_kondo.bats
#
###

# detect ROOT_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
ROOT_DIR="$(cd "${TEST_DIR}/../.." || exit 1; pwd -P)"
# detect ROOT_DIR - end

setup() {
  source "${ROOT_DIR}/src/scripts/install_clj_kondo.bash" # CMD_NAME
  # An empty INSTALL_DIR tells the script to install into a temp directory, and
  # the tests have no way to learn which one it picked.
  [ -n "${INSTALL_DIR-}" ] || skip "INSTALL_DIR is empty, so the script installed into a temp directory"
  [ -n "${VERSION-}" ] || skip "VERSION is empty, so there is nothing to compare against"
  INSTALLED="${INSTALL_DIR%/}/${CMD_NAME}"
}

@test "the orb left an executable in INSTALL_DIR" {
  [ -x "${INSTALLED}" ]
}

@test "the installed binary reports the expected version" {
  run "${INSTALLED}" --version
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"v${VERSION}"* ]]
}

# Without this the version test above could pass on a binary that came from
# somewhere else on PATH, which is what any other installer on the machine gives
# you.
@test "the installed binary is the one PATH resolves" {
  [ "$(command -v "${CMD_NAME}")" = "${INSTALLED}" ]
}
