#!/usr/bin/env bats

###
# Bats script validating orb command install_babashka.
#
#  ./test/command/test_command_clone_git_repo.bats
#
###

@test "Show DEST_DIR content" {
  ls "${DEST_DIR}"
}
