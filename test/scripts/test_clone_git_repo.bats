#!/usr/bin/env bats

# detect ROOT_DIR - BEGIN
TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" || exit 1; pwd -P)"
ROOT_DIR="$(cd "${TEST_DIR}/../.." || exit 1; pwd -P)"
# detect ROOT_DIR - end

setup() {
  local dest_dir
  dest_dir="$(mktemp -d -t "test-clone-$(date +%Y%m%d_%H%M%S)-XXX")"
  export DEST_DIR="${dest_dir}"
}

teardown() {
  rm -rf "${DEST_DIR}"
}

@test "Try to clone lfs" {
  export REPO_URL="https://github.com/rynkowsg/rynkowsg-orb-sample-repo-l2.git"
  export REPO_BRANCH="master-lfs"
  export REPO_SHA1="0ec9a71496402ad9383760f0e293efa6f7f95fad"
  "${ROOT_DIR}/src/scripts/clone_git_repo.bash"

  # check directory is not empty
  [ "$(ls -A "${dest_dir}")" ]
}

# DEST_DIR="$(mktemp -d -t "test-clone-$(date +%Y%m%d_%H%M%S)-XXX")" REPO_URL="https://github.com/rynkowsg/rynkowsg-orb-sample-repo-l2.git" REPO_BRANCH="master" REPO_SHA1=64451475acc0db9d4cfc06b6ff1fd0dfc4c40939 DEBUG=0 ./src/scripts/clone_git_repo.bash
# DEST_DIR="$(mktemp -d -t "test-clone-$(date +%Y%m%d_%H%M%S)-XXX")" REPO_URL="https://github.com/rynkowsg/rynkowsg-orb-sample-repo-l2.git" REPO_BRANCH="master-lfs" REPO_SHA1=0ec9a71496402ad9383760f0e293efa6f7f95fad DEBUG=0 ./src/scripts/clone_git_repo.bash
