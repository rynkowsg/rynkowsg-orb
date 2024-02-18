#!/usr/bin/env bats

###
# Bats script checking whether l0 repo is checked out correctly
#
#  REPO_DIR=/tmp/repo ./test/commands/clone_git_repo/check_clone_l0.bats
#
###

@test "check_clone_l0: Content of regular-file.txt is correct" {
  content="$(cat "${REPO_DIR}/regular-file.txt")"
  expected_value="This is regular file."
  [ "${expected_value}" == "${content}" ]
}

@test "check_clone_l0: Content of sample-repo-l1/regular-file.txt is correct" {
  content="$(cat "${REPO_DIR}/sample-repo-l1/regular-file.txt")"
  expected_value="This is regular file."
  [ "${expected_value}" == "${content}" ]
}

@test "check_clone_l0: Content of sample-repo-l1/sample-repo-l2/regular-file.txt is correct" {
  content="$(cat "${REPO_DIR}/sample-repo-l1/sample-repo-l2/regular-file.txt")"
  expected_value="This is regular file."
  [ "${expected_value}" == "${content}" ]
}
