#!/bin/bash
# source of ././src/scripts/install_asdf.bash - BEGIN
###
# Script installs asdf.
#
# Execute:
#    DEBUG=1 VERSION=0.14.0 INSTALL_DIR=tmp-here ./src/scripts/gen/install_asdf.bash
###

########################################################################################################################
## common library (shared)
########################################################################################################################

# source of ././src/scripts/./internal/color.bash - BEGIN
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')
# source of ././src/scripts/./internal/color.bash - END

# source of ././src/scripts/./internal/common.bash - BEGIN
HOME="${HOME:-"$(eval echo ~)"}"

# $1 - path
normalized_path() {
  local path="${1}"
  eval path="${path}"
  # this allows to resolve ~
  echo "${path}"
}

# $1 - path
absolute_path() {
  local path="${1}"
  local normalized
  normalized="$(normalized_path "${path}")"
  cd "${normalized}" || exit 1
  pwd -P
}
# source of ././src/scripts/./internal/common.bash - END

# source of ././src/scripts/./internal/install_common.bash - BEGIN
# $1 - expected path
path_in_path() {
  local dir="$1"
  if echo "${PATH}" | tr ':' '\n' | grep -qx "${dir}"; then
    return 0 # true
  else
    return 1 # false
  fi
}

# $1 - command name
is_installed() {
  local command_name="$1"
  if command -v "${command_name}" >/dev/null; then
    return 0 # true
  else
    return 1 # false
  fi
}
# source of ././src/scripts/./internal/install_common.bash - END


########################################################################################################################
## asdf-orb-specific
########################################################################################################################
# in this section I we can convert orb input to the script intput

DEBUG=${PARAM_DEBUG:-${DEBUG:-0}}
if [ "${DEBUG}" = 1 ]; then
  set -x
fi

VERSION="${PARAM_VERSION:-${VERSION:-}}"
INSTALL_DIR="$(normalized_path "${PARAM_INSTALL_DIR:-${INSTALL_DIR:-}}")"

# source of ././src/scripts/./internal/asdf_orb_common_start.bash - BEGIN
echo "BASH_ENV=${BASH_ENV:-}"
echo "CIRCLECI=${CIRCLECI:-}"
echo "DEBUG=${DEBUG:-}"
# source of ././src/scripts/./internal/asdf_orb_common_start.bash - END

# source of ././src/scripts/./internal/asdf_orb_common_input.bash - BEGIN
ASDF_DIR="${PARAM_ASDF_DIR:-${ASDF_DIR:-~/.asdf}}"
eval ASDF_DIR="${ASDF_DIR}"
# eval to resolve possible ~
# source of ././src/scripts/./internal/asdf_orb_common_input.bash - END


########################################################################################################################
## asdf-specific (shared)
########################################################################################################################

# source of ././src/scripts/./internal/asdf_common.bash - BEGIN
NAME="asdf"
CMD_NAME="${NAME}"

ASDF_REPO="${ASDF_REPO:-"https://github.com/asdf-vm/asdf.git"}"

ASDF_VERSION_REGEX="[0-9]+\.[0-9]+\.[0-9]+"

# $1 - version
asdf_validate_version() {
  local version="$1"
  local version_regex="^${ASDF_VERSION_REGEX}$"
  if [[ $version =~ $version_regex ]]; then
    : # version matches regex
  elif [ -z "${version}" ]; then
    : # version is empty
  else
    printf "${RED}%s${NC}\n" "The version ${version} is invalid."
    exit 1
  fi
}

# $1 - install dir
asdf_validate_install_dir() {
  local install_dir="${1}"
  if [ -d "${install_dir}" ]; then
    :
    # todo: check whether is empty
  else
    if [ -z "${install_dir}" ]; then
      printf "${RED}%s${NC}\n" "The install_dir can't be empty."
      exit 1
    fi
  fi
}

asdf_version() {
  asdf --version | sed "s|v\(${ASDF_VERSION_REGEX}\)-.*|\1|"
}

# $1 - expected version
asdf_is_version() {
  local expected_ver="$1"
  if [ "$(asdf_version)" = "${expected_ver}" ]; then
    return 0; # true
  else
    return 1; # false
  fi
}

asdf_is_installed() {
  is_installed "${CMD_NAME}"
}

# $1 - install dir
asdf_determine_install_dir() {
  local install_dir_default="${HOME}/.asdf"
  local install_dir="${1:-"${install_dir_default}"}"
  echo "${install_dir}"
}

# $1 - version
# $2 - install_dir
asdf_install() {
  local version="${1}"
  local install_dir_default="${HOME}/.asdf"
  local install_dir="${2}"
  asdf_validate_version "${version}"
  asdf_validate_install_dir "${install_dir}"
  mkdir -p "${install_dir}"
  local install_dir_absolute
  install_dir_absolute="$(absolute_path "${install_dir}")"
  # Installation by cloning repo. More:
  # https://asdf-vm.com/guide/getting-started.html#_3-install-asdf
  local git_params=()
  git_params+=(-C "${HOME}")
  git_params+=(-c advice.detachedHead=false)
  local git_clone_params=()
  if [ -n "${version}" ]; then
      git_clone_params+=(--branch "v${version}")
  fi
  git_clone_params+=(--depth 1)
  git "${git_params[@]}" clone "${git_clone_params[@]}" "${ASDF_REPO}" "${install_dir_absolute}"
}
# source of ././src/scripts/./internal/asdf_common.bash - END


########################################################################################################################
## asdf-orb-specific
########################################################################################################################

# $1 - install_dir
ci_post_asdf_install() {
  if [ "${CIRCLECI}" = "true" ]; then
    local install_dir="${1}"
    asdf_validate_install_dir "${install_dir}"
    echo ". ${install_dir}/asdf.sh" >> "${BASH_ENV}"
  fi
}

main() {
  local version install_dir
  version="${VERSION}"
  install_dir="$(asdf_determine_install_dir "${INSTALL_DIR}")"
  if ! asdf_is_installed; then
      printf "${YELLOW}%s${NC}\n" "${NAME} is not yet installed."
      asdf_install "${version}" "${install_dir}"
      ci_post_asdf_install "${install_dir}"
    elif ! asdf_is_version "${version}"; then
      printf "${YELLOW}%s${NC}\n" "The installed version of ${NAME} ($(asdf_version)) is different then expected (${version})."
      asdf_install "${version}" "${install_dir}"
      ci_post_asdf_install "${install_dir}"
    else
      printf "${YELLOW}%s${NC}\n" "${NAME} is already installed in $(which "${CMD_NAME}")."
    fi
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@]
# It is not a problem. This part pf condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
# source of ././src/scripts/install_asdf.bash - END
