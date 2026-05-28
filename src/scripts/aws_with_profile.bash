#!/bin/bash

###
# Runs a command with credentials from an AWS profile.
#
# Materializes PROFILE's credentials into the current shell via
# `aws configure export-credentials`, then runs COMMAND. Nothing is written to
# BASH_ENV, so the credentials are scoped to this single step.
#
# Example:
#
#   PARAM_PROFILE=forge/deployer \
#     PARAM_COMMAND='aws sts get-caller-identity' \
#     ./src/scripts/aws_with_profile.bash
#
###

set -euo pipefail

DEBUG=${PARAM_DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

PROFILE="${PARAM_PROFILE:-""}"
COMMAND="${PARAM_COMMAND:-""}"

function load_credentials {
  # capture first so a failing `aws` is caught by `set -e`
  # (a bare `eval "$(aws ...)"` would mask its exit code)
  local env_out
  env_out="$(aws configure export-credentials --profile "${PROFILE}" --format env)"
  # `--format env` output already contains `export` statements
  eval "${env_out}"
}

function main {
  if [ -z "${PROFILE}" ]; then echo "ERROR: PROFILE is required." >&2; return 1; fi
  if [ -z "${COMMAND}" ]; then echo "ERROR: COMMAND is required." >&2; return 1; fi

  load_credentials

  # run the wrapped command with the credentials in scope; do not impose
  # nounset on it (matches CircleCI's default shell options)
  set +u
  eval "${COMMAND}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
