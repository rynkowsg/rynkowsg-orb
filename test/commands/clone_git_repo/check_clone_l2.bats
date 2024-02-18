#!/usr/bin/env bats

###
# Bats script checking whether l2 repo is checked out correctly
#
#  REPO_DIR=/tmp/repo ./test/commands/clone_git_repo/check_clone_l1.bats
#
###

@test "check_clone_l2: Content of regular-file.txt is correct" {
  content="$(cat "${REPO_DIR}/regular-file.txt")"
  expected_value="This is regular file."
  [ "${expected_value}" == "${content}" ]
}