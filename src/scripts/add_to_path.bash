#!/bin/bash

###
# Script adds given path/paths to PATH (via BASH_ENV).
#
# Example with a single path:
#
#   PATH_TO_ADD=./bin ./src/scripts/add_to_path.bash
#
# Example with multiple paths:
#
#   PATHS_TO_ADD="./bin:./tools" ./src/scripts/add_to_path.bash
#
###

set -euo pipefail

DEBUG=${DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

PATH_TO_ADD="${PATH_TO_ADD:-""}"
PATHS_TO_ADD="${PATHS_TO_ADD:-""}"

function main {
  local paths=()
  [ -n "${PATH_TO_ADD}" ] && paths+=("${PATH_TO_ADD}")
  if [ -n "${PATHS_TO_ADD}" ]; then
    local split_paths
    IFS=':' read -ra split_paths <<<"${PATHS_TO_ADD}"
    paths+=("${split_paths[@]}")
  fi

  # nothing to add
  [ "${#paths[@]}" -eq 0 ] && return 0

  local p abs_paths=()
  for p in "${paths[@]}"; do
    abs_paths+=("$(cd "${p}" && pwd -P)")
  done

  local joined_paths
  joined_paths="$(IFS=':'; echo "${abs_paths[*]}")"
  echo "export PATH=\"${joined_paths}:\${PATH}\"" >> "${BASH_ENV}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
