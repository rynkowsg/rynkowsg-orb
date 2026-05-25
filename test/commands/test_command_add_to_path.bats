#!/usr/bin/env bats

###
# Bats script validating orb command add_to_path.
#
#  ./test/commands/test_command_add_to_path.bats
#
###

# detect ROOT_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
ROOT_DIR="$(cd "${TEST_DIR}/../.." || exit 1; pwd -P)"
# detect ROOT_DIR - end

setup() {
  source "${ROOT_DIR}/src/scripts/add_to_path.bash" # main
  BASH_ENV="$(mktemp)"
}

teardown() {
  rm -f "${BASH_ENV}"
}

@test "single path is prepended to PATH" {
  local dir abs
  dir="$(mktemp -d)"
  abs="$(cd "${dir}" && pwd -P)"
  PATH_TO_ADD="${dir}" PATHS_TO_ADD="" main
  grep -qF "export PATH=\"${abs}:\${PATH}\"" "${BASH_ENV}"
}

@test "multiple paths are prepended in order, joined with ':'" {
  local d1 d2 a1 a2
  d1="$(mktemp -d)"
  d2="$(mktemp -d)"
  a1="$(cd "${d1}" && pwd -P)"
  a2="$(cd "${d2}" && pwd -P)"
  PATH_TO_ADD="" PATHS_TO_ADD="${d1}:${d2}" main
  grep -qF "export PATH=\"${a1}:${a2}:\${PATH}\"" "${BASH_ENV}"
}

@test "relative path is resolved to an absolute path" {
  local base abs
  base="$(mktemp -d)"
  mkdir -p "${base}/bin"
  abs="$(cd "${base}/bin" && pwd -P)"
  cd "${base}"
  PATH_TO_ADD="bin" PATHS_TO_ADD="" main
  grep -qF "export PATH=\"${abs}:\${PATH}\"" "${BASH_ENV}"
}

@test "no paths given is a no-op" {
  PATH_TO_ADD="" PATHS_TO_ADD="" main
  [ ! -s "${BASH_ENV}" ]
}
