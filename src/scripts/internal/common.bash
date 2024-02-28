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
