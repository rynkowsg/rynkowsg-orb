#!/bin/bash

###
# Runs a command with credentials from an assumed AWS role.
#
# Assumes ROLE_ARN via `aws sts assume-role`, exports the temporary
# credentials into the current shell, then runs COMMAND. Nothing is written to
# BASH_ENV, so the credentials are scoped to this single step.
#
# Example:
#
#   PARAM_PROFILE=identity/ci \
#     PARAM_ROLE_ARN=arn:aws:iam::123456789012:role/ci/my-role \
#     PARAM_ROLE_SESSION_NAME=my-job \
#     PARAM_COMMAND='aws sts get-caller-identity' \
#     ./src/scripts/aws_with_assumed_role.bash
#
###

set -euo pipefail

DEBUG=${PARAM_DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

PROFILE="${PARAM_PROFILE:-""}"
ROLE_ARN="${PARAM_ROLE_ARN:-""}"
ROLE_SESSION_NAME="${PARAM_ROLE_SESSION_NAME:-""}"
COMMAND="${PARAM_COMMAND:-""}"

function assume_role {
  local creds profile_args=()
  [ -n "${PROFILE}" ] && profile_args=(--profile "${PROFILE}")
  creds="$(aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "${ROLE_SESSION_NAME}" \
    "${profile_args[@]}" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)"
  IFS=$'\t' read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< "${creds}"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

function main {
  if [ -z "${ROLE_ARN}" ]; then echo "ERROR: ROLE_ARN is required." >&2; return 1; fi
  if [ -z "${ROLE_SESSION_NAME}" ]; then echo "ERROR: ROLE_SESSION_NAME is required." >&2; return 1; fi
  if [ -z "${COMMAND}" ]; then echo "ERROR: COMMAND is required." >&2; return 1; fi

  assume_role

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
