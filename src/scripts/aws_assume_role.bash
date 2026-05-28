#!/bin/bash

###
# Assumes an AWS role via `aws sts assume-role` and writes the resulting
# credentials to BASH_ENV.
#
# Clears any AWS credentials previously written to BASH_ENV, then obtains
# credentials for ROLE_ARN (ROLE_SESSION_NAME is the session name; PROFILE,
# if set, is the source profile). When PROFILE is empty, --profile is omitted.
#
# Example:
#
#   PROFILE=identity/ci \
#     ROLE_ARN=arn:aws:iam::123456789012:role/ci/my-role \
#     ROLE_SESSION_NAME=my-job \
#     ./src/scripts/aws_assume_role.bash
#
###

set -euo pipefail

DEBUG=${PARAM_DEBUG:-0}
[ "${DEBUG}" = 1 ] && set -x

PROFILE="${PARAM_PROFILE:-""}"
ROLE_ARN="${PARAM_ROLE_ARN:-""}"
ROLE_SESSION_NAME="${PARAM_ROLE_SESSION_NAME:-""}"

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
  if [ -z "${ROLE_ARN}" ]; then
    echo "ERROR: ROLE_ARN is required." >&2
    return 1
  fi
  if [ -z "${ROLE_SESSION_NAME}" ]; then
    echo "ERROR: ROLE_SESSION_NAME is required." >&2
    return 1
  fi

  clear_credentials

  local creds key secret token profile_args=()
  [ -n "${PROFILE}" ] && profile_args=(--profile "${PROFILE}")
  creds="$(aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "${ROLE_SESSION_NAME}" \
    "${profile_args[@]}" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)"
  IFS=$'\t' read -r key secret token <<< "${creds}"
  {
    echo "export AWS_ACCESS_KEY_ID=\"${key}\""
    echo "export AWS_SECRET_ACCESS_KEY=\"${secret}\""
    echo "export AWS_SESSION_TOKEN=\"${token}\""
  } >> "${BASH_ENV}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
