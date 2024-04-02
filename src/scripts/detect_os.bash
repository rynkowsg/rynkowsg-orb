#!/bin/bash

case $(uname) in
  [Ll]inux*)
    if [ -f /.dockerenv ]; then
      echo 'export EXECUTOR=docker' >>"${BASH_ENV}"
    else
      echo 'export EXECUTOR=linux' >>"${BASH_ENV}"
    fi
    ;;
  [Dd]arwin*)
    echo 'export EXECUTOR=macos' >>"${BASH_ENV}"
    ;;
  msys* | MSYS* | nt | win*)
    echo 'export EXECUTOR=windows' >>"${BASH_ENV}"
    ;;
esac
# shellcheck disable=SC1090
source "${BASH_ENV}"

# Source:
# https://discuss.circleci.com/t/circleci-os-detect-replacement/46639/2
#
# Similar
# https://github.com/CircleCI-Archived/os-detect-orb/blob/master/src/commands/init.yml#L7
