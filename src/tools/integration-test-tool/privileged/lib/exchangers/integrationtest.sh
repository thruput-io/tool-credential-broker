# shellcheck shell=bash
set -euo pipefail

exchange() {
  wants=$1

  case "$wants" in
    integrationtest/ci/run) ;;
    *) echo "integrationtest: nothing is registered for $wants" >&2; return 1 ;;
  esac

  secret=$(cat)

  case "$secret" in
    super-?*) ;;
    *) echo "integrationtest: the secret it was handed is not a super-token it can trade" >&2; return 1 ;;
  esac

  printf '%s\n' "${secret#super-}-ci-run-allowed"
}
