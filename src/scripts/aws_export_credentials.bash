#!/bin/bash

###
# Exports an AWS profile's credentials to BASH_ENV via
# `aws configure export-credentials`.
#
# Clears any AWS credentials previously written to BASH_ENV, then exports
# PROFILE's credentials.
#
# Example:
#
#   PARAM_PROFILE=forge/deployer ./src/scripts/aws_export_credentials.bash
#
###

set -euo pipefail

DEBUG=${PARAM_DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

PROFILE="${PARAM_PROFILE:-""}"

function clear_credentials {
  # aws-cli orb env vars
  sed -i '/^export AWS_CLI_STR_ACCESS_KEY_ID=/d' "${BASH_ENV}"
  sed -i '/^export AWS_CLI_STR_SECRET_ACCESS_KEY=/d' "${BASH_ENV}"
  sed -i '/^export AWS_CLI_STR_SESSION_TOKEN=/d' "${BASH_ENV}"
  # current role secrets
  sed -i '/^export AWS_ACCESS_KEY_ID=/d' "${BASH_ENV}"
  sed -i '/^export AWS_SECRET_ACCESS_KEY=/d' "${BASH_ENV}"
  sed -i '/^export AWS_SESSION_TOKEN=/d' "${BASH_ENV}"
}

function main {
  if [ -z "${PROFILE}" ]; then
    echo "ERROR: PROFILE is required." >&2
    return 1
  fi

  clear_credentials

  aws configure export-credentials --profile "${PROFILE}" --format env >> "${BASH_ENV}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
