#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TERRAFORM_DIR="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
ENV_FILE="${TF_ENV_FILE:-${TERRAFORM_DIR}/.env.tfvars}"

if [[ $# -lt 1 ]]; then
  cat >&2 <<EOF
Usage: $0 <terraform-subcommand> [args...]
Example: $0 plan
EOF
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  cat >&2 <<EOF
Missing env file: ${ENV_FILE}
Create it from:
  cp ${TERRAFORM_DIR}/.env.tfvars.example ${ENV_FILE}
EOF
  exit 1
fi

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

strip_wrapping_quotes() {
  local value="$1"
  if [[ ${#value} -ge 2 ]]; then
    local first_char="${value:0:1}"
    local last_char="${value: -1}"
    if [[ ("${first_char}" == "\"" && "${last_char}" == "\"") || ("${first_char}" == "'" && "${last_char}" == "'") ]]; then
      printf '%s' "${value:1:${#value}-2}"
      return
    fi
  fi
  printf '%s' "${value}"
}

declare -a tf_env
line_number=0
while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
  line_number=$((line_number + 1))
  line="$(trim_whitespace "${raw_line}")"

  if [[ -z "${line}" || "${line:0:1}" == "#" ]]; then
    continue
  fi

  if [[ "${line}" != *=* ]]; then
    echo "Invalid line ${line_number} in ${ENV_FILE}: expected KEY=VALUE." >&2
    exit 1
  fi

  key="${line%%=*}"
  value="${line#*=}"
  key="$(trim_whitespace "${key}")"
  value="$(trim_whitespace "${value}")"

  if [[ ! "${key}" =~ ^TF_VAR_[A-Za-z0-9_]+$ ]]; then
    echo "Invalid key '${key}' at line ${line_number}. Only TF_VAR_* keys are allowed." >&2
    exit 1
  fi

  value="$(strip_wrapping_quotes "${value}")"
  tf_env+=("${key}=${value}")
done < "${ENV_FILE}"

cd "${TERRAFORM_DIR}"
exec env "${tf_env[@]}" terraform "$@"
