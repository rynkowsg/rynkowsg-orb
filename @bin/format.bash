#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# Validates/corrects format
#
# Example:
#
#  - check:  @bin/format.bash check
#  - apply:  @bin/format.bash apply
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
SHELL_GR_DIR="${SHELL_GR_DIR:-"${ROOT_DIR}/.github_deps/rynkowsg/shell-gr@v0.2.2"}"
# shellcheck source=.github_deps/rynkowsg/shell-gr@v0.2.2/lib/tool/format.bash
source "${SHELL_GR_DIR}/lib/tool/format.bash" # format_with_env

main() {
  local format_cmd_type="${1:-"apply"}"
  local error=0
  format_with_env "${format_cmd_type}" bash \
    < <(
      find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
        | grep -v -E '(.github_deps|/gen/)' \
        | sort
    ) \
    || ((error += $?))
  format_with_env "${format_cmd_type}" bats < <(find "${ROOT_DIR}" -type f -name '*.bats' | sort) || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main "$@"
